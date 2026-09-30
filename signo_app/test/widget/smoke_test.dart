import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/app/router.dart';
import 'package:signo_app/app/shell.dart';
import 'package:signo_app/app/theme.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/revenuecat/billing.dart';
import 'package:signo_app/core/settings/settings.dart';
import 'package:signo_app/features/dictionary/dictionary_screen.dart';
import 'package:signo_app/widgets/kinetic_button.dart';

import '../support/settle_with_video_card.dart';

/// Minimal in-memory content: smoke tests exercise the shell and theming,
/// NOT the asset pipeline (real assets are covered by vocab_assets_test).
/// Loading real assets through rootBundle inside repeated `testWidgets`
/// FakeAsync zones is flaky (the second test's asset future may never
/// complete), so content is injected instead.
///
/// Both signs are clip-backed, and that is now load-bearing rather than
/// cosmetic: the translator resolves against `index.copyWithVideoOnly()`, so
/// a clip-less fixture would turn the `hola` quick phrase into an
/// out-of-vocabulary omission and the shell walk would lose its player card.
final List<VocabEntry> kSmokeVocab = <VocabEntry>[
  for (final (String id, String gloss, String subtema)
      in <(String, String, String)>[
    ('smoke-1', 'HOLA', 'Saludos informales'),
    ('smoke-2', 'CHAU', 'Despedida'),
  ])
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[gloss.toLowerCase()],
      lesson: 1,
      subtema: subtema,
      hasVideo: true,
      asset: 'assets/signs/$id.mp4',
    ),
];

const GrammarRuleSet kSmokeGrammar = GrammarRuleSet(
  provenanceNote: 'smoke fixture',
  categories: <String, Set<String>>{},
  rules: <GrammarRule>[],
);

/// The colored face of a [KineticButton] (its inner animated container).
Finder _kineticFaceFinder(Color faceColor) => find.byWidgetPredicate(
      (Widget w) =>
          w is AnimatedContainer &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == faceColor,
    );

/// The T13 nav contract: Bingo is a hidden tab, so its label must never be a
/// navigation destination — and, since the dead "Próximamente" cards were
/// removed from the Práctica hub, the label is now absent from the whole
/// shell too. The rail-scoped check is kept because it is the invariant that
/// actually matters: no Bingo DESTINATION is reachable.
void _expectNoBingoInNavRail() {
  expect(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Bingo'),
    ),
    findsNothing,
  );
}

/// No unimplemented "Próximamente" card survives anywhere in the shell. A
/// tab offering two promises the code cannot honour reads as unfinished scope.
void _expectNoComingSoonCards() {
  expect(find.text('Próximamente'), findsNothing);
  expect(find.text('Simón'), findsNothing);
}

Future<void> pumpApp(
  WidgetTester tester, {
  required bool onboardingSeen,
  Map<String, Object>? prefsOverrides,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'signo.onboardingSeen': onboardingSeen,
    // The learning path's active node pulses forever (repeat animation);
    // reduced motion keeps pumpAndSettle deterministic in widget tests.
    'signo.reducedMotion': true,
    ...?prefsOverrides,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        vocabIndexProvider.overrideWith(
          (Ref ref) async => VocabIndex.build(kSmokeVocab),
        ),
        grammarRuleSetProvider.overrideWith(
          (Ref ref) async => kSmokeGrammar,
        ),
      ],
      child: const SignoApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // Keep widget tests offline, exactly like the app runtime.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('first launch shows the onboarding gate, not the shell', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, onboardingSeen: false);

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Empezar a aprender'), findsNothing);
    expect(find.text('Aprende Lengua de Señas Colombiana'), findsOneWidget);
  });

  testWidgets(
    'shell renders the 4 visible tabs with Kinetic theming and hides Bingo',
    (WidgetTester tester) async {
      await pumpApp(tester, onboardingSeen: true);

      final Finder navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);

      // 4 visible destinations, in order: Aprender, Práctica, Traductor,
      // Premium. Bingo is a hidden tab per spec and its dead Práctica card is
      // gone, so the label must be absent everywhere in the tree.
      expect(
        find.descendant(of: navBar, matching: find.text('Aprender')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Práctica')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Traductor')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: navBar, matching: find.text('Premium')),
        findsOneWidget,
      );
      expect(find.text('Bingo'), findsNothing);
      _expectNoComingSoonCards();

      // Kinetic theme applied to the navigation bar and color scheme.
      final BuildContext navContext = tester.element(navBar);
      final NavigationBarThemeData navTheme =
          Theme.of(navContext).navigationBarTheme;
      expect(navTheme.backgroundColor, KineticColors.surfaceContainerMid);
      expect(
        Theme.of(navContext).colorScheme.primary,
        KineticColors.mint,
      );
    },
  );

  testWidgets('tapping a destination swaps the IndexedStack page', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, onboardingSeen: true);

    await tester.tap(find.text('Traductor'));
    await tester.pumpAndSettle();

    // M4: the Traductor tab now hosts the offline translator (input +
    // quick phrases + translate button) instead of the M1 placeholder.
    expect(find.text('Traducir'), findsOneWidget);
    expect(find.text('gracias'), findsOneWidget);
    expect(find.text('por favor'), findsOneWidget);
    expect(find.byType(SignoShell), findsOneWidget);
  });

  testWidgets('dictionary opens from the Aprender tab app-bar action', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester, onboardingSeen: true);

    // The action lives on the Aprender tab only; the injected smoke vocab
    // has 2 signs, both clip-backed, so the coverage line reads
    // '2 señas · 2 con video'.
    await tester.tap(find.byIcon(Icons.menu_book_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(DictionaryScreen), findsOneWidget);
    expect(find.text('2 señas · 2 con video'), findsOneWidget);
    expect(find.text('HOLA'), findsOneWidget);
  });

  testWidgets('large text a11y toggle scales app text through the router', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      onboardingSeen: true,
      prefsOverrides: <String, Object>{'signo.largeText': true},
    );

    // The router builder overrides the textScaler app-wide (spec a11y
    // font-scaling): a 10sp style renders at 13sp. `.first` — the label also
    // exists on the navigation bar.
    final double scale =
        MediaQuery.textScalerOf(tester.element(find.text('Aprender').first))
            .scale(10);
    expect(scale, 13.0);
  });

  testWidgets(
    'T13 smoke: onboarding gate leads to themed tabs with Bingo hidden',
    (WidgetTester tester) async {
      // -- First launch: static onboarding gate, Kinetic themed.
      await pumpApp(tester, onboardingSeen: false);

      expect(find.text('Aprende Lengua de Señas Colombiana'), findsOneWidget);
      final BuildContext scaffoldContext =
          tester.element(find.byType(Scaffold).first);
      expect(
        Theme.of(scaffoldContext).scaffoldBackgroundColor,
        KineticColors.background,
      );
      expect(find.byType(KineticButton), findsOneWidget);
      // Scoped: the active onboarding page-dot is a mint AnimatedContainer
      // too, so the button face is matched inside the KineticButton subtree.
      expect(
        find.descendant(
          of: find.byType(KineticButton),
          matching: _kineticFaceFinder(KineticColors.mint),
        ),
        findsOneWidget,
      );

      // Drive the REAL gate path: 'Saltar' completes onboarding (write-through
      // to prefs) and the router swaps to the shell (reduced motion ⇒ a
      // zero-duration switch).
      await tester.tap(find.text('Saltar'));
      await tester.pumpAndSettle();

      // -- 5-tab contract: 4 visible destinations + Bingo hidden.
      final Finder navBar = find.byType(NavigationBar);
      expect(navBar, findsOneWidget);
      expect(
        find.descendant(
          of: navBar,
          matching: find.byType(NavigationDestination),
        ),
        findsNWidgets(4),
      );
      for (final String label in const <String>[
        'Aprender',
        'Práctica',
        'Traductor',
        'Premium',
      ]) {
        expect(
          find.descendant(of: navBar, matching: find.text(label)),
          findsOneWidget,
        );
      }
      // On the Aprender tab 'Bingo' is absent from the whole shell; the
      // nav-rail absence is re-checked on every visited tab below.
      expect(find.text('Bingo'), findsNothing);
      _expectNoComingSoonCards();

      // -- Kinetic tokens behind every tab: mint/iris/amber scheme on the
      // dark background ladder.
      final BuildContext navContext = tester.element(navBar);
      expect(Theme.of(navContext).colorScheme.primary, KineticColors.mint);
      expect(Theme.of(navContext).colorScheme.secondary, KineticColors.iris);
      expect(Theme.of(navContext).colorScheme.tertiary, KineticColors.amber);
      expect(
        Theme.of(navContext).scaffoldBackgroundColor,
        KineticColors.background,
      );
      // Space Grotesk carries the headline (scoped to the AppBar — the label
      // also lives in the navigation bar).
      final Finder appBarTitle = find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Aprender'),
      );
      expect(appBarTitle, findsOneWidget);
      // google_fonts resolves asset-loaded family names (offline tests use
      // bundled assets): 'SpaceGrotesk_regular', not the display name.
      expect(
        DefaultTextStyle.of(tester.element(appBarTitle)).style.fontFamily,
        startsWith('SpaceGrotesk'),
      );

      // -- Aprender: unit path with a mint progress accent.
      expect(find.text('UNIDAD 1'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (Widget w) =>
              w is LinearProgressIndicator && w.color == KineticColors.mint,
        ),
        findsWidgets,
      );

      // -- Práctica: themed exercise hub, Plus Jakarta body text.
      await tester.tap(find.text('Práctica'));
      await tester.pumpAndSettle();
      expect(find.text('Elige un ejercicio'), findsOneWidget);
      final Finder bodyText = find.text(
        'Completa lecciones en Aprender para desbloquear la práctica.',
      );
      expect(bodyText, findsOneWidget);
      expect(
        DefaultTextStyle.of(tester.element(bodyText)).style.fontFamily,
        startsWith('PlusJakartaSans'),
      );
      final Icon recognizeIcon =
          tester.widget<Icon>(find.byIcon(Icons.visibility_outlined));
      expect(recognizeIcon.color, KineticColors.mint);
      _expectNoBingoInNavRail();
      // Only the two implemented exercise types are offered.
      expect(find.text('Asociar'), findsOneWidget);
      _expectNoComingSoonCards();

      // -- Traductor: KineticButton CTA plus the real offline quick-phrase
      // path. 'hola' is a seeded phrase and matches the fixture lemma, so the
      // whole phrase resolves and nothing is reported as out of vocabulary.
      // load() pauses at the first sign, so no timers are pending — but the
      // player card mounts a video-backed sign, whose loading indicator never
      // settles, so bounded pumps instead of pumpAndSettle.
      await tester.tap(find.text('Traductor'));
      await tester.pumpAndSettle();
      expect(find.text('Traducir'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KineticButton),
          matching: _kineticFaceFinder(KineticColors.mint),
        ),
        findsOneWidget,
      );
      await tester.tap(find.widgetWithText(ActionChip, 'hola'));
      await settleWithVideoCard(tester);
      // The translated sequence renders through the REAL LocalMatcher path
      // (load() pauses at the first sign, so no timers are pending for
      // pumpAndSettle). The player card is within the short ListView's build
      // extent, so finders reach it without scrolling; scrollUntilVisible is
      // ambiguous here because the TextField owns a second (internal)
      // Scrollable inside the same subtree.
      expect(find.text('Secuencia 1/1'), findsOneWidget);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.play_circle)).color,
        KineticColors.mint,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.volume_up)).color,
        KineticColors.iris,
      );
      _expectNoBingoInNavRail();

      // -- Premium: paywall surfaces with the amber trial badge and the
      // always-visible attribution (below the fold in the free-user layout,
      // so scroll the paywall list until it builds into view).
      // Bounded pumps from here on: the shell is an IndexedStack, so the
      // Traductor tab and its video-backed player card stay mounted (and
      // animating) after switching tabs — pumpAndSettle cannot return.
      await tester.tap(find.text('Premium'));
      await settleWithVideoCard(tester);
      expect(find.text('Signo Premium'), findsOneWidget);
      expect(find.text('USD 49.99/año'), findsOneWidget);
      expect(find.text('7 días gratis'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(kPoweredByRevenueCat),
        200,
        scrollable: find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text(kPoweredByRevenueCat), findsOneWidget);
      _expectNoBingoInNavRail();

      // The shell survived the whole walk (IndexedStack contract intact).
      expect(find.byType(SignoShell), findsOneWidget);
    },
  );
}
