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
Future<void> startRepasarSession(BuildContext context, WidgetRef ref) async {
  final EconomyState progress = ref.read(progressProvider);
  if (progress.failedSignIds.isEmpty) {
    return;
  }
  final List<VocabEntry> vocabulary;
  try {
    final VocabIndex index = await ref.read(vocabIndexProvider.future);
    vocabulary = index.entries;
  } on Object {
    // Mirror the tree's error rendering: no vocabulary → nothing to review.
    return;
  }
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
