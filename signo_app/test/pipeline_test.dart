import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/translator/gemini_strategy.dart';
import 'package:signo_app/core/translator/local_matcher.dart';
import 'package:signo_app/core/translator/translator_service.dart';

/// In-memory vocabulary fixture (same JSON shape as the compiled asset).
const String _fixtureJson = '''
{
  "source": "test fixture",
  "count": 12,
  "signs": [
    {"id": "l1-001", "gloss": "HOLA", "lemmas": ["hola"], "lesson": 1, "subtema": "Saludos informales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-002", "gloss": "GRACIAS", "lemmas": ["gracias"], "lesson": 1, "subtema": "Saludos informales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-003", "gloss": "BUENOS-DIAS", "lemmas": ["buenos dias", "buenos", "dias"], "lesson": 1, "subtema": "Saludos informales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-004", "gloss": "COMO-ESTAS", "lemmas": ["como estas", "como", "estas"], "lesson": 1, "subtema": "Saludos informales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l2-001", "gloss": "TIO", "lemmas": ["tio", "tia"], "lesson": 2, "subtema": "Familia", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l2-002", "gloss": "CAFE", "lemmas": ["cafe"], "lesson": 2, "subtema": "Colores", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-001", "gloss": "YO", "lemmas": ["yo"], "lesson": 3, "subtema": "Sujeto", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-002", "gloss": "TU", "lemmas": ["tu"], "lesson": 3, "subtema": "Sujeto", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-003", "gloss": "CASA", "lemmas": ["casa"], "lesson": 3, "subtema": "Lugar", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-004", "gloss": "ESTUDIAR", "lemmas": ["estudiar"], "lesson": 3, "subtema": "Acciones", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-005", "gloss": "AYER", "lemmas": ["ayer"], "lesson": 3, "subtema": "Tiempo", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
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

LocalMatcher buildLocal() =>
    LocalMatcher(index: buildIndex(), rules: buildRules());

List<String> labels(TranslationResult result) =>
    result.glosses.map((Gloss g) => g.label).toList();

/// Remote strategy stub: returns the configured result or throws when none.
class _StubStrategy implements TranslatorStrategy {
  const _StubStrategy(this.result);

  final TranslationResult? result;

  @override
  Future<TranslationResult> translate(String input) async {
    final TranslationResult? value = result;
    if (value == null) {
      throw StateError('remote unavailable');
    }
    return value;
  }
}

void main() {
  group('tokenizeSentence', () {
    test('splits on punctuation and whitespace, dropping empties', () {
      expect(
        tokenizeSentence('¡Hola!,  ¿Cómo; estas? Muy (bien)'),
        <String>['Hola', 'Cómo', 'estas', 'Muy', 'bien'],
      );
      expect(tokenizeSentence('   '), <String>[]);
      expect(tokenizeSentence(''), <String>[]);
    });

    test('keeps accented letters intact for notice copy', () {
      expect(tokenizeSentence('Tía café'), <String>['Tía', 'café']);
    });
  });

  group('LocalMatcher (offline scripted translation)', () {
    test('maps a scripted sentence through the gloss-mapper core', () async {
      final TranslationResult result = await buildLocal().translate(
        'Ayer yo estudiar en la casa',
      );

      // time-front: AYER leads; verb-final: ESTUDIAR closes; `en`/`la`
      // dropped by preposition/article rules.
      expect(labels(result), <String>['AYER', 'YO', 'CASA', 'ESTUDIAR']);
      expect(result.glosses.first.isTime, isTrue);
      expect(result.engine, TranslationEngine.local);
      expect(result.unknownWords, isEmpty);
      expect(result.notice, isNull);
    });

    test('drops the copula between content signs', () async {
      final TranslationResult result = await buildLocal().translate(
        'yo soy tio',
      );

      // The copula drops; both content signs survive and keep their order.
      expect(labels(result), <String>['YO', 'TIO']);
      expect(result.notice, isNull);
    });

    test('excludes unknown words with a visible notice', () async {
      final TranslationResult result = await buildLocal().translate(
        'gato casa telescopio',
      );

      expect(labels(result), <String>['CASA']);
      expect(result.unknownWords, <String>['gato', 'telescopio']);
      expect(
        result.notice,
        'Se omitieron palabras fuera de vocabulario: gato, telescopio.',
      );
    });

    test('reports an empty result when nothing is recognized', () async {
      final TranslationResult result = await buildLocal().translate('gato');

      expect(result.glosses, isEmpty);
      expect(result.notice, 'No encontré señas conocidas en tu frase.');
    });

    test('collapses consecutive duplicates from multi-word phrases', () async {
      // `buenos` and `dias` are separate tokens resolving to ONE sign.
      final TranslationResult result = await buildLocal().translate(
        'buenos dias',
      );

      expect(labels(result), <String>['BUENOS-DIAS']);
    });

    test('matches accents and case-insensitively', () async {
      final TranslationResult result = await buildLocal().translate('TÍO');

      expect(labels(result), <String>['TIO']);
    });

    test('repetitions separated by other signs survive the collapse', () async {
      final TranslationResult result = await buildLocal().translate(
        'hola casa hola',
      );

      expect(labels(result), <String>['HOLA', 'CASA', 'HOLA']);
    });

    test('repetition joined by a dropped connector becomes adjacent and '
        'collapses', () async {
      // `y` drops, leaving two adjacent HOLA — indistinguishable from a
      // doubled phrase at token level, so the collapse folds them.
      final TranslationResult result = await buildLocal().translate(
        'hola y hola',
      );

      expect(labels(result), <String>['HOLA']);
    });
  });

  group('GeminiStrategy (keyless stub)', () {
    test('reports unconfigured without a key', () {
      expect(const GeminiStrategy().isConfigured, isFalse);
      expect(const GeminiStrategy(apiKey: '').isConfigured, isFalse);
      expect(const GeminiStrategy(apiKey: 'k').isConfigured, isTrue);
    });

    test('always fails fast so the local path stays the default', () async {
      await expectLater(
        const GeminiStrategy().translate('hola'),
        throwsA(isA<GeminiUnavailableError>()),
      );
    });
  });

  group('TranslatorService', () {
    test('uses the local engine when no remote is configured', () async {
      final TranslationResult result = await TranslatorService(
        localStrategy: buildLocal(),
      ).translate('hola');

      expect(result.engine, TranslationEngine.local);
      expect(labels(result), <String>['HOLA']);
    });

    test('prefers the remote result when it succeeds', () async {
      const TranslationResult remote = TranslationResult(
        glosses: <Gloss>[],
        engine: TranslationEngine.gemini,
      );
      final TranslationResult result = await TranslatorService(
        localStrategy: buildLocal(),
        remoteStrategy: const _StubStrategy(remote),
      ).translate('hola');

      expect(result.engine, TranslationEngine.gemini);
    });

    test('falls back to the local result on any remote error', () async {
      final TranslationResult result = await TranslatorService(
        localStrategy: buildLocal(),
        remoteStrategy: const _StubStrategy(null),
      ).translate('gato casa');

      expect(result.engine, TranslationEngine.local);
      expect(labels(result), <String>['CASA']);
      expect(result.unknownWords, <String>['gato']);
    });

    test('keyless Gemini stub behaves like a failed remote', () async {
      final TranslationResult result = await TranslatorService(
        localStrategy: buildLocal(),
        remoteStrategy: const GeminiStrategy(),
      ).translate('hola');

      expect(result.engine, TranslationEngine.local);
      expect(labels(result), <String>['HOLA']);
    });
  });

  group('gloss → SignView seam', () {
    test('byId resolves the gloss entry for the player card', () {
      final VocabIndex index = buildIndex();

      expect(index.byId('l3-003')?.gloss, 'CASA');
      expect(index.byId('missing'), isNull);
    });
  });
}
