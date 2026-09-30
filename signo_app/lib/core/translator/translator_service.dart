import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';

import 'gemini_strategy.dart';
import 'local_matcher.dart';

/// Which strategy produced a translation.
enum TranslationEngine { local, gemini }

/// Outcome of translating a Spanish sentence into an LSC gloss sequence.
class TranslationResult {
  const TranslationResult({
    required this.glosses,
    required this.engine,
    this.unknownWords = const <String>[],
    this.notice,
  });

  /// Ordered gloss sequence ready for the sequence player.
  final List<Gloss> glosses;
  final TranslationEngine engine;

  /// Input words excluded for being out of vocabulary (local engine only).
  final List<String> unknownWords;

  /// Spanish, user-facing notice (unknown words / empty result); null when
  /// there is nothing to surface.
  final String? notice;
}

/// A translation strategy: Spanish text in, translation result out.
///
/// Implementations: [LocalMatcher] (offline, always available) and
/// [GeminiStrategy] (remote enhancement, optional). This is the seam where
/// any future engine plugs in without touching [TranslatorService].
abstract interface class TranslatorStrategy {
  Future<TranslationResult> translate(String input);
}

/// Offline-first translator facade (design #172).
///
/// The local strategy ALWAYS runs so the answer never depends on the
/// network. When a remote strategy is configured its result is preferred,
/// but ANY error silently falls back to the local result — the spec's
/// graceful-fallback contract.
class TranslatorService {
  TranslatorService({
    required TranslatorStrategy localStrategy,
    TranslatorStrategy? remoteStrategy,
  }) : _local = localStrategy,
       _remote = remoteStrategy;

  final TranslatorStrategy _local;
  final TranslatorStrategy? _remote;

  Future<TranslationResult> translate(String input) async {
    final TranslationResult local = await _local.translate(input);
    final TranslatorStrategy? remote = _remote;
    if (remote == null) {
      return local;
    }
    try {
      return await remote.translate(input);
    } catch (_) {
      // Graceful fallback: offline-first guarantee (spec: translator).
      return local;
    }
  }
}

/// Builds the translator from the compiled content assets.
///
/// GATE D of the video-only rule, and it lives HERE, in the index handed to
/// [LocalMatcher] — deliberately not as a filter inside the matcher. The
/// matcher already asks the index to resolve every token, so handing it an
/// index whose lemma map cannot resolve a clip-less word makes
/// `mapTokensToGlosses` classify those words as `unknownWords` by
/// construction, and the EXISTING notice ("Se omitieron palabras fuera de
/// vocabulario: …") then tells the user exactly what happened. A second
/// filtering layer in the matcher would have to duplicate that classification
/// and would produce the same outcome with no way to explain it to the user.
///
/// `copyWithVideoOnly()` rather than `VocabIndex.build(...)`: the asset was
/// already parsed into `vocabIndexProvider`, and this reuses those entries
/// instead of decoding `vocab.json` a second time on every app start.
///
/// The remote slot holds the keyless [GeminiStrategy] stub: the key arrives
/// at build time via `--dart-define=GEMINI_API_KEY=...` (never committed);
/// with no key the stub fails fast and the service always answers locally.
/// Unaffected by the video-only index — it never touches the vocabulary.
final FutureProvider<TranslatorService> translatorServiceProvider =
    FutureProvider<TranslatorService>((Ref ref) async {
      final VocabIndex index = await ref.watch(vocabIndexProvider.future);
      final GrammarRuleSet rules = await ref.watch(
        grammarRuleSetProvider.future,
      );
      return TranslatorService(
        localStrategy: LocalMatcher(index: index.copyWithVideoOnly(), rules: rules),
        remoteStrategy: GeminiStrategy(
          apiKey: const String.fromEnvironment('GEMINI_API_KEY'),
        ),
      );
    });
