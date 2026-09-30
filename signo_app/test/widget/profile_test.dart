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

import '../support/settle_with_video_card.dart';

/// In-memory vocab fixture so the Repasar entry can resolve failed signs and
/// start the shared session without touching real assets (rootBundle inside
/// repeated testWidgets FakeAsync zones is flaky).
///
/// Every sign is clip-backed: `startRepasarSession` resolves the failed ids
/// against `VocabIndex.videoEntries`, so a clip-less fixture would resolve
/// nothing and the Repasar card would (correctly) never start a session.
final List<VocabEntry> fixture = <VocabEntry>[
  for (final (String id, String gloss, String subtema) in <(String, String, String)>[
    ('s1', 'HOLA', 'Saludos informales'),
    ('s2', 'CHAU', 'Despedidas'),
    ('s3', 'GRACIAS', 'Saludos informales'),
    ('s4', 'ADIOS', 'Despedidas'),
  ])
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[normalizeForMatch(gloss)],
      lesson: 1,
      subtema: subtema,
      hasVideo: true,
      asset: 'assets/signs/$id.mp4',
    ),
];

/// A sign the app cannot play, persisted as a failed id.
const VocabEntry kClipLessEntry = VocabEntry(
  id: 'dead-1',
  gloss: 'FANTASMA',
  lemmas: <String>['fantasma'],
  lesson: 1,
  subtema: 'Saludos informales',
  hasVideo: false,
);

final List<VocabEntry> clipLessFixture = <VocabEntry>[kClipLessEntry];
final List<VocabEntry> mixedFixture = <VocabEntry>[...fixture, kClipLessEntry];

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
  List<VocabEntry>? vocab,
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
          (Ref ref) async => VocabIndex.build(vocab ?? fixture),
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
    await settleWithVideoCard(tester);

    // Same semantics as the Aprender tree card: repasar session of 2.
    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
  });

  group('video-only gate on the persisted failed list', () {
    testWidgets('a clip-less failed id starts no session', (
      WidgetTester tester,
    ) async {
      // `dead-1` is in the vocabulary but ships no clip. `failedSignIds` is
      // PERSISTED state, so it can still hold ids from before the video-only
      // path — resolving one into an exercise would show a card that can never
      // play. There is nothing to review, so the card must not be offered at
      // all: a visible "Repasar ahora" that opens nothing is a dead button.
      await pumpProfile(
        tester,
        vocab: clipLessFixture,
        prefsOverrides: <String, Object>{
          kProgressPrefsKey:
              progressBlob(failedSignIds: <String>['dead-1']),
        },
      );

      expect(find.text('URGENTE'), findsNothing);
      expect(find.text('Repasar ahora'), findsNothing);
      expect(find.textContaining('seña fallida'), findsNothing);
      expect(find.byType(LessonScreen), findsNothing);
    });

    testWidgets('a mixed failed list reviews only the playable sign', (
      WidgetTester tester,
    ) async {
      await pumpProfile(
        tester,
        vocab: mixedFixture,
        prefsOverrides: <String, Object>{
          kProgressPrefsKey: progressBlob(
            failedSignIds: <String>['s1', 'dead-1'],
          ),
        },
      );

      // The card counts what the session can actually deliver, not the raw
      // persisted list: one of these two ids is clip-less, so promising two
      // would open a one-sign session.
      expect(find.text('1 seña fallida'), findsOneWidget);
      expect(find.text('2 señas fallidas'), findsNothing);

      await tester.tap(find.text('Repasar ahora'));
      await settleWithVideoCard(tester);

      // The session runs a single exercise: the dead sign was dropped, the
      // playable one survived. The number on the card matched it.
      expect(find.byType(LessonScreen), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);
    });
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
