import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/tts/tts_service.dart';

/// Dwell time per sign at 1x speed; 0.75x stretches it proportionally.
const Duration _kSignDuration = Duration(milliseconds: 1200);

/// Immutable playback state for the translated gloss sequence.
class SequencePlayerState {
  const SequencePlayerState({
    this.sequence = const <Gloss>[],
    this.index = -1,
    this.playing = false,
    this.speed = 1.0,
  });

  final List<Gloss> sequence;

  /// Current sign position; -1 while idle (nothing loaded).
  final int index;
  final bool playing;

  /// Playback speed multiplier: 1.0 or 0.75.
  final double speed;

  bool get hasSequence => sequence.isNotEmpty;

  /// `Secuencia n/n` indicator (idle shows `Secuencia 0/0`).
  String get counterLabel => 'Secuencia ${index + 1}/${sequence.length}';

  Gloss? get current =>
      hasSequence && index >= 0 && index < sequence.length
      ? sequence[index]
      : null;

  /// Real time between sign advances at the current speed.
  Duration get signDuration => Duration(
    milliseconds: (_kSignDuration.inMilliseconds / speed).round(),
  );

  SequencePlayerState copyWith({
    List<Gloss>? sequence,
    int? index,
    bool? playing,
    double? speed,
  }) {
    return SequencePlayerState(
      sequence: sequence ?? this.sequence,
      index: index ?? this.index,
      playing: playing ?? this.playing,
      speed: speed ?? this.speed,
    );
  }
}

/// Drives the `Secuencia n/n` player: pure state + intents, NO timers. The
/// screen owns the periodic timer and calls [advance], which keeps this
/// controller fully deterministic in unit tests (no FakeAsync needed).
class SequencePlayerController extends Notifier<SequencePlayerState> {
  @override
  SequencePlayerState build() => const SequencePlayerState();

  /// Loads a translated sequence and pauses at its first sign. An empty
  /// sequence resets the player to idle. Speed carries over between loads.
  void load(List<Gloss> sequence) {
    state = SequencePlayerState(
      sequence: List<Gloss>.unmodifiable(sequence),
      index: sequence.isEmpty ? -1 : 0,
      playing: false,
      speed: state.speed,
    );
  }

  void play() {
    if (!state.hasSequence) {
      return;
    }
    var index = state.index;
    if (!state.playing && index >= state.sequence.length - 1) {
      index = 0; // replay from the top once the sequence finished
    }
    state = state.copyWith(index: index, playing: true);
    _speakCurrent();
  }

  void pause() {
    state = state.copyWith(playing: false);
    unawaited(ref.read(ttsGatewayProvider).stop());
  }

  /// Toggles between 1x and 0.75x; playback continues across the change.
  void toggleSpeed() {
    state = state.copyWith(speed: state.speed == 1.0 ? 0.75 : 1.0);
  }

  /// Steps to the next sign; stops (and keeps the last sign visible) at the
  /// end of the sequence. Called by the screen timer while playing.
  void advance() {
    if (!state.hasSequence) {
      return;
    }
    if (state.index + 1 >= state.sequence.length) {
      state = state.copyWith(playing: false);
      return;
    }
    state = state.copyWith(index: state.index + 1);
    if (state.playing) {
      _speakCurrent();
    }
  }

  /// Re-speaks the current sign (speaker button).
  void repeatAudio() => _speakCurrent();

  void _speakCurrent() {
    final Gloss? current = state.current;
    if (current == null) {
      return;
    }
    unawaited(
      ref
          .read(ttsGatewayProvider)
          .speak(speakableTextForGloss(current.label)),
    );
  }
}

/// Sequence player state shared between the translator screen widgets.
final NotifierProvider<SequencePlayerController, SequencePlayerState>
sequencePlayerProvider = NotifierProvider<SequencePlayerController,
    SequencePlayerState>(SequencePlayerController.new);
