import '../../core/lsc_vocab/lsc_vocab.dart';

/// Filters dictionary entries for a user query (spec `visual-dictionary`:
/// "searchable read-only dictionary").
///
/// Matching is substring-based and goes through [normalizeForMatch], so the
/// search is case-insensitive and Spanish-diacritics-insensitive (`cafe`
/// finds CAFÉ). An empty (or blank) query returns every entry, which is the
/// browse-all view of the compiled vocabulary.
List<VocabEntry> searchSigns(List<VocabEntry> entries, String query) {
  final String needle = normalizeForMatch(query).trim();
  if (needle.isEmpty) {
    return entries;
  }
  return <VocabEntry>[
    for (final VocabEntry entry in entries)
      if (normalizeForMatch(entry.gloss).contains(needle) ||
          entry.lemmas.any(
            (String lemma) => normalizeForMatch(lemma).contains(needle),
          ))
        entry,
  ];
}
