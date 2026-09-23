import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/features/dictionary/dictionary_screen.dart';
import 'package:signo_app/features/dictionary/sign_detail_screen.dart';
import 'package:signo_app/features/learn/lesson_screen.dart' show SignView;

/// In-memory dictionary fixture: enough signs to check browse-all, filtering
/// (including accents) and detail navigation without touching real assets
/// (rootBundle inside repeated testWidgets FakeAsync zones is flaky).
VocabEntry entry(
  String id,
  String gloss,
  List<String> lemmas,
  int lesson,
  String subtema,
) =>
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: lemmas,
      lesson: lesson,
      subtema: subtema,
      hasVideo: false,
    );

final List<VocabEntry> fixture = <VocabEntry>[
  entry('d1', 'HOLA', <String>['hola'], 1, 'Saludos informales'),
  entry('d2', 'CAFÉ', <String>['café', 'coffee'], 4, 'Comida'),
  entry('d3', 'CASA', <String>['casa'], 3, 'Lugar'),
  entry('d4', 'CHAU', <String>['chau', 'adiós'], 1, 'Despedidas'),
];

Future<void> pumpDictionary(WidgetTester tester) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vocabIndexProvider.overrideWith(
          (Ref ref) async => VocabIndex.build(fixture),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: DictionaryScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('browse-all: lists every sign with a count when query is empty',
      (WidgetTester tester) async {
    await pumpDictionary(tester);

    expect(find.text('Diccionario'), findsOneWidget);
    expect(find.text('4 señas'), findsOneWidget);
    expect(find.text('HOLA'), findsOneWidget);
    expect(find.text('CAFÉ'), findsOneWidget);
    expect(find.text('CASA'), findsOneWidget);
    expect(find.text('CHAU'), findsOneWidget);
  });

  testWidgets('filters results ignoring case and accents', (
    WidgetTester tester,
  ) async {
    await pumpDictionary(tester);

    // `cafe` (plain ASCII) must find the CAFÉ entry.
    await tester.enterText(find.byType(TextField), 'cafe');
    await tester.pumpAndSettle();

    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('CAFÉ'), findsOneWidget);
    expect(find.text('HOLA'), findsNothing);
    expect(find.text('CASA'), findsNothing);
  });

  testWidgets('shows an empty state when nothing matches', (
    WidgetTester tester,
  ) async {
    await pumpDictionary(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados para "zzz"'), findsOneWidget);
    expect(find.text('0 resultados'), findsOneWidget);
  });

  testWidgets('opening a result shows the detail with the SignView T4 seam', (
    WidgetTester tester,
  ) async {
    await pumpDictionary(tester);

    await tester.tap(find.text('HOLA'));
    await tester.pumpAndSettle();

    expect(find.byType(SignDetailScreen), findsOneWidget);
    // Detail reuses the M3 text-mode SignView — same single video seam.
    expect(find.byType(SignView), findsOneWidget);
    expect(find.text('video en curaduría'), findsOneWidget);
    // Lemma chips + unit/subtema metadata.
    expect(
      find.descendant(
        of: find.byType(SignDetailScreen),
        matching: find.text('hola'),
      ),
      findsOneWidget,
    );
    expect(find.text('Unidad 1 · Saludos informales'), findsOneWidget);
  });

  testWidgets('keeps 48px minimum touch targets on rows and search field', (
    WidgetTester tester,
  ) async {
    await pumpDictionary(tester);

    final Size rowSize = tester.getSize(
      find.widgetWithText(InkWell, 'HOLA'),
    );
    expect(rowSize.height, greaterThanOrEqualTo(48));

    final Size fieldSize = tester.getSize(find.byType(TextField));
    expect(fieldSize.height, greaterThanOrEqualTo(48));
  });
}
