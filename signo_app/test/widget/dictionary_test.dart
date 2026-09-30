import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/features/dictionary/dictionary_screen.dart';
import 'package:signo_app/features/dictionary/sign_detail_screen.dart';
import 'package:signo_app/features/learn/lesson_screen.dart' show SignView;

import '../support/settle_with_video_card.dart';

/// In-memory dictionary fixture: enough signs to check browse-all, filtering
/// (including accents) and detail navigation without touching real assets
/// (rootBundle inside repeated testWidgets FakeAsync zones is flaky).
///
/// Every sign is deliberately CLIP-LESS, and that is the point: the dictionary
/// is the one surface the video-only rule does not touch, so its whole job is
/// to render signs the app cannot yet play. Keeping the fixture clip-less is
/// what makes the text-mode assertions below meaningful.
/// Pass [asset] to build a clip-backed entry; omit it (the default) for a
/// clip-less one.
VocabEntry entry(
  String id,
  String gloss,
  List<String> lemmas,
  int lesson,
  String subtema, {
  String? asset,
}) =>
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: lemmas,
      lesson: lesson,
      subtema: subtema,
      hasVideo: asset != null,
      asset: asset,
    );

final List<VocabEntry> fixture = <VocabEntry>[
  entry('d1', 'HOLA', <String>['hola'], 1, 'Saludos informales'),
  entry('d2', 'CAFÉ', <String>['café', 'coffee'], 4, 'Comida'),
  entry('d3', 'CASA', <String>['casa'], 3, 'Lugar'),
  entry('d4', 'CHAU', <String>['chau', 'adiós'], 1, 'Despedidas'),
];

/// Second fixture with MIXED coverage: only 59 of the 201 real signs carry a
/// clip, so any honest dictionary test needs both kinds side by side. The clip
/// assets are fake on purpose — no video actually decodes here, and the badge /
/// note assertions only depend on [VocabEntry.isVideoBacked].
final List<VocabEntry> mixedFixture = <VocabEntry>[
  entry('m1', 'HOLA', <String>['hola'], 1, 'Saludos informales',
      asset: 'assets/clips/hola.mp4'),
  entry('m2', 'CASA', <String>['casa'], 3, 'Lugar'),
  entry('m3', 'PERRO', <String>['perro'], 2, 'Animales',
      asset: 'assets/clips/perro.mp4'),
  entry('m4', 'LIBRO', <String>['libro'], 5, 'Objetos'),
];

Future<void> pumpDictionary(WidgetTester tester) async {
  await _pumpDictionaryWith(tester, fixture);
}

Future<void> pumpMixedDictionary(WidgetTester tester) async {
  await _pumpDictionaryWith(tester, mixedFixture);
}

Future<void> _pumpDictionaryWith(
  WidgetTester tester,
  List<VocabEntry> entries,
) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        vocabIndexProvider.overrideWith(
          (Ref ref) async => VocabIndex.build(entries),
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
    // All four fixture signs are clip-less, so the coverage line honestly
    // reports zero videos rather than pretending the dictionary is complete.
    expect(find.text('4 señas · 0 con video'), findsOneWidget);
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

    expect(find.text('1 resultado de 4 señas · 0 con video'), findsOneWidget);
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
    expect(find.text('0 resultados de 4 señas · 0 con video'), findsOneWidget);
  });

  testWidgets('opening a result shows the detail with the SignView T4 seam', (
    WidgetTester tester,
  ) async {
    await pumpDictionary(tester);

    await tester.tap(find.text('HOLA'));
    await tester.pumpAndSettle();

    expect(find.byType(SignDetailScreen), findsOneWidget);
    // Detail reuses the M3 SignView — the same single video seam. This entry is
    // clip-less, so it renders the text-mode card: sign glyph plus the gloss.
    expect(find.byType(SignView), findsOneWidget);
    // Scoped to the card: the browse list behind still shows its own HOLA row.
    expect(
      find.descendant(of: find.byType(SignView), matching: find.text('HOLA')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.sign_language), findsWidgets);
    // DELIBERATE REVERSAL of an earlier rule. This assertion used to require the
    // "no video en curaduría" wording to be absent, on the grounds that the
    // dictionary owes the user no apology about the library. That was wrong for
    // a clip-LESS entry: the user is one tap away from pressing play, and
    // nothing would happen with no explanation. The dictionary is now the ONE
    // surface allowed to state the missing clip, and only when
    // `isVideoBacked` is false — every teaching surface (learning path,
    // exercises, Repasar, Práctica, translator) keeps the old rule and stays
    // curation-box free because it only ever shows clip-backed signs.
    expect(find.text('Vídeo no disponible por ahora'), findsOneWidget);
    // Second line: the reason is production, not a bug and not an apology.
    // Quiet, one sentence, no promise about a date the team cannot keep.
    expect(find.text('Estamos produciendo los vídeos restantes.'),
        findsOneWidget);
    expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
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

  testWidgets('play badge appears only on clip-backed rows', (
    WidgetTester tester,
  ) async {
    await pumpMixedDictionary(tester);

    // HOLA and PERRO have a clip; CASA and LIBRO do not.
    Finder badgeIn(String gloss) => find.descendant(
          of: find.widgetWithText(InkWell, gloss),
          matching: find.byIcon(Icons.play_circle_fill),
        );

    expect(badgeIn('HOLA'), findsOneWidget);
    expect(badgeIn('PERRO'), findsOneWidget);
    expect(badgeIn('CASA'), findsNothing);
    expect(badgeIn('LIBRO'), findsNothing);
    expect(find.byIcon(Icons.play_circle_fill), findsNWidgets(2));
  });

  testWidgets('missing-clip note appears only on clip-less details', (
    WidgetTester tester,
  ) async {
    const String note = 'Vídeo no disponible por ahora';
    const String productionNote = 'Estamos produciendo los vídeos restantes.';

    await pumpMixedDictionary(tester);

    await tester.tap(find.text('CASA'));
    await tester.pumpAndSettle();

    // Clip-less: the honest lines are there, inside the detail screen.
    expect(
      find.descendant(
        of: find.byType(SignDetailScreen),
        matching: find.text(note),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SignDetailScreen),
        matching: find.text(productionNote),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(SignDetailScreen),
        matching: find.byIcon(Icons.videocam_off_outlined),
      ),
      findsOneWidget,
    );

    // Clip-backed: nothing is claimed, because a note there would be a lie.
    // Bounded pumps, not pumpAndSettle: this detail mounts a SignVideoPlayer
    // whose loading indicator never ends in the test environment.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('HOLA'));
    await settleWithVideoCard(tester);

    expect(find.byType(SignDetailScreen), findsOneWidget);
    expect(find.text(note), findsNothing);
    expect(find.text(productionNote), findsNothing);
    expect(find.byIcon(Icons.videocam_off_outlined), findsNothing);
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
