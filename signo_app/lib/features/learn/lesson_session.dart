import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lsc_vocab/lsc_vocab.dart';
import 'curriculum.dart' show kBossExerciseCap, sampleEvenly;
import 'economy.dart';

/// The two MVP exercise types (spec `learning-path`): recognize shows a sign
/// and asks for the word; match shows a word and asks for the sign.
enum ExerciseType { recognize, match }

/// One exercise: an [entry] plus 4 deterministic options, one of them correct.
///
/// Options carry full [VocabEntry]s so the UI renders a word (recognize) or a
/// sign card (match) from the same object — swapping the text-mode card for a
/// real video later needs no flow change.
class Exercise {
  const Exercise({
    required this.entry,
    required this.type,
    required this.options,
    required this.correctIndex,
  });

  final VocabEntry entry;
  final ExerciseType type;
  final List<VocabEntry> options;
  final int correctIndex;

  bool isCorrect(int optionIndex) => optionIndex == correctIndex;
}

/// Outcome snapshot handed to the lesson-end screen.
class LessonResult {
  const LessonResult({
    required this.xpGained,
    required this.precisionPercent,
    required this.correctCount,
    required this.total,
    required this.streak,
    required this.unitCompleted,
    required this.isRepasar,
  });

  final int xpGained;
  final int precisionPercent;
  final int correctCount;
  final int total;
  final int streak;

  /// True when the finished node was the unit BOSS (chest ready on the map).
  final bool unitCompleted;
  final bool isRepasar;
}

/// Mutable session state: the ordered exercises, the cursor, and the last
/// answer while feedback is on screen.
class LessonSessionState {
  const LessonSessionState({
    required this.exercises,
    required this.index,
    required this.correctCount,
    this.selectedOption,
    this.finished = false,
    this.result,
  });

  final List<Exercise> exercises;
  final int index;
  final int correctCount;

  /// Option chosen for the current exercise (feedback phase) or null.
  final int? selectedOption;
  final bool finished;
  final LessonResult? result;

  int get total => exercises.length;
  bool get isLast => index + 1 >= total;
  Exercise? get current =>
      finished || index >= total ? null : exercises[index];
  double get precision =>
      total == 0 ? 0 : (correctCount * 100) / total;

  LessonSessionState copyWith({
    int? index,
    int? correctCount,
    int? selectedOption,
    bool clearSelectedOption = false,
    bool? finished,
    LessonResult? result,
  }) {
    return LessonSessionState(
      exercises: exercises,
      index: index ?? this.index,
      correctCount: correctCount ?? this.correctCount,
      selectedOption:
          clearSelectedOption ? null : (selectedOption ?? this.selectedOption),
      finished: finished ?? this.finished,
      result: result ?? this.result,
    );
  }
}

/// Builds one exercise per sign in order, alternating recognize/match
/// deterministically (or fixed when [fixedType] is set). Distractors are
/// drawn cyclically from [distractorPool] — never random — so sessions are
/// reproducible and test-friendly.
List<Exercise> buildExercises(
  List<VocabEntry> signs, {
  required List<VocabEntry> distractorPool,
  ExerciseType? fixedType,
}) {
  final List<Exercise> exercises = <Exercise>[];
  for (int i = 0; i < signs.length; i++) {
    final VocabEntry entry = signs[i];
    final ExerciseType type =
        fixedType ?? (i.isEven ? ExerciseType.recognize : ExerciseType.match);
    final List<VocabEntry> options =
        _buildOptions(entry, distractorPool, i);
    exercises.add(Exercise(
      entry: entry,
      type: type,
      options: options,
      correctIndex: options.indexWhere(
        (VocabEntry option) => option.id == entry.id,
      ),
    ));
  }
  return exercises;
}

/// Correct option at a rotating deterministic position; distractors walk the
/// pool cyclically skipping duplicates and the correct entry itself.
List<VocabEntry> _buildOptions(
  VocabEntry correct,
  List<VocabEntry> pool,
  int seedIndex,
) {
  final List<VocabEntry> options = <VocabEntry>[correct];
  final Set<String> usedIds = <String>{correct.id};
  int cursor = (seedIndex * 3 + 1) % pool.length;
  while (options.length < 4 && usedIds.length < pool.length) {
    final VocabEntry candidate = pool[cursor % pool.length];
    cursor++;
    if (usedIds.contains(candidate.id)) {
      if (cursor > pool.length * 2) {
        break; // Pool exhausted (tiny fixture) — fewer options is valid.
      }
      continue;
    }
    usedIds.add(candidate.id);
    options.add(candidate);
  }
  return options;
}

/// Drives a lesson-like session: lessons, BOSS reviews, Repasar and
/// Práctica all reuse this state machine.
///
/// Flow: [start] → [answer] (locks feedback, applies heart/failed rules) →
/// [advance] (next exercise or finish). Finishing applies the economy rules
/// once and stores a [LessonResult]; leaving early simply drops the session —
/// wrong answers already applied stay applied (documented MVP behavior).
class LessonSessionController extends Notifier<LessonSessionState?> {
  int _xpBefore = 0;
  String? _nodeId;
  bool _isBoss = false;
  bool _isRepasar = false;

  @override
  LessonSessionState? build() => null;

  bool get isRepasar => _isRepasar;

  /// Starts a session over [signs]. [distractorPool] defaults to [signs];
  /// callers pass a wider pool (unit/vocabulary) for small sign sets.
  void start(
    List<VocabEntry> signs, {
    String? nodeId,
    bool isBoss = false,
    bool isRepasar = false,
    ExerciseType? fixedType,
    List<VocabEntry>? distractorPool,
  }) {
    _xpBefore = ref.read(progressProvider).xp;
    _nodeId = nodeId;
    _isBoss = isBoss;
    _isRepasar = isRepasar;
    final List<VocabEntry> pool = distractorPool ?? signs;
    state = LessonSessionState(
      exercises:
          buildExercises(signs, distractorPool: pool, fixedType: fixedType),
      index: 0,
      correctCount: 0,
    );
  }

  /// BOSS sessions review up to [kBossExerciseCap] evenly spaced signs;
  /// convenience wrapper used by the tree.
  void startBoss(
    List<VocabEntry> unitSigns, {
    required String nodeId,
    List<VocabEntry>? distractorPool,
  }) {
    start(
      sampleEvenly(unitSigns, kBossExerciseCap),
      nodeId: nodeId,
      isBoss: true,
      distractorPool: distractorPool,
    );
  }

  /// Locks an answer: correct → tally; wrong → −1 heart + failed-seed.
  /// Ignored outside the answering phase.
  void answer(int optionIndex) {
    final LessonSessionState? current = state;
    if (current == null ||
        current.finished ||
        current.selectedOption != null) {
      return;
    }
    final Exercise exercise = current.exercises[current.index];
    final bool correct = exercise.isCorrect(optionIndex);
    if (!correct) {
      ref.read(progressProvider.notifier).registerWrongAnswer(exercise.entry.id);
    }
    state = current.copyWith(
      selectedOption: optionIndex,
      correctCount: current.correctCount + (correct ? 1 : 0),
    );
  }

  /// Leaves the feedback phase: next exercise, or finish the session.
  void advance() {
    final LessonSessionState? current = state;
    if (current == null || current.finished || current.selectedOption == null) {
      return;
    }
    if (!current.isLast) {
      state = current.copyWith(
        index: current.index + 1,
        clearSelectedOption: true,
      );
      return;
    }
    _finish(current);
  }

  void _finish(LessonSessionState current) {
    ref.read(progressProvider.notifier).completeSession(
          completedNodeId: _nodeId,
          clearsFailedSigns: _isRepasar,
        );
    final EconomyState after = ref.read(progressProvider);
    state = current.copyWith(
      clearSelectedOption: true,
      finished: true,
      result: LessonResult(
        xpGained: after.xp - _xpBefore,
        precisionPercent: current.precision.round(),
        correctCount: current.correctCount,
        total: current.total,
        streak: after.streak,
        unitCompleted: _isBoss,
        isRepasar: _isRepasar,
      ),
    );
  }

  /// Drops the session (exit or after the end screen).
  void dismiss() => state = null;
}

/// Active lesson session; null when no session is running.
final NotifierProvider<LessonSessionController, LessonSessionState?>
    sessionProvider =
    NotifierProvider<LessonSessionController, LessonSessionState?>(
      LessonSessionController.new,
    );
