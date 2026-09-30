import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asset paths for the compiled LSC content (see `tool/parse_vocab.dart`).
const String kVocabAssetPath = 'assets/content/vocab.json';
const String kGrammarAssetPath = 'assets/content/grammar.json';

/// Normalizes a token or lemma for matching: lowercase + Spanish diacritics
/// stripped. Must stay in sync with `normalizeLemma` in `tool/parse_vocab.dart`.
String normalizeForMatch(String input) {
  const Map<String, String> accents = <String, String>{
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u', 'â': 'a', 'ê': 'e',
    'î': 'i', 'ô': 'o', 'û': 'u', 'ã': 'a', 'õ': 'o', 'ç': 'c', 'ï': 'i',
    'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
  };
  final StringBuffer buffer = StringBuffer();
  for (final int rune in input.runes) {
    final String ch = String.fromCharCode(rune);
    buffer.write(accents[ch] ?? ch.toLowerCase());
  }
  return buffer.toString();
}

/// One sign of the LSC vocabulary, compiled from the MonikLSC spreadsheet.
class VocabEntry {
  const VocabEntry({
    required this.id,
    required this.gloss,
    required this.lemmas,
    required this.lesson,
    required this.subtema,
    required this.hasVideo,
    this.asset,
    this.releasePath,
    this.trimStartMs,
    this.trimEndMs,
  });

  factory VocabEntry.fromJson(Map<String, Object?> json) {
    return VocabEntry(
      id: json['id']! as String,
      gloss: json['gloss']! as String,
      lemmas: (json['lemmas']! as List<Object?>).cast<String>(),
      lesson: json['lesson']! as int,
      subtema: json['subtema']! as String,
      asset: json['asset'] as String?,
      releasePath: json['releasePath'] as String?,
      trimStartMs: json['trimStartMs'] as int?,
      trimEndMs: json['trimEndMs'] as int?,
      hasVideo: json['hasVideo']! as bool,
    );
  }

  final String id;

  /// Uppercase gloss label (e.g. `CASA`, `BUENOS-DIAS`).
  final String gloss;

  /// Diacritics-stripped lowercase lookup forms (variants included:
  /// `Tío/a` → `[tio, tia]`).
  final List<String> lemmas;
  final int lesson;
  final String subtema;

  /// Video fields; null until video curation fills them in.
  final String? asset;
  final String? releasePath;
  final int? trimStartMs;
  final int? trimEndMs;
  final bool hasVideo;

  /// THE product rule, in one predicate: a sign is only usable when the
  /// manifest attached BOTH the `hasVideo` flag and the clip path.
  ///
  /// `hasVideo` alone is not enough — it is a manifest-level boolean, while
  /// `asset` is what [SignVideoPlayer] actually loads. An entry claiming a
  /// clip with a null `asset` would render a card that can never play, which
  /// is exactly the dead surface the video-only rule exists to remove.
  bool get isVideoBacked => hasVideo && asset != null;

  @override
  bool operator ==(Object other) => other is VocabEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One grammar rule distilled from the DBLSC chapters (ch02/ch03/ch08).
class GrammarRule {
  const GrammarRule({required this.id, required this.category, required this.action});

  factory GrammarRule.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> match = json['match']! as Map<String, Object?>;
    return GrammarRule(
      id: json['id']! as String,
      category: match['category']! as String,
      action: json['action']! as String,
    );
  }

  final String id;
  final String category;
  final String action;
}

/// Categories + rules loaded from `grammar.json`, with chapter provenance.
class GrammarRuleSet {
  const GrammarRuleSet({
    required this.provenanceNote,
    required this.categories,
    required this.rules,
  });

  factory GrammarRuleSet.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> provenance =
        json['provenance']! as Map<String, Object?>;
    final Map<String, Object?> rawCategories =
        json['categories']! as Map<String, Object?>;
    final Map<String, Set<String>> categories = <String, Set<String>>{
      for (final MapEntry<String, Object?> entry in rawCategories.entries)
        entry.key: (entry.value! as List<Object?>)
            .map((Object? word) => normalizeForMatch(word! as String))
            .toSet(),
    };
    final List<GrammarRule> rules = (json['rules']! as List<Object?>)
        .map((Object? rule) =>
            GrammarRule.fromJson(rule! as Map<String, Object?>))
        .toList();
    return GrammarRuleSet(
      provenanceNote: provenance['note']! as String,
      categories: categories,
      rules: rules,
    );
  }

  final String provenanceNote;

  /// Category name → normalized word set (e.g. `copula`, `timeExpressions`).
  final Map<String, Set<String>> categories;
  final List<GrammarRule> rules;

  /// Words in [category]; empty set when the category does not exist.
  Set<String> categoryWords(String category) =>
      categories[category] ?? const <String>{};

  /// First rule whose category contains [word] (rule order = priority).
  GrammarRule? matchRule(String word) {
    for (final GrammarRule rule in rules) {
      if (categoryWords(rule.category).contains(word)) {
        return rule;
      }
    }
    return null;
  }
}

/// In-memory vocabulary index: normalized lemma → entry (first CSV
/// occurrence wins on duplicates like CAFE in L1 and L4).
///
/// A [VocabIndex] comes in two flavours, both built by [VocabIndex.build]:
///
/// * COMPLETE (the default) — all compiled signs, clip-less ones included.
///   The dictionary needs this: a user must be able to look up a sign the app
///   cannot yet play.
/// * VIDEO-ONLY — [entries] and the lemma map are reduced to
///   [VocabEntry.isVideoBacked] signs. Everything that TEACHES or TRANSLATES
///   (learning path, exercises, Repasar, Práctica, translator) uses this
///   flavour, so a clip-less sign can never be reached there. The dictionary
///   keeps the complete one.
class VocabIndex {
  VocabIndex._(this.entries, this._lemmaIndex);

  factory VocabIndex.build(
    List<VocabEntry> entries, {
    bool videoOnly = false,
  }) {
    // The predicate lives on the entry, never on a caller-side re-check: one
    // definition, so the four gates cannot drift apart.
    final List<VocabEntry> source = videoOnly
        ? <VocabEntry>[
            for (final VocabEntry entry in entries)
              if (entry.isVideoBacked) entry,
          ]
        : entries;
    // The lemma map MUST be derived from the same filtered list, not merely
    // dropped from the full one: `lookup` on a video-only index has to return
    // null for a clip-less word, and deriving it from the survivors is the
    // only way that is guaranteed by construction rather than by inspection.
    final Map<String, VocabEntry> lemmaIndex = <String, VocabEntry>{};
    for (final VocabEntry entry in source) {
      for (final String lemma in entry.lemmas) {
        lemmaIndex.putIfAbsent(normalizeForMatch(lemma), () => entry);
      }
      lemmaIndex.putIfAbsent(normalizeForMatch(entry.gloss), () => entry);
    }
    return VocabIndex._(List<VocabEntry>.unmodifiable(source), lemmaIndex);
  }

  /// Always the COMPLETE index: the dictionary and the gloss-mapper tests
  /// need every compiled sign, clip-less ones included. The video-only
  /// flavour is opt-in through [build]'s flag or [copyWithVideoOnly].
  factory VocabIndex.fromJsonString(String jsonString) {
    final Map<String, Object?> json =
        jsonDecode(jsonString)! as Map<String, Object?>;
    final List<VocabEntry> entries = (json['signs']! as List<Object?>)
        .map((Object? sign) =>
            VocabEntry.fromJson(sign! as Map<String, Object?>))
        .toList();
    return VocabIndex.build(entries);
  }

  final List<VocabEntry> entries;
  final Map<String, VocabEntry> _lemmaIndex;

  /// Only the signs that ship a playable clip, in first-appearance (CSV)
  /// order. This is THE list every teaching surface iterates.
  late final List<VocabEntry> videoEntries = List<VocabEntry>.unmodifiable(
    <VocabEntry>[
      for (final VocabEntry entry in entries)
        if (entry.isVideoBacked) entry,
    ],
  );

  int get count => entries.length;

  /// A video-only VIEW of an already-parsed index.
  ///
  /// The translator needs the same 201-entry asset as the dictionary but must
  /// not see the 142 clip-less signs, and re-reading the asset just to
  /// re-derive the filtered index would double the parse on every app start.
  /// Entry order is preserved, so the filtered set matches `build` exactly.
  ///
  /// The lemma map is rebuilt from the already-parsed survivors rather than
  /// filtered from the complete one on purpose: if a clip-less sign and a
  /// clip-backed one share a lemma (e.g. `cafe` in two lessons), filtering
  /// would delete the key and silently hide a sign that CAN be played.
  VocabIndex copyWithVideoOnly() => VocabIndex.build(videoEntries, videoOnly: true);

  /// Resolves a raw (possibly accented, any-case) token to its entry.
  VocabEntry? lookup(String token) =>
      _lemmaIndex[normalizeForMatch(token)];

  /// Resolves an already-normalized lemma directly.
  VocabEntry? lookupLemma(String lemma) => _lemmaIndex[lemma];

  /// Resolves an entry by id (e.g. a `Gloss.entryId` rendered through the
  /// SignView seam); null when unknown.
  VocabEntry? byId(String id) {
    for (final VocabEntry entry in entries) {
      if (entry.id == id) {
        return entry;
      }
    }
    return null;
  }
}

/// Loads the compiled content assets at startup.
class VocabRepository {
  const VocabRepository();

  Future<VocabIndex> loadVocabIndex() async {
    final String raw = await rootBundle.loadString(kVocabAssetPath);
    return VocabIndex.fromJsonString(raw);
  }

  Future<GrammarRuleSet> loadGrammarRules() async {
    final String raw = await rootBundle.loadString(kGrammarAssetPath);
    return GrammarRuleSet.fromJson(
      jsonDecode(raw)! as Map<String, Object?>,
    );
  }
}

/// Overridable repository provider (tests inject fixtures via the pure
/// builders instead).
final Provider<VocabRepository> vocabRepositoryProvider =
    Provider<VocabRepository>((Ref ref) => const VocabRepository());

/// Synchronous-ready access to the vocabulary: watch as [AsyncValue] for
/// sync states, or `await` the future for one-shot loads.
final FutureProvider<VocabIndex> vocabIndexProvider =
    FutureProvider<VocabIndex>(
  (Ref ref) => ref.watch(vocabRepositoryProvider).loadVocabIndex(),
);

/// Synchronous-ready access to the grammar rule set.
final FutureProvider<GrammarRuleSet> grammarRuleSetProvider =
    FutureProvider<GrammarRuleSet>(
  (Ref ref) => ref.watch(vocabRepositoryProvider).loadGrammarRules(),
);
