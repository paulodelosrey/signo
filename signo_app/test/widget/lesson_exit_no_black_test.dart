import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/app/theme.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/settings/settings.dart';
import 'package:signo_app/features/learn/lesson_end_screen.dart';
import 'package:signo_app/features/learn/lesson_screen.dart';
import 'package:signo_app/features/learn/lesson_session.dart';

import '../support/settle_with_video_card.dart';

/// Regression test for the BLACK SCREEN after leaving a lesson.
///
/// Leaving a lesson calls `sessionProvider.dismiss()` and then pops. The
/// dismissal clears the provider, which sends the SAME screen down its own
/// "session dropped underneath us" branch, scheduling a second pop. Two pops
/// tear down the route below as well, so the Navigator ends up empty: the app
/// is alive, there is no Dart exception, and the user stares at a black screen
/// until they force-stop. Reproduced on a real device both when exiting
/// mid-lesson and after "Continuar" on the lesson-end screen.
///
/// The rule these tests pin: a lesson route pops EXACTLY ONCE, so the route it
/// was pushed on top of survives.
///
/// The signs are clip-backed because `buildExercises` (GATE B) drops clip-less
/// ones — a clip-less fixture would start an empty session and there would be
/// no lesson to exit. That also means the lesson's sign card is a video player,
/// whose loading indicator never settles in tests; see [settleWithVideoCard].
const List<VocabEntry> kSessionVocab = <VocabEntry>[
  VocabEntry(
    id: 'l-1',
    gloss: 'HOLA',
    lemmas: <String>['hola'],
    lesson: 1,
    subtema: 'Saludos',
    hasVideo: true,
    asset: 'assets/signs/l-1.mp4',
  ),
  VocabEntry(
    id: 'l-2',
    gloss: 'GRACIAS',
    lemmas: <String>['gracias'],
    lesson: 1,
    subtema: 'Saludos',
    hasVideo: true,
    asset: 'assets/signs/l-2.mp4',
  ),
];

/// The page the lesson is pushed on top of — the stand-in for the app shell.
Future<ProviderContainer> _pumpLessonOverHome(
  WidgetTester tester,
) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'signo.onboardingSeen': true,
    'signo.reducedMotion': true,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildKineticTheme(),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  container.read(sessionProvider.notifier).start(
                        <VocabEntry>[kSessionVocab.first],
                        distractorPool: kSessionVocab,
                      );
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) => const LessonScreen(),
                    ),
                  );
                },
                child: const Text('Abrir lección'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('exiting mid-lesson leaves the page underneath alive', (
    WidgetTester tester,
  ) async {
    await _pumpLessonOverHome(tester);

    await tester.tap(find.text('Abrir lección'));
    await settleWithVideoCard(tester);
    expect(find.byType(LessonScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Salir de la lección'));
    await settleWithVideoCard(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Salir'));
    await settleWithVideoCard(tester);

    // The route below is still on screen — no black.
    expect(find.byType(LessonScreen), findsNothing);
    expect(find.text('Abrir lección'), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
  });

  testWidgets('"Continuar" on the lesson-end screen pops exactly once', (
    WidgetTester tester,
  ) async {
    final ProviderContainer container =
        await _pumpLessonOverHome(tester);

    await tester.tap(find.text('Abrir lección'));
    await settleWithVideoCard(tester);

    // Answer the single exercise and finish the session.
    container.read(sessionProvider.notifier).answer(0);
    await tester.pump();
    container.read(sessionProvider.notifier).advance();
    await settleWithVideoCard(tester);

    expect(find.byType(LessonEndScreen), findsOneWidget);
    expect(find.text('Abrir lección'), findsNothing); // replaced the lesson

    await tester.tap(find.text('Continuar'));
    await settleWithVideoCard(tester);

    expect(find.byType(LessonEndScreen), findsNothing);
    expect(find.text('Abrir lección'), findsOneWidget);
    expect(find.byType(Navigator), findsOneWidget);
  });
}
