import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Kinetic design tokens for the Signo MVP.
///
/// Single source of truth for the dark "Kinetic" look: background ladder,
/// mint/iris/amber accents, and the rounded shape scale. Refer to these
/// constants instead of hard-coding colors or radii in feature code.
abstract final class KineticColors {
  // Background ladder.
  static const Color background = Color(0xFF10131A);
  static const Color surfaceContainerLow = Color(0xFF191C23);
  static const Color surfaceContainerMid = Color(0xFF1D2027);
  static const Color surfaceContainerHigh = Color(0xFF272A31);
  static const Color outline = Color(0xFF282F3E);

  // Primary: mint.
  static const Color mint = Color(0xFF00F0A8);
  static const Color onMint = Color(0xFF003824);
  static const Color mintContainer = Color(0xFF0B4633);
  static const Color onMintContainer = Color(0xFF7CFFD4);
  static const Color mintRim = Color(0xFF00A878);

  // Secondary: iris.
  static const Color iris = Color(0xFF7B61FF);
  static const Color onIris = Color(0xFFFFFFFF);
  static const Color irisContainer = Color(0xFF2A2358);
  static const Color onIrisContainer = Color(0xFFE4DEFF);
  static const Color irisRim = Color(0xFF5A45D8);

  // Tertiary: amber.
  static const Color amber = Color(0xFFFFB800);
  static const Color onAmber = Color(0xFF2B1D00);

  // Error: #FF3366 family.
  static const Color error = Color(0xFFFF3366);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFF3D0A1C);
  static const Color onErrorContainer = Color(0xFFFFB3C4);

  // Text scale.
  static const Color textHigh = Color(0xFFE0E2EC);
  static const Color textLow = Color(0xFFB9CBBF);
}

/// Rounded shape scale: 8 / 16 / 24 / pill.
abstract final class KineticRadii {
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double pill = 999;
}

/// Dark [ColorScheme] built from the Kinetic tokens.
const ColorScheme kineticColorScheme = ColorScheme.dark(
  primary: KineticColors.mint,
  onPrimary: KineticColors.onMint,
  primaryContainer: KineticColors.mintContainer,
  onPrimaryContainer: KineticColors.onMintContainer,
  secondary: KineticColors.iris,
  onSecondary: KineticColors.onIris,
  secondaryContainer: KineticColors.irisContainer,
  onSecondaryContainer: KineticColors.onIrisContainer,
  tertiary: KineticColors.amber,
  onTertiary: KineticColors.onAmber,
  error: KineticColors.error,
  onError: KineticColors.onError,
  errorContainer: KineticColors.errorContainer,
  onErrorContainer: KineticColors.onErrorContainer,
  surface: KineticColors.background,
  onSurface: KineticColors.textHigh,
  onSurfaceVariant: KineticColors.textLow,
  surfaceContainerLowest: KineticColors.background,
  surfaceContainerLow: KineticColors.surfaceContainerLow,
  surfaceContainer: KineticColors.surfaceContainerMid,
  surfaceContainerHigh: KineticColors.surfaceContainerHigh,
  surfaceContainerHighest: KineticColors.surfaceContainerHigh,
  outline: KineticColors.outline,
  outlineVariant: KineticColors.outline,
  inverseSurface: KineticColors.textHigh,
  onInverseSurface: KineticColors.background,
);

/// Composed Kinetic [TextTheme].
///
/// Space Grotesk carries display, headline and bold labels; Plus Jakarta Sans
/// carries body text. Colors are re-applied so styles stay readable on the
/// dark background ladder (Google Fonts text themes default to dark inks).
///
/// The theme never pins a text scale factor: it only defines styles, so the
/// system text-scaling preference is respected everywhere.
TextTheme buildKineticTextTheme() {
  final TextTheme grotesk = GoogleFonts.spaceGroteskTextTheme();
  final TextTheme jakarta = GoogleFonts.plusJakartaSansTextTheme();
  return jakarta.copyWith(
    displayLarge: grotesk.displayLarge?.copyWith(fontWeight: FontWeight.w700),
    displayMedium: grotesk.displayMedium?.copyWith(fontWeight: FontWeight.w700),
    displaySmall: grotesk.displaySmall?.copyWith(fontWeight: FontWeight.w700),
    headlineLarge: grotesk.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
    headlineMedium: grotesk.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
    ),
    headlineSmall: grotesk.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    titleLarge: grotesk.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: grotesk.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    titleSmall: jakarta.titleSmall,
    bodyLarge: jakarta.bodyLarge,
    bodyMedium: jakarta.bodyMedium,
    bodySmall: jakarta.bodySmall,
    labelLarge: grotesk.labelLarge?.copyWith(fontWeight: FontWeight.w700),
    labelMedium: grotesk.labelMedium?.copyWith(fontWeight: FontWeight.w600),
    labelSmall: grotesk.labelSmall?.copyWith(fontWeight: FontWeight.w600),
  ).apply(
    displayColor: KineticColors.textHigh,
    bodyColor: KineticColors.textHigh,
  );
}

/// Builds the full Kinetic [ThemeData].
ThemeData buildKineticTheme() {
  final TextTheme textTheme = buildKineticTextTheme();
  return ThemeData(
    useMaterial3: true,
    colorScheme: kineticColorScheme,
    scaffoldBackgroundColor: KineticColors.background,
    textTheme: textTheme,
    iconTheme: const IconThemeData(color: KineticColors.textLow),
    dividerTheme: const DividerThemeData(color: KineticColors.outline),
    splashFactory: InkSparkle.splashFactory,
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KineticColors.mint
            : KineticColors.outline,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? KineticColors.onMint
            : KineticColors.textLow,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: KineticColors.surfaceContainerMid,
      indicatorColor: KineticColors.mint.withValues(alpha: 0.14),
      elevation: 0,
      height: 68,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const IconThemeData(color: KineticColors.mint)
            : const IconThemeData(color: KineticColors.textLow),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? KineticColors.mint
              : KineticColors.textLow,
        ),
      ),
    ),
  );
}

/// Shared transparent app bar used across the shell and feature screens.
PreferredSizeWidget kineticAppBar(String title) {
  return AppBar(
    title: Text(title),
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  );
}
