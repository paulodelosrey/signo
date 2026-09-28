import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart';
import 'package:signo_app/core/tts/tts_service.dart';
import 'package:signo_app/features/translator/player_controller.dart';
import 'package:signo_app/features/translator/translator_screen.dart';

/// In-memory content fixture — loading real assets through rootBundle
/// inside repeated `testWidgets` FakeAsync zones is flaky (M3 lesson), so
/// the pipeline is injected instead; real assets stay covered by
/// vocab_assets_test.
const String _fixtureJson = '''
{
  "source": "test fixture",
  "count": 6,
  "signs": [
    {"id": "l1-001", "gloss": "HOLA", "lemmas": ["hola"], "lesson": 1, "subtema": "Saludos informales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-002", "gloss": "GRACIAS", "lemmas": ["gracias"], "lesson": 1, "subtema": "Frases comunes", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-003", "gloss": "CASA", "lemmas": ["casa"], "lesson": 1, "subtema": "Lugar", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-004", "gloss": "AYUDA", "lemmas": ["ayuda"], "lesson": 1, "subtema": "Frases comunes", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-005", "gloss": "CHAUV", "lemmas": ["chau"], "lesson": 1, "subtema": "Despedida", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l3-001", "gloss": "APRENDER", "lemmas": ["aprender"], "lesson": 3, "subtema": "Acciones", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false}
  ]
}
''';

GrammarRuleSet _buildRules() {
  return GrammarRuleSet.fromJson(<String, Object?>{
    'provenance': <String, Object?>{
      'note': 'translator widget fixture',
      'rules': <Object?>{},
    },
    'categories': <String, Object?>{
      'copula': <String>['ser', 'es', 'soy'],
      'connectors': <String>['que', 'y'],
      'intensifiers': <String>['muy'],
      'articles': <String>['el', 'la'],
      'prepositions': <String>['a', 'en', 'de'],
      'timeExpressions': <String>['ayer'],
      'verbs': <String>['estudiar'],
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

/// Recording fake so the real flutter_tts platform channel is NEVER touched.
class _RecordingTts implements TtsGateway {
  final List<String> spoken = <String>[];
  int stops = 0;

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stops++;
}

Future<void> _pumpTranslator(WidgetTester tester, _RecordingTts tts) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    // KineticButton reads the settings controller; reduced motion keeps
    // press animations instantaneous in tests.
    'signo.reducedMotion': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        vocabIndexProvider.overrideWith(
          (Ref ref) async => VocabIndex.fromJsonString(_fixtureJson),
        ),
        grammarRuleSetProvider.overrideWith(
          (Ref ref) async => _buildRules(),
        ),
        ttsGatewayProvider.overrideWithValue(tts),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SafeArea(child: TranslatorScreen())),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _translate(WidgetTester tester, String sentence) async {
  await tester.enterText(find.byType(TextField), sentence);
  await tester.tap(find.text('Traducir'));
  await tester.pumpAndSettle();
}

void main() {
  late _RecordingTts tts;

  setUp(() => tts = _RecordingTts());

  testWidgets('renders input, quick phrases and button before translating', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);

    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.text('Escribe una frase en español…'),
      ),
      findsOneWidget,
    );
    expect(find.text('Traducir'), findsOneWidget);
    // The four seeded quick phrases, in order.
    expect(find.text('hola, buenos días'), findsOneWidget);
    expect(find.text('gracias'), findsOneWidget);
    expect(find.text('¿cómo estás?'), findsOneWidget);
    expect(find.text('quiero aprender'), findsOneWidget);
    expect(find.text('Secuencia 1/1'), findsNothing);
  });

  testWidgets('scripted sentence produces the sequence player', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);
    await _translate(tester, 'hola casa');

    expect(find.text('Secuencia 1/2'), findsOneWidget);
    expect(find.text('HOLA'), findsOneWidget);
    // The fixture entries declare no clip, so SignView renders the text-mode
    // card; a real clip (hasVideo) swaps in the player inside the same box.
    expect(find.text('video en curaduría'), findsOneWidget);
    expect(tts.spoken, isEmpty); // nothing speaks until play is pressed
  });

  testWidgets('unknown word is excluded with a visible notice', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);
    await _translate(tester, 'zorro hola');

    expect(
      find.text('Se omitieron palabras fuera de vocabulario: zorro.'),
      findsOneWidget,
    );
    expect(find.text('Secuencia 1/1'), findsOneWidget);
    expect(find.text('HOLA'), findsOneWidget);
  });

  testWidgets(
    'play walks the sequence n/n speaking each sign, then stops at the end',
    (WidgetTester tester) async {
      await _pumpTranslator(tester, tts);
      await _translate(tester, 'hola gracias casa');

      // The seeded phrases wrap onto a second row, so the player card sits
      // lower in the 600px test viewport: scroll it into view before tapping.
      await tester.ensureVisible(find.byTooltip('Reproducir'));
      await tester.pump();
      await tester.tap(find.byTooltip('Reproducir'));
      await tester.pump(); // rebuild after play — NO pumpAndSettle: the
      // periodic playback timer would never let it settle.

      expect(find.byTooltip('Pausar'), findsOneWidget);
      expect(tts.spoken, <String>['hola']);

      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('Secuencia 2/3'), findsOneWidget);
      expect(tts.spoken, <String>['hola', 'gracias']);

      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text('Secuencia 3/3'), findsOneWidget);
      expect(tts.spoken, <String>['hola', 'gracias', 'casa']);

      // The sequence ends and the play button comes back.
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.byTooltip('Reproducir'), findsOneWidget);
    },
  );

  testWidgets('0.75x speed stretches the interval and survives a new load', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);
    await _translate(tester, 'hola gracias');

    await tester.ensureVisible(find.byTooltip('Reproducir'));
    await tester.pump();
    await tester.tap(find.byTooltip('Reproducir'));
    await tester.pump();

    await tester.ensureVisible(find.text('0.75x'));
    await tester.pump();
    await tester.tap(find.text('0.75x'));
    await tester.pump();

    // At 0.75x each sign lasts 1600ms: nothing advanced after 1300ms...
    await tester.pump(const Duration(milliseconds: 1300));
    expect(find.text('Secuencia 1/2'), findsOneWidget);

    // ...but the step lands once the stretched interval completes.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Secuencia 2/2'), findsOneWidget);

    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(TranslatorScreen)),
    );
    expect(container.read(sequencePlayerProvider).speed, 0.75);
  });

  testWidgets('quick phrase chip fills the input and translates', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);

    await tester.tap(find.widgetWithText(ActionChip, 'gracias'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.text('gracias'),
      ),
      findsOneWidget,
    );
    expect(find.text('Secuencia 1/1'), findsOneWidget);
    expect(find.text('GRACIAS'), findsOneWidget);
  });

  testWidgets('a phrase with out-of-vocabulary words is honest about it', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);

    // `quiero` is deliberately outside the curated vocabulary.
    await tester.tap(find.widgetWithText(ActionChip, 'quiero aprender'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Se omitieron palabras fuera de vocabulario: quiero.',
      ),
      findsOneWidget,
    );
    expect(find.text('Secuencia 1/1'), findsOneWidget);
    expect(find.text('APRENDER'), findsOneWidget);
  });
}
