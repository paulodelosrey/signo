import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/tts/tts_service.dart';
import 'package:signo_app/features/translator/player_controller.dart';

/// Recording fake: the ONLY TtsGateway tests ever touch, so the real
/// flutter_tts platform channel is never invoked.
class _RecordingTts implements TtsGateway {
  final List<String> spoken = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}

const Gloss _hola = Gloss(
  label: 'HOLA',
  entryId: 'l1-038',
  subtema: 'Saludos informales',
  isTime: false,
);
const Gloss _gracias = Gloss(
  label: 'GRACIAS',
  entryId: 'l2-050',
  subtema: 'Frases comunes',
  isTime: false,
);
const Gloss _casa = Gloss(
  label: 'CASA',
  entryId: 'l3-070',
  subtema: 'Lugar',
  isTime: false,
);

void main() {
  group('speakableTextForGloss', () {
    test('lowercases and splits compound gloss labels', () {
      expect(speakableTextForGloss('BUENOS-DIAS'), 'buenos dias');
      expect(speakableTextForGloss('YO'), 'yo');
      expect(speakableTextForGloss('COMO_ESTAS'), 'como estas');
    });
  });

  group('SequencePlayerController', () {
    late _RecordingTts tts;
    late ProviderContainer container;
    late SequencePlayerController controller;

    setUp(() {
      tts = _RecordingTts();
      container = ProviderContainer(
        overrides: [ttsGatewayProvider.overrideWithValue(tts)],
      );
      controller = container.read(sequencePlayerProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('starts idle at Secuencia 0/0', () {
      final SequencePlayerState state = container.read(sequencePlayerProvider);

      expect(state.hasSequence, isFalse);
      expect(state.counterLabel, 'Secuencia 0/0');
      expect(state.current, isNull);
    });

    test('load pauses at the first sign; empty load resets to idle', () {
      controller.load(<Gloss>[_hola, _gracias, _casa]);
      var state = container.read(sequencePlayerProvider);

      expect(state.counterLabel, 'Secuencia 1/3');
      expect(state.playing, isFalse);
      expect(state.current?.label, 'HOLA');

      controller.load(<Gloss>[]);
      state = container.read(sequencePlayerProvider);

      expect(state.hasSequence, isFalse);
      expect(state.counterLabel, 'Secuencia 0/0');
    });

    test('play speaks the first sign and advance steps with TTS', () {
      controller.load(<Gloss>[_hola, _gracias, _casa]);

      controller.play();
      expect(container.read(sequencePlayerProvider).playing, isTrue);
      expect(tts.spoken, <String>['hola']);

      controller.advance();
      expect(container.read(sequencePlayerProvider).counterLabel,
          'Secuencia 2/3');
      expect(tts.spoken, <String>['hola', 'gracias']);

      controller.advance();
      expect(tts.spoken, <String>['hola', 'gracias', 'casa']);
    });

    test('stops at the end and replays from the top on play', () {
      controller.load(<Gloss>[_hola, _gracias]);

      controller.advance(); // 2/2
      controller.advance(); // end → stops
      var state = container.read(sequencePlayerProvider);

      expect(state.playing, isFalse);
      expect(state.counterLabel, 'Secuencia 2/2');
      // advance() while paused never speaks (speech follows playback only).
      expect(tts.spoken, isEmpty);

      controller.play();
      state = container.read(sequencePlayerProvider);

      expect(state.playing, isTrue);
      expect(state.counterLabel, 'Secuencia 1/2');
      expect(tts.spoken, <String>['hola']);
    });

    test('pause stops playback and the current utterance', () {
      controller.load(<Gloss>[_hola, _gracias]);

      controller.play();
      controller.pause();

      final SequencePlayerState state = container.read(sequencePlayerProvider);
      expect(state.playing, isFalse);
      expect(tts.stops, 1);
    });

    test('toggleSpeed alternates 1x ⇄ 0.75x and stretches the interval', () {
      expect(
        container.read(sequencePlayerProvider).signDuration,
        const Duration(milliseconds: 1200),
      );

      controller.toggleSpeed();
      SequencePlayerState state = container.read(sequencePlayerProvider);
      expect(state.speed, 0.75);
      expect(state.signDuration, const Duration(milliseconds: 1600));

      controller.toggleSpeed();
      state = container.read(sequencePlayerProvider);
      expect(state.speed, 1.0);
    });

    test('load keeps the chosen speed across translations', () {
      controller.toggleSpeed();
      controller.load(<Gloss>[_hola]);

      expect(container.read(sequencePlayerProvider).speed, 0.75);
    });

    test('repeatAudio re-speaks the current sign', () {
      controller.load(<Gloss>[_hola, _gracias]);

      controller.repeatAudio();

      expect(tts.spoken, <String>['hola']);
    });

    test('play/advance on an empty sequence are safe no-ops', () {
      controller.play();
      controller.advance();

      expect(tts.spoken, isEmpty);
      expect(container.read(sequencePlayerProvider).playing, isFalse);
    });
  });
}
