import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';

import 'translator_service.dart';

/// Splits raw Spanish input into matchable tokens: punctuation becomes a
/// separator, then whitespace-split, keeping non-empty pieces.
///
/// The gloss mapper normalizes case/diacritics itself (`normalizeForMatch`),
/// so tokens stay close to the user's raw input for the notice copy.
List<String> tokenizeSentence(String input) {
  final String cleaned = input.replaceAll(
    RegExp("[-,;:.!?¿¡\"'()\u2013\u2014]"),
    ' ',
  );
  return cleaned
      .split(RegExp(r'\s+'))
      .where((String token) => token.isNotEmpty)
      .toList();
}

/// Builds the Spanish notice a local translation should surface, or null
/// when everything went through cleanly (spec: unknown words MUST be
/// excluded with a visible notice).
String? buildLocalNotice(GlossMappingResult mapping) {
  if (mapping.glosses.isEmpty) {
    return 'No encontré señas conocidas en tu frase.';
  }
  if (mapping.unknownWords.isEmpty) {
    return null;
  }
  return 'Se omitieron palabras fuera de vocabulario: '
      '${mapping.unknownWords.join(', ')}.';
}

/// Default OFFLINE translation path: composes the M2 gloss-mapper core
/// (vocabulary lookup + grammar rules: copula/connectors/articles/
/// prepositions drops, time-fronting, verb-final reorder). No network and
/// no platform channels — pure Dart over the compiled assets.
///
/// VIDEO-ONLY: [index] is expected to be `VocabIndex.copyWithVideoOnly()` (see
/// [translatorServiceProvider]). A clip-less word is therefore not "matched
/// then filtered", it simply does not resolve: `mapTokensToGlosses` classifies
/// it as unknown and [buildLocalNotice] tells the user the word was omitted.
/// This is why there is no `hasVideo` check in this class — the gate is the
/// index, and duplicating it here would only make the omission unexplainable.
class LocalMatcher implements TranslatorStrategy {
  LocalMatcher({required this.index, required this.rules});

  final VocabIndex index;
  final GrammarRuleSet rules;

  @override
  Future<TranslationResult> translate(String input) async {
    final GlossMappingResult mapping = mapTokensToGlosses(
      tokenizeSentence(input),
      index,
      rules,
    );
    return TranslationResult(
      glosses: _collapseConsecutiveDuplicates(mapping.glosses),
      engine: TranslationEngine.local,
      unknownWords: mapping.unknownWords,
      notice: buildLocalNotice(mapping),
    );
  }

  /// Multi-word phrases whose words resolve to the SAME sign ("buenos
  /// días" → BUENOS-DIAS) must play once, not once per token. Only
  /// consecutive same-entry glosses collapse; legitimate repetitions
  /// separated by other signs survive.
  List<Gloss> _collapseConsecutiveDuplicates(List<Gloss> glosses) {
    final List<Gloss> collapsed = <Gloss>[];
    for (final Gloss gloss in glosses) {
      if (collapsed.isEmpty || collapsed.last.entryId != gloss.entryId) {
        collapsed.add(gloss);
      }
    }
    return collapsed;
  }
}
