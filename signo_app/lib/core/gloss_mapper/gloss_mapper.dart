import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';

/// A single sign in a translated gloss sequence.
class Gloss {
  const Gloss({
    required this.label,
    required this.entryId,
    required this.subtema,
    required this.isTime,
  });

  /// Uppercase gloss label (e.g. `CASA`).
  final String label;
  final String entryId;
  final String subtema;

  /// True when the sign is a time expression (fronted by `time-front`).
  final bool isTime;

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      other is Gloss &&
      other.label == label &&
      other.entryId == entryId &&
      other.isTime == isTime;

  @override
  int get hashCode => Object.hash(label, entryId, isTime);
}

/// A function word removed by a grammar rule (e.g. copula, connector).
class WordDrop {
  const WordDrop({required this.word, required this.ruleId});
  final String word;
  final String ruleId;

  @override
  bool operator ==(Object other) =>
      other is WordDrop && other.word == word && other.ruleId == ruleId;

  @override
  int get hashCode => Object.hash(word, ruleId);
}

/// Outcome of mapping Spanish tokens to an LSC gloss sequence.
/// [unknownWords] feeds the translator's "word not in vocabulary" notice.
class GlossMappingResult {
  const GlossMappingResult({
    required this.glosses,
    required this.unknownWords,
    required this.droppedWords,
  });

  final List<Gloss> glosses;
  final List<String> unknownWords;
  final List<WordDrop> droppedWords;

  @override
  bool operator ==(Object other) =>
      other is GlossMappingResult &&
      other.glosses == glosses &&
      other.unknownWords == unknownWords &&
      other.droppedWords == droppedWords;

  @override
  int get hashCode => Object.hash(glosses, unknownWords, droppedWords);
}

enum _TokenKind { vocabSign, ruleDrop, unknown }

class _Token {
  const _Token(this.kind, this.raw, {this.entry, this.rule});
  final _TokenKind kind;
  final String raw;
  final VocabEntry? entry;
  final GrammarRule? rule;
}

bool _entryIsVerb(VocabEntry entry, GrammarRuleSet rules) {
  if (entry.subtema == 'Acciones') {
    return true;
  }
  final Set<String> verbs = rules.categoryWords('verbs');
  return entry.lemmas.any(verbs.contains);
}

bool _entryIsTime(VocabEntry entry, GrammarRuleSet rules) {
  if (entry.subtema == 'Tiempo') {
    return true;
  }
  final Set<String> timeWords = rules.categoryWords('timeExpressions');
  return entry.lemmas.any(timeWords.contains);
}

/// Maps normalized Spanish tokens to an LSC gloss sequence.
///
/// Pipeline (chapter provenance lives in `assets/content/grammar.json`):
/// 1. vocabulary match first — a lexical sign always wins over rules, so
///    `si` maps to the SI sign instead of being dropped as a connector;
/// 2. unmatched tokens falling in a drop category (copula, connectors,
///    intensifiers, articles, prepositions) are removed and recorded;
/// 3. anything else is unknown and surfaced for the translator notice;
/// 4. `time-front`: time expressions are stably moved to the front;
/// 5. `reorder` (verb-final): with more than one matched sign, verbs are
///    stably moved to the end (LSC topic-comment approximation).
GlossMappingResult mapTokensToGlosses(
  List<String> tokens,
  VocabIndex index,
  GrammarRuleSet rules,
) {
  final List<_Token> classified = <_Token>[];
  for (final String raw in tokens) {
    final String normalized = normalizeForMatch(raw);
    final VocabEntry? entry = index.lookupLemma(normalized);
    if (entry != null) {
      classified.add(_Token(_TokenKind.vocabSign, raw, entry: entry));
      continue;
    }
    final GrammarRule? rule = rules.matchRule(normalized);
    if (rule != null && rule.action == 'drop') {
      classified.add(_Token(_TokenKind.ruleDrop, raw, rule: rule));
      continue;
    }
    classified.add(_Token(_TokenKind.unknown, raw));
  }

  final List<_Token> signs = classified
      .where((_Token t) => t.kind == _TokenKind.vocabSign)
      .toList();
  final List<WordDrop> droppedWords = classified
      .where((_Token t) => t.kind == _TokenKind.ruleDrop)
      .map((_Token t) => WordDrop(word: t.raw, ruleId: t.rule!.id))
      .toList();
  final List<String> unknownWords = classified
      .where((_Token t) => t.kind == _TokenKind.unknown)
      .map((_Token t) => t.raw)
      .toList();

  // time-front: stable partition, time expressions first.
  final List<VocabEntry> timeFirst = <VocabEntry>[];
  final List<VocabEntry> rest = <VocabEntry>[];
  for (final _Token token in signs) {
    final VocabEntry entry = token.entry!;
    (_entryIsTime(entry, rules) ? timeFirst : rest).add(entry);
  }
  List<VocabEntry> ordered = <VocabEntry>[...timeFirst, ...rest];

  // reorder (verb-final): only when the clause has more than one sign.
  if (ordered.length > 1) {
    final List<VocabEntry> verbs = <VocabEntry>[];
    final List<VocabEntry> nonVerbs = <VocabEntry>[];
    for (final VocabEntry entry in ordered) {
      (_entryIsVerb(entry, rules) ? verbs : nonVerbs).add(entry);
    }
    if (verbs.isNotEmpty) {
      ordered = <VocabEntry>[...nonVerbs, ...verbs];
    }
  }

  final List<Gloss> glosses = ordered
      .map(
        (VocabEntry entry) => Gloss(
          label: entry.gloss,
          entryId: entry.id,
          subtema: entry.subtema,
          isTime: _entryIsTime(entry, rules),
        ),
      )
      .toList();

  return GlossMappingResult(
    glosses: glosses,
    unknownWords: unknownWords,
    droppedWords: droppedWords,
  );
}
