import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart';
import 'package:signo_app/features/learn/economy.dart';
import 'package:signo_app/features/learn/lesson_screen.dart';
import 'package:signo_app/features/profile/profile_screen.dart';

/// In-memory vocab fixture so the Repasar entry can resolve failed signs and
/// start the shared session without touching real assets (rootBundle inside
/// repeated testWidgets FakeAsync zones is flaky).
final List<VocabEntry> fixture = <VocabEntry>[
  VocabEntry(
    id: 's1',
    gloss: 'HOLA',
    lemmas: <String>['hola'],
    lesson: 1,
    subtema: 'Saludos informales',
    hasVideo: false,
  ),
  VocabEntry(
    id: 's2',
    gloss: 'CHAU',
    lemmas: <String>['chau'],
    lesson: 1,
    subtema: 'Despedidas',
    hasVideo: false,
  ),
  VocabEntry(
    id: 's3',
    gloss: 'GRACIAS',
    lemmas: <String>['gracias'],
    lesson: 1,
    subtema: 'Saludos informales',
    hasVideo: false,
  ),
  VocabEntry(
    id: 's4',
    gloss: 'ADIOS',
    lemmas: <String>['adios'],
    lesson: 1,
    subtema: 'Despedidas',
    hasVideo: false,
  ),
];

String progressBlob({
  int hearts = 5,
  int xp = 0,
  int gems = 0,
  int streak = 0,
  List<String> failedSignIds = const <String>[],
  bool hasPro = false,
}) =>
    '{"hearts":$hearts,"xp":$xp,"gems":$gems,"streak":$streak,'
    '"lastPlayedOn":null,'
    '"failedSignIds":[${failedSignIds.map((String s) => '"$s"').join(',')}],'
    '"completedNodeIds":[],"claimedChestUnits":[],"hasPro":$hasPro}';

late SharedPreferences prefs;

Future<void> pumpProfile(
  WidgetTester tester, {
  Map<String, Object>? prefsOverrides,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues(<String, Object>{
    'signo.reducedMotion': true,
    ...?prefsOverrides,
  });
  prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        vocabIndexProvider.overrideWith(
          (Ref ref) async => VocabIndex.build(fixture),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('renders learning stats from the progress store', (
    WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      prefsOverrides: <String, Object>{
        kProgressPrefsKey: progressBlob(
          hearts: 3,
          xp: 125,
          gems: 50,
          streak: 4,
        ),
      },
    );

    // Streak / gems / XP / hearts tiles mirror the Aprender HUD values.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('125'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Racha'), findsOneWidget);
    expect(find.text('Gemas'), findsOneWidget);
    expect(find.text('XP'), findsOneWidget);
    expect(find.text('Corazones'), findsOneWidget);
    // No PRO badge and no infinity on a free profile.
    expect(find.text('PRO'), findsNothing);
    expect(find.text('∞'), findsNothing);
  });

  testWidgets('PRO profile shows infinite hearts with a PRO badge', (
    WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      prefsOverrides: <String, Object>{
        kProgressPrefsKey: progressBlob(hasPro: true),
      },
    );

    expect(find.text('∞'), findsOneWidget);
    expect(find.text('PRO'), findsOneWidget);
  });

  testWidgets('no Repasar entry without failed signs', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    expect(find.text('Repasar ahora'), findsNothing);
    expect(find.text('URGENTE'), findsNothing);
  });

  testWidgets(
      'Repasar entry starts the shared session over the failed signs', (
    WidgetTester tester,
  ) async {
    await pumpProfile(
      tester,
      prefsOverrides: <String, Object>{
        kProgressPrefsKey:
            progressBlob(failedSignIds: <String>['s1', 's2']),
      },
    );

    expect(find.text('URGENTE'), findsOneWidget);
    expect(find.text('2 señas fallidas'), findsOneWidget);

    await tester.tap(find.text('Repasar ahora'));
    await tester.pumpAndSettle();

    // Same semantics as the Aprender tree card: repasar session of 2.
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
  });

  testWidgets('large text toggle persists through the settings repository', (
    WidgetTester tester,
  ) async {
    await pumpProfile(tester);

    expect(prefs.getBool('signo.largeText'), isNull);

    // The a11y section sits below the fold of the lazy ListView.
    await tester.scrollUntilVisible(
      find.text('Texto grande'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.widgetWithText(SwitchListTile, 'Texto grande'));
    await tester.pumpAndSettle();

    expect(prefs.getBool('signo.largeText'), isTrue);
    expect(
      find.widgetWithText(SwitchListTile, 'Texto grande'),
      findsOneWidget,
    );
  });
}
