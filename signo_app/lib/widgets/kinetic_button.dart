import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/settings/settings.dart';

/// Visual weight of the tactile button.
enum KineticButtonVariant { primary, secondary }

/// 3D tactile Kinetic button.
///
/// A pill-shaped face resting on a 4px darker bottom rim. At rest the face is
/// translated -3px on Y (raised over the rim); tapping sinks it back 3px into
/// the rim for a physical press. When reduced motion is on (app toggle or the
/// system "disable animations" accessibility setting) the translation is
/// skipped entirely and only the color feedback remains. Minimum height is
/// 56px, keeping the touch target above the 48px accessibility floor.
class KineticButton extends ConsumerStatefulWidget {
  const KineticButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = KineticButtonVariant.primary,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final KineticButtonVariant variant;
  final bool expand;
  final IconData? icon;

  @override
  ConsumerState<KineticButton> createState() => _KineticButtonState();
}

class _KineticButtonState extends ConsumerState<KineticButton> {
  static const double _rimHeight = 4;
  static const double _liftOffset = -3;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion =
        ref.watch(settingsProvider.select((s) => s.reducedMotion)) ||
        MediaQuery.disableAnimationsOf(context);
    final bool enabled = widget.onPressed != null;

    final (Color face, Color rim, Color labelColor) = switch (widget.variant) {
      KineticButtonVariant.primary => (
        KineticColors.mint,
        KineticColors.mintRim,
        KineticColors.onMint,
      ),
      KineticButtonVariant.secondary => (
        KineticColors.iris,
        KineticColors.irisRim,
        KineticColors.onIris,
      ),
    };
    final Color faceColor = !enabled
        ? KineticColors.surfaceContainerHigh
        : _pressed
        ? Color.lerp(face, KineticColors.background, 0.08)!
        : face;
    final Color rimColor = enabled ? rim : KineticColors.outline;
    final Color labelColorResolved = enabled
        ? labelColor
        : KineticColors.textLow;

    final Duration animationDuration = Duration(
      milliseconds: reducedMotion ? 0 : 100,
    );
    final double yOffset = !reducedMotion && !_pressed ? _liftOffset : 0;

    final Widget button = AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, yOffset, 0),
      padding: const EdgeInsets.only(bottom: _rimHeight),
      decoration: BoxDecoration(
        color: rimColor,
        borderRadius: BorderRadius.circular(KineticRadii.pill),
      ),
      child: AnimatedContainer(
        duration: animationDuration,
        curve: Curves.easeOut,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: faceColor,
          borderRadius: BorderRadius.circular(KineticRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: labelColorResolved, size: 22),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: labelColorResolved,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: widget.expand ? SizedBox(width: double.infinity, child: button) : button,
        ),
      ),
    );
  }
}
