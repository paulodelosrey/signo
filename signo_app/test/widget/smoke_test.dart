import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/app/router.dart';
import 'package:signo_app/app/shell.dart';
import 'package:signo_app/app/theme.dart';
import 'package:signo_app/core/settings/settings.dart';

Future<void> pumpApp(WidgetTester tester, {required bool onboardingSeen}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'signo.onboardingSeen': onboardingSeen,
  });
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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
      // Premium. Bingo exists only as a hidden tab per spec — its label must
      // be absent everywhere in the tree.
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

    expect(find.text('Traductor offline'), findsOneWidget);
    expect(find.byType(SignoShell), findsOneWidget);
  });
}
