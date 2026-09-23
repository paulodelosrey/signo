import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';

const String _fixtureJson = '''
{
  "source": "test fixture",
  "count": 4,
  "signs": [
    {"id": "l3-001", "gloss": "CASA", "lemmas": ["casa"], "lesson": 3, "subtema": "Lugar", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-001", "gloss": "TIO", "lemmas": ["tio", "tia"], "lesson": 1, "subtema": "Familia", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l5-001", "gloss": "BUENOS-DIAS", "lemmas": ["buenos", "dias"], "lesson": 1, "subtema": "Saludos formales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-002", "gloss": "CAFE-DUP", "lemmas": ["cafe"], "lesson": 4, "subtema": "Comida", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false}
  ]
}
''';

void main() {
  group('VocabIndex', () {
    test('builds from JSON string with all entries', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      expect(index.count, 4);
      expect(index.entries.map((VocabEntry e) => e.gloss),
          containsAll(<String>['CASA', 'TIO', 'BUENOS-DIAS']));
    });

    test('resolves lemmas and gloss labels case-insensitively', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      expect(index.lookup('casa')!.id, 'l3-001');
      expect(index.lookup('CASA')!.id, 'l3-001');
      expect(index.lookupLemma('dias')!.gloss, 'BUENOS-DIAS');
    });

    test('exposes gender variants as separate lemmas of one entry', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      final VocabEntry? viaMasculine = index.lookupLemma('tio');
      final VocabEntry? viaFeminine = index.lookupLemma('tia');
      expect(viaMasculine, isNotNull);
      expect(viaFeminine, isNotNull);
      expect(viaMasculine!.id, viaFeminine!.id);
    });

    test('first entry wins when two signs share a lemma', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      // The fixture deliberately declares CAFE-DUP with no earlier CAFE
      // sibling, so it owns the lemma; add one to prove first-wins.
      final VocabIndex withDuplicate = VocabIndex.build(<VocabEntry>[
        const VocabEntry(
          id: 'l1-009',
          gloss: 'CAFE',
          lemmas: <String>['cafe'],
          lesson: 1,
          subtema: 'Colores',
          hasVideo: false,
        ),
        const VocabEntry(
          id: 'l4-008',
          gloss: 'CAFE-DUP',
          lemmas: <String>['cafe'],
          lesson: 4,
          subtema: 'Comida',
          hasVideo: false,
        ),
      ]);

      expect(withDuplicate.lookupLemma('cafe')!.id, 'l1-009');
      expect(index.count, 4);
    });

    test('returns null for unknown lemmas without throwing', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      expect(index.lookup('telescopio'), isNull);
      expect(index.lookup(''), isNull);
    });
  });

  group('GrammarRuleSet', () {
    test('parses categories normalized and resolves rules in order', () {
      final GrammarRuleSet rules = GrammarRuleSet.fromJson(<String, Object?>{
        'provenance': <String, Object?>{'note': 'fixture'},
        'categories': <String, Object?>{
          'copula': <String>['Es', 'SOY'],
          'connectors': <String>['y'],
        },
        'rules': <Object?>[
          <String, Object?>{
            'id': 'drop-copula',
            'match': <String, Object?>{'category': 'copula'},
            'action': 'drop',
          },
          <String, Object?>{
            'id': 'drop-connectors',
            'match': <String, Object?>{'category': 'connectors'},
            'action': 'drop',
          },
        ],
      });

      expect(rules.matchRule('es')!.id, 'drop-copula');
      expect(rules.matchRule('soy')!.id, 'drop-copula');
      expect(rules.matchRule('y')!.id, 'drop-connectors');
      expect(rules.matchRule('casa'), isNull);
      expect(rules.categoryWords('missing'), isEmpty);
      expect(rules.provenanceNote, 'fixture');
    });
  });
}
