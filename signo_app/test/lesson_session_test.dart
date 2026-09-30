import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart'
    show sharedPreferencesProvider;
import 'package:signo_app/features/learn/economy.dart'
    show canStartLesson, kInitialHearts, kXpPerLesson, progressProvider;
import 'package:signo_app/features/learn/lesson_session.dart';

/// A PLAYABLE sign: the flag and the clip path together, which is what
/// [VocabEntry.isVideoBacked] demands. Every sign in these fixtures is meant
/// to be playable, so the helper carries the flags once instead of every call
/// site remembering them (and forgetting, which is the regression the rule
/// exists to prevent).
VocabEntry entry(String id, String gloss) => VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[normalizeForMatch(gloss)],
      lesson: 1,
      subtema: 'Saludos informales',
      hasVideo: true,
      asset: 'assets/signs/$id.mp4',
    );

/// A sign the app cannot play. Only for the tests whose whole point is the
/// video-only gate.
VocabEntry clipLessEntry(String id, String gloss) => VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[normalizeForMatch(gloss)],
      lesson: 1,
      subtema: 'Saludos informales',
      hasVideo: false,
    );


final List<VocabEntry> fourSigns = <VocabEntry>[
  entry('s1', 'HOLA'),
  entry('s2', 'CHAU'),
  entry('s3', 'GRACIAS'),
  entry('s4', 'ADIOS'),
];

final List<VocabEntry> widePool = <VocabEntry>[
  ...fourSigns,
  entry('p5', 'POR-FAVOR'),
  entry('p6', 'PERDON'),
  entry('p7', 'BUENO'),
  entry('p8', 'MALO'),
];

/// A container with mock prefs so the session controller can read/write
/// progress (hearts, failed seeds) through the real providers.
Future<ProviderContainer> makeContainer() async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  addTearDown(container.dispose);
  // Warm the progress Notifier once.
  container.read(progressProvider);
  return container;
}

void main() {
  group('buildExercises', () {
    test('one exercise per sign, alternating recognize/match', () {
      final List<Exercise> exercises = buildExercises(
        fourSigns,
        distractorPool: widePool,
      );
      expect(exercises.length, 4);
      expect(exercises[0].type, ExerciseType.recognize);
      expect(exercises[1].type, ExerciseType.match);
      expect(exercises[2].type, ExerciseType.recognize);
      expect(exercises[3].type, ExerciseType.match);
      expect(
        exercises.map((Exercise e) => e.entry.id).toList(),
        <String>['s1', 's2', 's3', 's4'],
      );
    });

    test('every exercise has 4 options with exactly one correct', () {
      for (final Exercise exercise
          in buildExercises(fourSigns, distractorPool: widePool)) {
        expect(exercise.options.length, 4);
        expect(exercise.correctIndex, inInclusiveRange(0, 3));
        final Set<String> optionIds = <String>{
          for (final VocabEntry option in exercise.options) option.id,
        };
        expect(optionIds.length, 4);
        expect(optionIds.contains(exercise.entry.id), isTrue);
      }
    });

    test('building is deterministic (no randomness)', () {
      final List<Exercise> a =
          buildExercises(fourSigns, distractorPool: widePool);
      final List<Exercise> b =
          buildExercises(fourSigns, distractorPool: widePool);
      for (int i = 0; i < a.length; i++) {
        expect(
          a[i].options.map((VocabEntry e) => e.id).toList(),
          b[i].options.map((VocabEntry e) => e.id).toList(),
        );
        expect(a[i].correctIndex, b[i].correctIndex);
      }
    });

    test('fixedType pins the exercise type for all signs', () {
      final List<Exercise> exercises = buildExercises(
        fourSigns,
        distractorPool: widePool,
        fixedType: ExerciseType.match,
      );
      expect(
        exercises.every((Exercise e) => e.type == ExerciseType.match),
        isTrue,
      );
    });

    test('tiny pools may yield fewer than 4 options but keep the correct',
        () {
      final List<Exercise> exercises = buildExercises(
        fourSigns,
        distractorPool: fourSigns,
      );
      for (final Exercise exercise in exercises) {
        expect(exercise.options.first.id, exercise.entry.id);
        expect(exercise.options.length, lessThanOrEqualTo(4));
      }
    });
  });

  group('video-only invariant', () {
    // The curriculum already feeds video-only signs, so these tests hand
    // buildExercises the WORST legal input — a mixed sign list and a full
    // mixed pool — to prove the gate holds on its own instead of relying on
    // every caller having remembered to filter first.
    final List<VocabEntry> mixedSigns = <VocabEntry>[
      entry('s1', 'HOLA'),
      clipLessEntry('x1', 'GHOST1'),
      entry('s2', 'CHAU'),
      clipLessEntry('x2', 'GHOST2'),
      entry('s3', 'GRACIAS'),
    ];
    final List<VocabEntry> mixedPool = <VocabEntry>[
      ...mixedSigns,
      entry('p1', 'POR-FAVOR'),
      clipLessEntry('x3', 'GHOST3'),
      entry('p2', 'PERDON'),
      clipLessEntry('x4', 'GHOST4'),
      entry('p3', 'BUENO'),
      entry('p4', 'MALO'),
    ];

    test('no exercise entry is ever a clip-less sign', () {
      final List<Exercise> exercises =
          buildExercises(mixedSigns, distractorPool: mixedPool);

      expect(exercises.length, 3, reason: 'the two GHOST signs are dropped');
      expect(
        exercises.map((Exercise e) => e.entry.id).toList(),
        <String>['s1', 's2', 's3'],
      );
      for (final Exercise exercise in exercises) {
        expect(exercise.entry.isVideoBacked, isTrue);
      }
    });

    test('no option is ever a clip-less sign, even from a full mixed pool', () {
      for (final Exercise exercise
          in buildExercises(mixedSigns, distractorPool: mixedPool)) {
        for (final VocabEntry option in exercise.options) {
          expect(
            option.isVideoBacked,
            isTrue,
            reason: '${option.gloss} is a dead option card',
          );
        }
        // The correct option still sits among the distractors.
        expect(
          exercise.options.any((VocabEntry o) => o.id == exercise.entry.id),
          isTrue,
        );
      }
    });

    test('an all-clip-less sign list yields no exercises and no crash', () {
      // The edge the modulo arithmetic used to divide by zero on: a pool of
      // zero playable entries alongside a playable sign, and a sign list with
      // nothing playable at all.
      expect(
        buildExercises(
          <VocabEntry>[clipLessEntry('x1', 'GHOST1')],
          distractorPool: <VocabEntry>[
            clipLessEntry('x2', 'GHOST2'),
            clipLessEntry('x3', 'GHOST3'),
          ],
        ),
        isEmpty,
      );
      expect(
        buildExercises(<VocabEntry>[], distractorPool: mixedPool),
        isEmpty,
      );
    });

    test('a playable sign with an all-clip-less pool still gets its exercise',
        () {
      // The pool is empty AFTER filtering, which is the `% pool.length`
      // divide-by-zero the guard exists for. The exercise survives with a
      // single option — the correct sign.
      final List<Exercise> exercises = buildExercises(
        <VocabEntry>[entry('s1', 'HOLA')],
        distractorPool: <VocabEntry>[clipLessEntry('x1', 'GHOST1')],
      );

      expect(exercises.length, 1);
      expect(exercises.single.options.map((VocabEntry o) => o.id).toList(),
          <String>['s1']);
      expect(exercises.single.correctIndex, 0);
    });
  });

  group('LessonSessionController', () {

    test('start opens the session on exercise 0 with a clean tally',
        () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      expect(container.read(sessionProvider), isNull);

      controller.start(fourSigns, nodeId: 'u1-l1', distractorPool: widePool);

      final LessonSessionState session = container.read(sessionProvider)!;
      expect(session.index, 0);
      expect(session.correctCount, 0);
      expect(session.finished, isFalse);
      expect(session.current, isNotNull);
    });

    test('correct answer tallies, no heart lost, advance moves on',
        () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      controller.start(fourSigns, nodeId: 'u1-l1', distractorPool: widePool);

      final Exercise first = container.read(sessionProvider)!.exercises[0];
      controller.answer(first.correctIndex);

      final LessonSessionState after = container.read(sessionProvider)!;
      expect(after.correctCount, 1);
      expect(after.selectedOption, first.correctIndex);
      expect(container.read(progressProvider).hearts, kInitialHearts);
      expect(container.read(progressProvider).failedSignIds, isEmpty);

      controller.advance();
      expect(container.read(sessionProvider)!.index, 1);
    });

    test('wrong answer costs a heart and seeds the failed list', () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      controller.start(fourSigns, nodeId: 'u1-l1', distractorPool: widePool);

      final Exercise first = container.read(sessionProvider)!.exercises[0];
      final int wrong =
          (first.correctIndex + 1) % first.options.length;
      controller.answer(wrong);

      final LessonSessionState after = container.read(sessionProvider)!;
      expect(after.correctCount, 0);
      expect(container.read(progressProvider).hearts, kInitialHearts - 1);
      expect(
        container.read(progressProvider).failedSignIds,
        <String>[first.entry.id],
      );
    });

    test('answer is ignored in the feedback phase and after finish',
        () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      controller.start(fourSigns, nodeId: 'u1-l1', distractorPool: widePool);

      final Exercise first = container.read(sessionProvider)!.exercises[0];
      controller.answer(first.correctIndex);
      // Double answer must not change the tally.
      controller.answer((first.correctIndex + 1) % first.options.length);
      expect(container.read(sessionProvider)!.correctCount, 1);
    });

    test('advance without an answer is a no-op', () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      controller.start(fourSigns, nodeId: 'u1-l1', distractorPool: widePool);
      controller.advance();
      expect(container.read(sessionProvider)!.index, 0);
    });

    test('completing all exercises finishes with precision + XP + node',
        () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      controller.start(fourSigns, nodeId: 'u1-l1', distractorPool: widePool);

// Answer 3 correct, 1 wrong → 75% precision. The wrong answer spends a heart
      // mid-session, and completing the session refills it (see below).
      for (int i = 0; i < 4; i++) {
        final LessonSessionState session = container.read(sessionProvider)!;
        final Exercise exercise = session.exercises[session.index];
        final int pick = i == 3
            ? (exercise.correctIndex + 1) % exercise.options.length
            : exercise.correctIndex;
        controller.answer(pick);
        controller.advance();
      }

      final LessonSessionState finished = container.read(sessionProvider)!;
      expect(finished.finished, isTrue);
      expect(finished.result, isNotNull);
      expect(finished.result!.correctCount, 3);
      expect(finished.result!.total, 4);
      expect(finished.result!.precisionPercent, 75);
      expect(finished.result!.xpGained, kXpPerLesson + 1);
      expect(finished.result!.streak, 1);
      expect(finished.result!.unitCompleted, isFalse);
      expect(
        container.read(progressProvider).completedNodeIds,
        <String>{'u1-l1'},
      );
expect(
        container.read(progressProvider).hearts,
        // Completing the session gives the heart back. This used to assert
        // `kInitialHearts - 1`, locking in the soft-lock: the wrong answer was
        // paid for and never recovered, so the path stayed shut after a lesson
        // the player had just finished.
        kInitialHearts,
      );
      expect(canStartLesson(container.read(progressProvider)), isTrue);
    });

    test('boss session reports unitCompleted', () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      controller.start(
        fourSigns,
        nodeId: 'u1-boss',
        isBoss: true,
        distractorPool: widePool,
      );
      while (!(container.read(sessionProvider)!.finished)) {
        final LessonSessionState session = container.read(sessionProvider)!;
        final Exercise exercise = session.exercises[session.index];
        controller.answer(exercise.correctIndex);
        controller.advance();
      }
      expect(
        container.read(sessionProvider)!.result!.unitCompleted,
        isTrue,
      );
    });

    test('repasar completion clears the failed list', () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      // Seed two failed signs from an earlier session.
      await container
          .read(progressProvider.notifier)
          .registerWrongAnswer('s1');
      await container
          .read(progressProvider.notifier)
          .registerWrongAnswer('s3');

      controller.start(
        fourSigns,
        isRepasar: true,
        distractorPool: widePool,
      );
      while (!(container.read(sessionProvider)!.finished)) {
        final LessonSessionState session = container.read(sessionProvider)!;
        final Exercise exercise = session.exercises[session.index];
        controller.answer(exercise.correctIndex);
        controller.advance();
      }
      expect(container.read(progressProvider).failedSignIds, isEmpty);
      expect(
        container.read(sessionProvider)!.result!.isRepasar,
        isTrue,
      );
    });

    test('dismiss drops the session', () async {
      final ProviderContainer container = await makeContainer();
      final LessonSessionController controller =
          container.read(sessionProvider.notifier);
      controller.start(fourSigns, distractorPool: widePool);
      controller.dismiss();
      expect(container.read(sessionProvider), isNull);
    });
  });
}

