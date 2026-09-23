import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/features/dictionary/dictionary_search.dart';

VocabEntry entry(String id, String gloss, List<String> lemmas) => VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: lemmas,
      lesson: 1,
      subtema: 'Saludos',
      hasVideo: false,
    );

final List<VocabEntry> fixture = <VocabEntry>[
  entry('d1', 'HOLA', <String>['hola']),
  entry('d2', 'CAFÉ', <String>['café', 'coffee']),
  entry('d3', 'CASA', <String>['casa']),
  entry('d4', 'BUENOS-DIAS', <String>['buenos dias', 'bueno']),
];

void main() {
  group('searchSigns', () {
    test('empty query returns every entry (browse-all view)', () {
      expect(searchSigns(fixture, '').length, 4);
      expect(searchSigns(fixture, '   ').length, 4);
    });

    test('matches a gloss substring ignoring case and accents', () {
      // `cafe` (no accent, lowercase) must find CAFÉ.
      final List<VocabEntry> results = searchSigns(fixture, 'cafe');
      expect(results.map((VocabEntry e) => e.id), <String>['d2']);
      // Substring (not exact) match, any case.
      expect(searchSigns(fixture, 'HO').map((VocabEntry e) => e.id),
          <String>['d1']);
    });

    test('matches any lemma, not just the gloss', () {
      // 'coffee' is a secondary lemma of CAFÉ.
      expect(searchSigns(fixture, 'coffee').map((VocabEntry e) => e.id),
          <String>['d2']);
      // Multi-word lemma with the query split across the blank.
      expect(searchSigns(fixture, 'buenos').map((VocabEntry e) => e.id),
          <String>['d4']);
    });

    test('returns an empty list when nothing matches', () {
      expect(searchSigns(fixture, 'zzz'), isEmpty);
    });
  });
}
