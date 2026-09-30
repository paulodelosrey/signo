import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lsc_vocab/lsc_vocab.dart';
import 'economy.dart';
import 'lesson_screen.dart';
import 'lesson_session.dart';

/// Starts the static Repasar session over the failed signs (spec
/// `learning-path`: "static Repasar card seeded from failed signs").
///
/// Single shared entry point so the Aprender tree card AND the Profile
/// review entry reuse the exact same progress state and semantics: resolve
/// the failed ids through the vocabulary index, seed [sessionProvider] with
/// `isRepasar: true` (completing it clears the failed list), and push the
/// lesson flow. Does nothing when there is nothing to review — mirroring the
/// tree card, which only appears with failed signs.
///
/// The vocabulary future is ALWAYS awaited (not read as a snapshot value):
/// callers like the Profile screen may never have watched
/// [vocabIndexProvider], so a synchronous read could observe a still-loading
/// index and silently resolve zero signs.
///
/// GATE C of the video-only rule, and the only gate that matters for id
/// resolution: `failedSignIds` is PERSISTED state, so it can still hold ids
/// from the pre-video-only path — signs that were failed before U2/U4 were
/// dropped and are now clip-less. Resolving them here is what turns a stale
/// progress entry into a real exercise, so they are filtered on the entry's
/// own [VocabEntry.isVideoBacked] rather than trusted. The distractor pool is
/// the video-only set for the same reason. When nothing survives, the session
/// simply does not start: an all-clip-less review list has nothing to review.
Future<void> startRepasarSession(BuildContext context, WidgetRef ref) async {
  final EconomyState progress = ref.read(progressProvider);
  if (progress.failedSignIds.isEmpty) {
    return;
  }
  final VocabIndex index;
  try {
    index = await ref.read(vocabIndexProvider.future);
  } on Object {
    // Mirror the tree's error rendering: no vocabulary → nothing to review.
    return;
  }
  // The pool stays WIDE (every clip-backed sign), not just the failed ones: a
  // review session of one sign still needs three distinct distractors to build
  // a four-option match exercise.
  final List<VocabEntry> vocabulary = index.videoEntries;
  final Map<String, VocabEntry> byId = <String, VocabEntry>{
    for (final VocabEntry entry in vocabulary) entry.id: entry,
  };
  final List<VocabEntry> failed = <VocabEntry>[
    for (final String id in progress.failedSignIds)
      if (byId[id] != null) byId[id]!,
  ];
  if (failed.isEmpty || !context.mounted) {
    return;
  }
  ref.read(sessionProvider.notifier).start(
        failed,
        isRepasar: true,
        distractorPool: vocabulary,
      );
  // Zero-duration route: matches the tree's lesson push and keeps
  // reduced-motion users and widget tests deterministic.
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const LessonScreen(),
    ),
  );
}

/// How many failed signs the review card may honestly promise.
///
/// The raw `failedSignIds.length` is NOT the number: a stale id from the old
/// path would make the card read "3 señas" and then open a 1-sign session —
/// or, once every id is stale, offer a review that starts nothing at all. The
/// card's count and the session's contents therefore come from ONE definition
/// ([_resolveReviewable]), so they can never disagree.
final FutureProvider<int> reviewableFailedCountProvider =
    FutureProvider<int>((Ref ref) async {
  final EconomyState progress = ref.watch(progressProvider);
  if (progress.failedSignIds.isEmpty) {
    return 0;
  }
  final VocabIndex index;
  try {
    index = await ref.watch(vocabIndexProvider.future);
  } on Object {
    return 0;
  }
  final Set<String> playable = <String>{
    for (final VocabEntry entry in index.videoEntries) entry.id,
  };
  return progress.failedSignIds
      .where(playable.contains)
      .toSet()
      .length;
});
