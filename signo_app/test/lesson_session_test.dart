import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart'
    show sharedPreferencesProvider;
import 'package:signo_app/features/learn/economy.dart'
    show kInitialHearts, kXpPerLesson, progressProvider;
import 'package:signo_app/features/learn/lesson_session.dart';

VocabEntry entry(String id, String gloss) => VocabEntry(
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

      // Answer 3 correct, 1 wrong → 75% precision, hearts 4.
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
      expect(container.read(progressProvider).hearts, kInitialHearts - 1);
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

