import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/settings.dart';
import 'onboarding.dart';
import 'shell.dart';
import 'theme.dart';

/// Application root widget and simple router.
///
/// Routes between the static onboarding gate (first launch, flagged in
/// SharedPreferences) and the 4-tab Kinetic shell. The gate transition is an
/// [AnimatedSwitcher] whose duration collapses to zero when the reduced-motion
/// toggle (or the system disable-animations setting) is on.
class SignoApp extends ConsumerWidget {
  const SignoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(settingsProvider);
    final bool reducedMotion =
        settings.reducedMotion || MediaQuery.disableAnimationsOf(context);

    return MaterialApp(
      title: 'Signo',
      debugShowCheckedModeBanner: false,
      theme: buildKineticTheme(),
      // A11y font-scaling (spec app-shell): the large-text toggle scales the
      // whole app (navigator included) through a MediaQuery textScaler
      // override; the system's own scaling is respected when it is off.
      builder: (BuildContext context, Widget? child) {
        if (!settings.largeText) {
          return child ?? const SizedBox.shrink();
        }
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.3),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AnimatedSwitcher(
        duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 250),
        child: settings.onboardingSeen
            ? const SignoShell(key: ValueKey<String>('shell'))
            : const OnboardingFlow(key: ValueKey<String>('onboarding')),
      ),
    );
  }
}
