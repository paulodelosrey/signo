import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart';
import 'package:signo_app/features/learn/economy.dart';
import 'package:signo_app/features/learn/learn_tree_screen.dart';
import 'package:signo_app/features/learn/lesson_screen.dart';
import 'package:signo_app/features/learn/lesson_session.dart';

import '../support/settle_with_video_card.dart';

/// U1 fills from L1 subtemas (saludos informales 4 + tonalidades 2 → one
/// merged lesson + boss). L3/L4 filler gives units 3/4 lockable lesson
/// nodes. Enough for active/locked/boss states without touching real assets.
///
/// Every sign is clip-backed, exactly as `vocabularyProvider` feeds the path
/// (`VocabIndex.videoEntries`): a clip-less fixture would render an empty tree
/// now, which is the rule working, not a broken test.
VocabEntry entry(String id, String gloss, int lesson, String subtema) =>
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[normalizeForMatch(gloss)],
      lesson: lesson,
      subtema: subtema,
      hasVideo: true,
      asset: 'assets/signs/$id.mp4',
    );

final List<VocabEntry> fixture = <VocabEntry>[
  entry('s1', 'HOLA', 1, 'Saludos informales'),
  entry('s2', 'CHAU', 1, 'Saludos informales'),
  entry('s3', 'GRACIAS', 1, 'Saludos informales'),
  entry('s4', 'ADIOS', 1, 'Saludos informales'),
  entry('s5', 'BUENOS-DIAS', 1, 'Saludos formales'),
  entry('s6', 'BUENAS-TARDES', 1, 'Saludos formales'),
  entry('s7', 'BUENAS-NOCHES', 1, 'Saludos formales'),
  entry('s8', 'TONO1', 1, 'Tonalidades'),
  entry('s9', 'TONO2', 1, 'Tonalidades'),
  entry('u1', 'SUJ1', 3, 'Sujeto'),
  entry('u2', 'SUJ2', 3, 'Sujeto'),
  entry('u3', 'SUJ3', 3, 'Sujeto'),
  entry('a1', 'ANI1', 4, 'Animales'),
  entry('a2', 'ANI2', 4, 'Animales'),
  entry('a3', 'ANI3', 4, 'Animales'),
  // Filler so option pools have 4+ candidates.
  entry('f1', 'POR-FAVOR', 1, 'Tonalidades'),
  entry('f2', 'PERDON', 1, 'Tonalidades'),
];

/// Unit 1 is deliberately ONE sign, so its node's distractor pool has to fall
/// back to the whole video-only vocabulary — the `unitSigns.length >= 4`
/// branch of `_startNode`. Everything clip-backed sits in the complete index
/// but outside every unit, so a fallback to the COMPLETE index would hand
/// `buildExercises` a pool of dead signs. Unit 3 is unlocked by pre-completing
/// U1's lesson and BOSS, so its first lesson is the active node.
final List<VocabEntry> tinyUnitFixture = <VocabEntry>[
  entry('s1', 'HOLA', 1, 'Saludos informales'),
  // Playable, but in L2 — no unit accepts lesson 2, so these are reachable
  // ONLY through the fallback pool.
  for (int i = 0; i < 8; i++)
    entry('w$i', 'WORDS${i}0', 2, 'Tipos de señas'),
  entry('a1', 'ACC1', 3, 'Acciones'),
  entry('a2', 'ACC2', 3, 'Acciones'),
  // Clip-less filler: a complete-index fallback would pull these in.
  for (int i = 0; i < 8; i++)
    VocabEntry(
      id: 'd$i',
      gloss: 'DEAD$i',
      lemmas: <String>['dead$i'],
      lesson: 4,
      subtema: 'Comida',
      hasVideo: false,
    ),
];

Future<void> pumpTree(
  WidgetTester tester, {
  Map<String, Object>? prefsOverrides,
  List<VocabEntry>? vocab,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  SharedPreferences.setMockInitialValues(<String, Object>{
    // The active node pulses forever; reduced motion keeps pumpAndSettle
    // deterministic (real users control this via the a11y toggle).
    'signo.reducedMotion': true,
    ...?prefsOverrides,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        vocabIndexProvider.overrideWith((Ref ref) async =>
            VocabIndex.build(vocab ?? fixture)),
      ],
      child: const MaterialApp(home: Scaffold(body: LearnTreeScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders HUD pills, unit cards and node states', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester);

    // HUD: streak, gems, hearts pills from the fresh state.
    expect(find.text('🔥 0'), findsOneWidget);
    expect(find.text('💎 0'), findsOneWidget);
    expect(find.text('❤️ 5'), findsOneWidget);

    // Unit header card for UNIDAD 1 with progress (2 lessons + boss).
    expect(find.text('UNIDAD 1'), findsOneWidget);
    expect(find.text('0/3'), findsOneWidget);

    // The single active node carries the start bubble.
    expect(find.text('¡COMIENZA AQUÍ!'), findsOneWidget);

    // Everything after the active node is locked: at least one lock icon.
    expect(find.byIcon(Icons.lock), findsWidgets);

    // No Repasar card without failed signs.
    expect(find.text('Repasar ahora'), findsNothing);
  });

  testWidgets('locked node tap shows a notice and never starts a lesson', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester);

    // U1's second lesson is locked and visible below the active node.
    final Finder lock = find.byIcon(Icons.lock).first;
    expect(lock, findsOneWidget);
    await tester.tap(lock);
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Completa las lecciones anteriores para desbloquear.'),
        findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing);
  });

  testWidgets('hearts gate: zero hearts blocks lesson start with notice', (
    WidgetTester tester,
  ) async {
    await pumpTree(
      tester,
      prefsOverrides: <String, Object>{
        kProgressPrefsKey:
            '{"hearts":0,"xp":10,"gems":0,"streak":1,"lastPlayedOn":"2026-09-22",'
            '"failedSignIds":[],"completedNodeIds":[],"claimedChestUnits":[],"hasPro":false}',
      },
    );

    // HUD unchanged otherwise: hearts pill shows 0 (spec hearts-gate).
    expect(find.text('❤️ 0'), findsOneWidget);

    // Tap the ACTIVE node itself (its play icon), not the bubble label.
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.byType(LessonScreen), findsNothing);
    // The notice is honest: it never promises that Repasar restores hearts
    // (it does not) and it names Premium, the only thing that lifts the gate
    // outright. Hearts themselves now refill on any completed session.
    expect(find.text(kOutOfHeartsMessage), findsOneWidget);
    expect(find.textContaining('Repaso'), findsNothing);
    expect(find.textContaining('Premium'), findsOneWidget);
    // HUD stays exactly as before the blocked attempt.
    expect(find.text('❤️ 0'), findsOneWidget);
  });

  testWidgets('active node tap starts the lesson flow', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await settleWithVideoCard(tester);

    expect(find.byType(LessonScreen), findsOneWidget);
    // First exercise is recognize (index 0): sign card prompt + word options.
    expect(find.text('¿Qué palabra significa esta seña?'),
        findsOneWidget);
    // The prompt card is a video-backed sign, so it is the clip — never the
    // gloss, which is the answer. Its loading indicator stands in for the clip
    // in tests (see settleWithVideoCard), and the curation note that used to
    // sit under it is gone entirely.
    expect(find.text('HOLA'), findsNothing);
    expect(find.text('video en curaduría'), findsNothing);
    expect(find.text('1/7'), findsOneWidget); // 7 signs in lesson 1.
  });

  testWidgets('a small unit falls back to the video-only vocabulary pool', (
    WidgetTester tester,
  ) async {
    await pumpTree(
      tester,
      vocab: tinyUnitFixture,
      prefsOverrides: <String, Object>{
        kProgressPrefsKey:
            '{"hearts":5,"xp":0,"gems":0,"streak":0,"lastPlayedOn":null,'
            '"failedSignIds":[],'
            '"completedNodeIds":["u1-l1","u1-boss"],"claimedChestUnits":[],'
            '"hasPro":false}',
      },
    );

    // The active node is U3's lesson, a 2-sign node → the wide pool is used.
    await tester.tap(find.byIcon(Icons.play_arrow).first);
    await settleWithVideoCard(tester);

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);

    // Read the session the tree actually seeded. Every entry and option must
    // be playable: the wide pool is the video-only vocabulary, so the clip-less
    // DEAD* rows that sit in the COMPLETE index are not here.
    final ProviderContainer container = ProviderScope.containerOf(
      tester.element(find.byType(LessonScreen)),
    );
    final LessonSessionState session = container.read(sessionProvider)!;
    expect(session.exercises.length, 2);
    for (final Exercise exercise in session.exercises) {
      expect(exercise.entry.isVideoBacked, isTrue);
      for (final VocabEntry option in exercise.options) {
        expect(option.isVideoBacked, isTrue, reason: option.gloss);
      }
    }
  });

  testWidgets('repasar card appears with failed signs and starts a session', (
    WidgetTester tester,
  ) async {
    await pumpTree(
      tester,
      prefsOverrides: <String, Object>{
        kProgressPrefsKey:
            '{"hearts":5,"xp":0,"gems":0,"streak":0,"lastPlayedOn":null,'
            '"failedSignIds":["s1","s2"],"completedNodeIds":[],"claimedChestUnits":[],"hasPro":false}',
      },
    );

    expect(find.text('URGENTE'), findsOneWidget);
    expect(find.text('2 señas fallidas'), findsOneWidget);

    await tester.tap(find.text('Repasar ahora'));
    await settleWithVideoCard(tester);

    expect(find.byType(LessonScreen), findsOneWidget);
    expect(find.text('1/2'), findsOneWidget);
  });
}
