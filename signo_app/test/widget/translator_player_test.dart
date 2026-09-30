import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart';
import 'package:signo_app/core/tts/tts_service.dart';
import 'package:signo_app/features/learn/lesson_screen.dart';
import 'package:signo_app/features/translator/player_controller.dart';
import 'package:signo_app/features/translator/translator_screen.dart';

import '../support/settle_with_video_card.dart';

/// In-memory content fixture — loading real assets through rootBundle
/// inside repeated `testWidgets` FakeAsync zones is flaky (M3 lesson), so
/// the pipeline is injected instead; real assets stay covered by
/// vocab_assets_test.
///
/// Every sign is clip-backed. That is now MANDATORY, not cosmetic:
/// `translatorServiceProvider` hands the matcher `index.copyWithVideoOnly()`,
/// so a clip-less fixture would turn EVERY word in this file into an
/// out-of-vocabulary omission and there would be no sequence to play.
const String _fixtureJson = '''
{
  "source": "test fixture",
  "count": 6,
  "signs": [
    {"id": "l1-001", "gloss": "HOLA", "lemmas": ["hola"], "lesson": 1, "subtema": "Saludos informales", "asset": "assets/signs/hola.mp4", "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true},
    {"id": "l1-002", "gloss": "GRACIAS", "lemmas": ["gracias"], "lesson": 1, "subtema": "Frases comunes", "asset": "assets/signs/gracias.mp4", "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true},
    {"id": "l1-003", "gloss": "CASA", "lemmas": ["casa"], "lesson": 3, "subtema": "Lugar", "asset": "assets/signs/casa.mp4", "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true},
    {"id": "l1-004", "gloss": "AYUDA", "lemmas": ["ayuda"], "lesson": 1, "subtema": "Frases comunes", "asset": "assets/signs/ayuda.mp4", "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true},
    {"id": "l1-005", "gloss": "CHAUV", "lemmas": ["chau"], "lesson": 1, "subtema": "Despedida", "asset": "assets/signs/chau.mp4", "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true},
    {"id": "l3-001", "gloss": "APRENDER", "lemmas": ["aprender"], "lesson": 3, "subtema": "Acciones", "asset": "assets/signs/aprender.mp4", "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true}
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

/// The gloss of the sign the sequence player is currently showing.
///
/// Asserted on the [SignView] widget rather than on rendered text: a
/// video-backed entry renders the player (never the text-mode card), so the
/// gloss is inside the clip and never painted in a test. Reading it off the
/// widget is both possible and stricter — it proves the card is bound to the
/// right entry, not merely that some text exists nearby.
String _currentSignGloss(WidgetTester tester) =>
    tester.widget<SignView>(find.byType(SignView).last).entry.gloss;

Future<void> _translate(WidgetTester tester, String sentence) async {
  await tester.enterText(find.byType(TextField), sentence);
  await tester.tap(find.text('Traducir'));
  // NOT pumpAndSettle: a translated sign is a video-backed entry, so the
  // player card's loading indicator animates forever in tests.
  await settleWithVideoCard(tester);
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
    // The six seeded quick phrases, in order. Every one of them is a COMPLETE
    // translation: no out-of-vocabulary word and no clip-less sign (proved
    // against the real assets in quick_phrases_assets_test.dart).
    expect(kQuickPhrases.map((QuickPhrase p) => p.phrase), <String>[
      'hola',
      'buenas tardes',
      'gracias',
      '¿cómo estás?',
      'por favor',
      'perdón, por favor',
    ]);
    for (final QuickPhrase phrase in kQuickPhrases) {
      expect(find.text(phrase.phrase), findsOneWidget);
    }
    // The curation note is GONE: the translator drops what it cannot show and
    // the omission notice says so, so a standing "the library keeps growing"
    // note would only contradict what the user is told on each translation.
    expect(find.text('sigue creciendo'), findsNothing);
    expect(find.text('Secuencia 1/1'), findsNothing);
  });

  testWidgets('scripted sentence produces the sequence player', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);
    await _translate(tester, 'hola casa');

    expect(find.text('Secuencia 1/2'), findsOneWidget);
    // The fixture entries ship a clip, so the card is the video player — whose
    // loading indicator stands in for the clip in tests. What matters here is
    // that no text-mode placeholder is ever rendered: no gloss, no curation.
    expect(find.text('HOLA'), findsNothing);
    expect(find.text('video en curaduría'), findsNothing);
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
    expect(_currentSignGloss(tester), 'HOLA');
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
    await settleWithVideoCard(tester);

    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.text('gracias'),
      ),
      findsOneWidget,
    );
    expect(find.text('Secuencia 1/1'), findsOneWidget);
    expect(_currentSignGloss(tester), 'GRACIAS');
  });

  testWidgets('a phrase with out-of-vocabulary words is honest about it', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);

    // The seeded chips no longer carry this case: every one of them is a
    // complete translation. The honest notice still has to work when a user
    // TYPES a phrase with words outside the curated vocabulary, so the
    // behaviour is asserted here on typed input instead of on a chip.
    await _translate(tester, 'zorro aprender');

    expect(
      find.text(
        'Se omitieron palabras fuera de vocabulario: zorro.',
      ),
      findsOneWidget,
    );
    expect(find.text('Secuencia 1/1'), findsOneWidget);
    expect(_currentSignGloss(tester), 'APRENDER');
  });

  testWidgets('next advances immediately, paused, and wraps at the end', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);
    await _translate(tester, 'hola gracias casa');

    await tester.ensureVisible(find.byTooltip('Seña siguiente'));
    await tester.pump();

    // Nothing is playing yet: the tap must still move the sequence, which is
    // exactly what was impossible before the control existed.
    expect(find.byTooltip('Reproducir'), findsOneWidget);
    await tester.tap(find.byTooltip('Seña siguiente'));
    await tester.pump();
    expect(find.text('Secuencia 2/3'), findsOneWidget);

    await tester.tap(find.byTooltip('Seña siguiente'));
    await tester.pump();
    expect(find.text('Secuencia 3/3'), findsOneWidget);

    // Forward from the last sign restarts instead of dead-ending.
    await tester.tap(find.byTooltip('Seña siguiente'));
    await tester.pump();
    expect(find.text('Secuencia 1/3'), findsOneWidget);

    // Paused browsing never starts playback on its own.
    expect(find.byTooltip('Reproducir'), findsOneWidget);
    expect(tts.spoken, isEmpty);
  });

  testWidgets('previous walks back and wraps from the first sign', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);
    await _translate(tester, 'hola gracias casa');

    await tester.ensureVisible(find.byTooltip('Seña anterior'));
    await tester.pump();

    await tester.tap(find.byTooltip('Seña anterior'));
    await tester.pump();
    expect(find.text('Secuencia 3/3'), findsOneWidget);

    await tester.tap(find.byTooltip('Seña anterior'));
    await tester.pump();
    expect(find.text('Secuencia 2/3'), findsOneWidget);
  });

  testWidgets('the play/pause icon reflects real playback state', (
    WidgetTester tester,
  ) async {
    await _pumpTranslator(tester, tts);
    await _translate(tester, 'hola gracias');

    // Paused: the card shows the play affordance.
    expect(find.byTooltip('Reproducir'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle), findsNothing);

    // The SignView must follow the state too, otherwise the icon lies the same
    // way the old always-autoplay clip did.
    final SignView view =
        tester.widget<SignView>(find.byType(SignView).last);
    expect(view.autoplay, isFalse);

    await tester.ensureVisible(find.byTooltip('Reproducir'));
    await tester.pump();
    await tester.tap(find.byTooltip('Reproducir'));
    await tester.pump(); // no pumpAndSettle: the autoplay timer never settles.

    expect(find.byTooltip('Pausar'), findsOneWidget);
    expect(
      tester.widget<SignView>(find.byType(SignView).last).autoplay,
      isTrue,
    );

    await tester.tap(find.byTooltip('Pausar'));
    await tester.pump();
    expect(
      tester.widget<SignView>(find.byType(SignView).last).autoplay,
      isFalse,
    );
  });
}
