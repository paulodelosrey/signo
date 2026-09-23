import 'translator_service.dart';

/// Thrown by [GeminiStrategy] while the remote path is unavailable.
class GeminiUnavailableError implements Exception {
  const GeminiUnavailableError(this.reason);

  final String reason;

  @override
  String toString() => 'GeminiUnavailableError: $reason';
}

/// Remote translator strategy seam for a future Gemini integration.
///
/// BLOCKED-USER (M4): there is no API key yet, so this stub ALWAYS fails
/// fast with [GeminiUnavailableError] and `TranslatorService` falls back to
/// the offline local matcher — exactly the keyless behavior the spec
/// requires ("Gemini MAY enhance only when env key present").
///
/// When a key is provisioned: inject it at build time
/// (`--dart-define=GEMINI_API_KEY=...`, never committed) and put the real
/// network call inside [translate] behind this SAME interface. The service
/// already prefers a configured remote and falls back on any error, so no
/// other file needs to change.
class GeminiStrategy implements TranslatorStrategy {
  const GeminiStrategy({this.apiKey});

  /// Build-time injected key; null/empty means the keyless demo path.
  final String? apiKey;

  /// True only when a non-empty key was injected at build time.
  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  @override
  Future<TranslationResult> translate(String input) async {
    // TODO(gemini-key): replace with the real network call once a key is
    // provisioned. The stub must never succeed so the offline-first
    // contract stays intact while the key is missing.
    throw const GeminiUnavailableError(
      'Gemini key not provisioned yet (keyless stub).',
    );
  }
}
