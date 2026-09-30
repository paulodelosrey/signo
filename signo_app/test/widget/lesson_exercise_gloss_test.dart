import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/app/theme.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart';
import 'package:signo_app/features/learn/lesson_screen.dart';
import 'package:signo_app/features/learn/lesson_session.dart';
import 'package:signo_app/widgets/sign_video_player.dart';

import '../support/settle_with_video_card.dart';

/// The exercise card must not leak the answer.
///
/// In the sign→word direction the prompt card IS the sign, and its gloss is one
/// of the four words below it. The video-only rule closed the escape hatch
/// that made this delicate: exercises only ever hold clip-backed signs, so the
/// prompt is the clip and there is no text-mode card to leak through.
///
/// The clip cannot decode in a widget test, so the card shows its loading
/// indicator throughout ([settleWithVideoCard]). That is enough to pin the
/// contract that matters — the answer is never printed, and the old curation
/// box is gone — but the card's CONTENTS are only observable on a clip-less
/// entry, which is covered by the direct [SignView] tests at the bottom.
final List<VocabEntry> kLessonVocab = <VocabEntry>[
  for (final (String id, String gloss) in <(String, String)>[
    ('l-1', 'BRILLANTE'),
    ('l-2', 'CLARO'),
    ('l-3', 'OSCURO'),
    ('l-4', 'HOLA'),
  ])
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[gloss.toLowerCase()],
      lesson: 1,
      subtema: 'Colores',
      hasVideo: true,
      asset: 'assets/signs/$id.mp4',
    ),
];

/// Deliberately clip-less: the text-mode card is the DICTIONARY surface, and
/// it is the only SignView configuration whose content a test can read.
const VocabEntry kClipLessEntry = VocabEntry(
  id: 'd-1',
  gloss: 'BRILLANTE',
  lemmas: <String>['brillante'],
  lesson: 1,
  subtema: 'Colores',
  hasVideo: false,
);

Future<void> _pumpLesson(
  WidgetTester tester, {
  required ExerciseType type,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'signo.onboardingSeen': true,
    'signo.reducedMotion': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  container.read(sessionProvider.notifier).start(
        <VocabEntry>[kLessonVocab.first],
        fixedType: type,
        distractorPool: kLessonVocab,
      );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKineticTheme(),
        home: const LessonScreen(),
      ),
    ),
  );
}

Future<void> _pumpSignView(
  WidgetTester tester,
  Widget child,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildKineticTheme(),
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('sign→word exercise does not print the gloss as the answer', (
    WidgetTester tester,
  ) async {
    await _pumpLesson(tester, type: ExerciseType.recognize);
    await settleWithVideoCard(tester);

    expect(find.text('¿Qué palabra significa esta seña?'), findsOneWidget);
    // The answer option is present…
    expect(find.text('Brillante'), findsOneWidget);
    // …but the sign card above it never spells the answer, in any state.
    expect(find.text('BRILLANTE'), findsNothing);
    // The curation box is gone from every card in the lesson.
    expect(find.text('video en curaduría'), findsNothing);
  });

  testWidgets('word→sign exercise states the word in its prompt', (
    WidgetTester tester,
  ) async {
    await _pumpLesson(tester, type: ExerciseType.match);
    await settleWithVideoCard(tester);

    // The prompt states the word, so there is nothing to hide: the sign cards
    // are the clips. (What a compact card prints when it has no clip is
    // asserted directly on SignView below.)
    expect(find.text('¿Cuál es la seña de «Brillante»?'), findsOneWidget);
    expect(find.text('video en curaduría'), findsNothing);
  });

  group('match grid is tap-to-play (one video player at a time)', () {
    // The device constraint this locks: on the TECNO CM6, four
    // `VideoPlayerController`s playing at once all decode but never update
    // their surface (8 captures 1s apart -> ONE unique frame in 7s), while
    // every single-player surface animates. Counting instantiated players is
    // therefore the only test that can catch a regression here: the freeze is
    // invisible to `flutter test` because the loader hangs rather than fails.
    testWidgets('no card instantiates a player until it is previewed', (
      WidgetTester tester,
    ) async {
      await _pumpLesson(tester, type: ExerciseType.match);
      await settleWithVideoCard(tester);

      // Four options, zero players, and the play affordance on every card.
      expect(find.byType(SignVideoPlayer), findsNothing);
      expect(find.text('Ver seña'), findsNWidgets(4));
    });

    testWidgets('previewing a card creates exactly one player', (
      WidgetTester tester,
    ) async {
      await _pumpLesson(tester, type: ExerciseType.match);
      await settleWithVideoCard(tester);

      await tester.tap(find.text('Ver seña').first);
      await settleWithVideoCard(tester);

      // ONE player, not four. This is the whole point of the interaction.
      expect(find.byType(SignVideoPlayer), findsOneWidget);
      // The other three stay inert: no player, still labelled.
      expect(find.text('Ver seña'), findsNWidgets(3));
    });

    testWidgets('previewing another card MOVES the single player', (
      WidgetTester tester,
    ) async {
      await _pumpLesson(tester, type: ExerciseType.match);
      await settleWithVideoCard(tester);

      await tester.tap(find.text('Ver seña').first);
      await settleWithVideoCard(tester);
      await tester.tap(find.text('Ver seña').first);
      await settleWithVideoCard(tester);

      // Still exactly one: moving the preview tears the old player down
      // instead of adding a second concurrent decoder.
      expect(find.byType(SignVideoPlayer), findsOneWidget);
    });

    testWidgets('the answer is committed by the check, not by the tap', (
      WidgetTester tester,
    ) async {
      await _pumpLesson(tester, type: ExerciseType.match);
      await settleWithVideoCard(tester);

      // Before previewing, there is no way to answer at all: a sign you have
      // not watched cannot be chosen.
      expect(find.byIcon(Icons.check), findsNothing);

      await tester.tap(find.text('Ver seña').first);
      await settleWithVideoCard(tester);

      // The ✓ only exists on the card that is playing.
      expect(find.byIcon(Icons.check), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check));
      await settleWithVideoCard(tester);

      // Answer locked: the feedback banner appears and the ✓ is gone.
      expect(find.text('Seguir'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });

  group('SignView text-mode card (clip-less, the dictionary surface)', () {
    testWidgets('the prompt card can withhold the gloss', (
      WidgetTester tester,
    ) async {
      await _pumpSignView(
        tester,
        const SignView(entry: kClipLessEntry, showGloss: false),
      );

      expect(find.text('BRILLANTE'), findsNothing);
      expect(find.byIcon(Icons.sign_language), findsOneWidget);
      expect(find.text('video en curaduría'), findsNothing);
    });

    testWidgets('the compact option card labels itself with its gloss', (
      WidgetTester tester,
    ) async {
      await _pumpSignView(
        tester,
        const SignView(entry: kClipLessEntry, compact: true),
      );

      expect(find.text('BRILLANTE'), findsOneWidget);
      expect(find.text('video en curaduría'), findsNothing);
    });

    testWidgets('no curation affordance survives anywhere on the card', (
      WidgetTester tester,
    ) async {
      await _pumpSignView(
        tester,
        const SignView(entry: kClipLessEntry),
      );

      // The icon and the label went together; asserting both means a partial
      // revert of the removal cannot slip through.
      expect(find.text('video en curaduría'), findsNothing);
      expect(find.byIcon(Icons.videocam_off_outlined), findsNothing);
    });
  });
}
