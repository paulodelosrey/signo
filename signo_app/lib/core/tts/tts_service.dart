import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Text-to-speech seam: feature code talks to THIS interface, never to the
/// platform plugin directly, so widget/unit tests inject a fake and the
/// real platform channel is only touched on device.
abstract interface class TtsGateway {
  /// Speaks [text] aloud. Completes once the engine accepts (and, where
  /// supported, finishes) the utterance.
  Future<void> speak(String text);

  /// Stops any current utterance.
  Future<void> stop();
}

/// Real [TtsGateway] backed by the `flutter_tts` plugin.
///
/// Configuration is lazy: constructing the gateway never touches a platform
/// channel, and the app never constructs it in tests (the provider is
/// overridden with a fake there).
class FlutterTtsGateway implements TtsGateway {
  FlutterTtsGateway() : _tts = FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  Future<void> _ensureConfigured() async {
    if (_configured) {
      return;
    }
    // Spec (translator): TTS via flutter_tts in Spanish with
    // awaitSpeakCompletion so playback pacing stays predictable.
    await _tts.awaitSpeakCompletion(true);
    // Prefer the Colombian Spanish voice; degrade to the generic Spanish
    // voice when the platform lacks the regional one.
    final dynamic colombian = await _tts.isLanguageAvailable('es-CO');
    await _tts.setLanguage(colombian == true ? 'es-CO' : 'es-ES');
    _configured = true;
  }

  @override
  Future<void> speak(String text) async {
    await _ensureConfigured();
    await _tts.speak(text);
  }

  @override
  Future<void> stop() => _tts.stop();
}

/// Injectable TTS seam; tests override this with a recording fake.
final Provider<TtsGateway> ttsGatewayProvider = Provider<TtsGateway>(
  (Ref ref) => FlutterTtsGateway(),
);

/// Converts an uppercase LSC gloss label (`BUENOS-DIAS`) into speakable
/// Spanish text (`buenos dias`).
String speakableTextForGloss(String glossLabel) {
  return glossLabel.toLowerCase().replaceAll(RegExp('[-_]'), ' ');
}
