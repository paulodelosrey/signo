import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';

/// Small in-memory vocabulary fixture (same JSON shape as
/// `assets/content/vocab.json`).
const String _fixtureJson = '''
{
  "source": "test fixture",
  "count": 8,
  "signs": [
    {"id": "l3-001", "gloss": "YO", "lemmas": ["yo"], "lesson": 3, "subtema": "Sujeto", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-002", "gloss": "TU", "lemmas": ["tu"], "lesson": 3, "subtema": "Sujeto", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-003", "gloss": "CASA", "lemmas": ["casa"], "lesson": 3, "subtema": "Lugar", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-004", "gloss": "ESTUDIAR", "lemmas": ["estudiar"], "lesson": 3, "subtema": "Acciones", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-005", "gloss": "AYER", "lemmas": ["ayer"], "lesson": 3, "subtema": "Tiempo", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-001", "gloss": "TIO", "lemmas": ["tio", "tia"], "lesson": 1, "subtema": "Familia", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-002", "gloss": "CAFE", "lemmas": ["cafe"], "lesson": 1, "subtema": "Colores", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l5-001", "gloss": "SI", "lemmas": ["si"], "lesson": 5, "subtema": "Negación y afirmación", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false}
  ]
}
''';

/// Grammar fixture mirroring assets/content/grammar.json structure.
GrammarRuleSet buildRules() {
  return GrammarRuleSet.fromJson(<String, Object?>{
    'provenance': <String, Object?>{
      'note': 'test fixture',
      'rules': <Object?>{},
    },
    'categories': <String, Object?>{
      'copula': <String>['ser', 'es', 'soy', 'esta', 'estoy'],
      'connectors': <String>['que', 'y', 'pero', 'porque', 'si'],
      'intensifiers': <String>['muy'],
      'articles': <String>['el', 'la', 'los', 'las'],
      'prepositions': <String>['a', 'en', 'de', 'con'],
      'timeExpressions': <String>['ayer', 'manana', 'ahora', 'hoy'],
      'verbs': <String>['estudiar', 'ayudar', 'comprar'],
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
      <String, Object?>{
        'id': 'drop-intensifiers',
        'match': <String, Object?>{'category': 'intensifiers'},
        'action': 'drop',
      },
      <String, Object?>{
        'id': 'drop-articles',
        'match': <String, Object?>{'category': 'articles'},
        'action': 'drop',
      },
      <String, Object?>{
        'id': 'drop-prepositions',
        'match': <String, Object?>{'category': 'prepositions'},
        'action': 'drop',
      },
      <String, Object?>{
        'id': 'time-front',
        'match': <String, Object?>{'category': 'timeExpressions'},
        'action': 'front',
      },
      <String, Object?>{
        'id': 'reorder',
        'match': <String, Object?>{'category': 'verbs'},
        'action': 'verb-final',
      },
    ],
  });
}

VocabIndex buildIndex() => VocabIndex.fromJsonString(_fixtureJson);

List<String> labels(GlossMappingResult result) =>
    result.glosses.map((Gloss g) => g.label).toList();

void main() {
  late VocabIndex index;
  late GrammarRuleSet rules;

  setUp(() {
    index = buildIndex();
    rules = buildRules();
  });

  group('drop-copula', () {
    test('removes the Spanish copula between content signs', () {
      final GlossMappingResult result = mapTokensToGlosses(
        <String>['yo', 'soy', 'feliz'],
        index,
        rules,
      );

      expect(labels(result), <String>['YO']);
      expect(result.droppedWords, <WordDrop>[
        const WordDrop(word: 'soy', ruleId: 'drop-copula'),
      ]);
      expect(result.unknownWords, <String>['feliz']);
    });
  });

  group('drop-connectors', () {
    test('removes connectors between signs', () {
      final GlossMappingResult result = mapTokensToGlosses(
        <String>['yo', 'y', 'casa'],
        index,
        rules,
      );

      expect(labels(result), <String>['YO', 'CASA']);
      expect(result.droppedWords.single.ruleId, 'drop-connectors');
    });

    test('vocabulary wins over rules: SI is a sign, not a connector', () {
      final GlossMappingResult result = mapTokensToGlosses(
        <String>['si'],
        index,
        rules,
      );

      expect(labels(result), <String>['SI']);
      expect(result.droppedWords, isEmpty);
    });
  });

  group('time-front', () {
    test('fronts the time expression as topic', () {
      final GlossMappingResult result = mapTokensToGlosses(
        <String>['yo', 'estudiar', 'ayer'],
        index,
        rules,
      );

      expect(labels(result), <String>['AYER', 'YO', 'ESTUDIAR']);
      expect(result.glosses.first.isTime, isTrue);
    });
  });

  group('reorder (verb-final)', () {
    test('moves the verb to the end of the clause', () {
      final GlossMappingResult result = mapTokensToGlosses(
        <String>['estudiar', 'yo', 'casa'],
        index,
        rules,
      );

      expect(labels(result), <String>['YO', 'CASA', 'ESTUDIAR']);
    });

    test('leaves a single verb sign untouched', () {
      final GlossMappingResult result = mapTokensToGlosses(
        <String>['estudiar'],
        index,
        rules,
      );

      expect(labels(result), <String>['ESTUDIAR']);
    });
  });

  group('unknown words', () {
    test('excludes out-of-vocabulary words for the translator notice', () {
      final GlossMappingResult result = mapTokensToGlosses(
        <String>['gato', 'casa', 'que', 'telescopio'],
        index,
        rules,
      );

      expect(labels(result), <String>['CASA']);
      expect(result.unknownWords, <String>['gato', 'telescopio']);
      expect(result.droppedWords.map((WordDrop d) => d.word), <String>['que']);
    });
  });

  group('lemma matching', () {
    test('matches accents and case-insensitively', () {
      expect(index.lookup('Tío')!.gloss, 'TIO');
      expect(index.lookup('CAFÉ')!.gloss, 'CAFE');
      expect(index.lookupLemma('tia')!.gloss, 'TIO');
    });
  });
}
