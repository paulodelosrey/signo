import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show PackageType;

import '../../app/theme.dart';
import '../../core/revenuecat/billing.dart';
import '../../core/revenuecat/billing_provider.dart';
import '../../features/learn/economy.dart';
import '../../widgets/kinetic_button.dart';

/// Premium tab: the RevenueCat paywall (spec `monetization`).
///
/// Mirrors the mockup: USD 49.99/year with a 7-day free trial, or
/// USD 9.99/month. Keyless demo (BLOCKED-USER: no Test Store key yet)
/// simulates the purchase locally by flipping the economy `hasPro` seam;
/// the "Powered by RevenueCat" attribution stays visible in every mode.
class PremiumScreen extends ConsumerStatefulWidget {
  const PremiumScreen({super.key});

  @override
  ConsumerState<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends ConsumerState<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    // Settles the billing mode (keyless demo vs RevenueCat) outside the
    // build phase. The shell hosts this screen inside an IndexedStack, so
    // this effectively initializes billing as soon as the app starts.
    Future<void>.microtask(() async {
      if (!mounted) {
        return;
      }
      await ref.read(billingProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final BillingState billing = ref.watch(billingProvider);
    final bool hasPro =
        ref.watch(progressProvider.select((EconomyState s) => s.hasPro));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        _benefitsCard(context),
        const SizedBox(height: 16),
        // Once PRO lands (real purchase or keyless demo) the purchase CTAs
        // go away entirely — the economy `hasPro` seam is the only truth.
        if (hasPro)
          _proActiveCard(context)
        else ...[
          _planTiles(context),
          const SizedBox(height: 16),
          KineticButton(
            label: billing.pendingAction
                ? 'Procesando…'
                : 'Empezar 7 días gratis',
            variant: KineticButtonVariant.primary,
            expand: true,
            // No packageType: the paywall (server-configured pricing) is the
            // right surface for "the recommended plan", and it lets the buyer
            // choose. The gateway's annual fallback only applies when no
            // paywall is configured at all.
            onPressed: billing.pendingAction
                ? null
                : () => ref.read(billingProvider.notifier).purchasePro(),
          ),
          const SizedBox(height: 8),
          KineticButton(
            label: 'Elegir USD 9.99/mes',
            variant: KineticButtonVariant.secondary,
            expand: true,
            // Targets the MONTHLY package explicitly. This used to call the
            // very same no-argument `purchasePro()` as the button above it,
            // and that path prefers the annual plan — so a judge who tapped
            // "USD 9.99/mes" was one tap away from buying USD 49.99/año while
            // the button said otherwise. If the monthly package cannot be
            // resolved the controller surfaces kPackageUnavailableMessage;
            // it never buys the annual plan instead.
            onPressed: billing.pendingAction
                ? null
                : () => ref
                    .read(billingProvider.notifier)
                    .purchasePro(packageType: PackageType.monthly),
          ),
          const SizedBox(height: 8),
          TextButton(
            // 48px accessibility floor for the text-only restore target.
            style: TextButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: billing.pendingAction
                ? null
                : () => ref.read(billingProvider.notifier).restorePurchases(),
            child: const Text('Restaurar compras'),
          ),
        ],
        if (billing.error != null) ...[
          const SizedBox(height: 12),
          _noticeCard(
            context,
            billing.error!,
            background: KineticColors.errorContainer,
            border: KineticColors.error,
          ),
        ],
        if (billing.notice != null) ...[
          const SizedBox(height: 12),
          _noticeCard(
            context,
            billing.notice!,
            background: KineticColors.amber.withValues(alpha: 0.12),
            border: KineticColors.amber,
          ),
        ],
        const SizedBox(height: 24),
        Text(
          kPoweredByRevenueCat,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(color: KineticColors.textLow),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _benefitsCard(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KineticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
        border: Border.all(color: KineticColors.mint, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👑', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text('Signo Premium', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          _benefit(context, '💜', 'Corazones infinitos'),
          _benefit(context, '🧩', 'Módulos ilimitados'),
          _benefit(context, '📥', 'Copia offline de videos'),
          _benefit(context, '🎓', 'Vista previa del certificado'),
        ],
      ),
    );
  }

  Widget _benefit(BuildContext context, String emoji, String label) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
        ],
      ),
    );
  }

  /// Two pricing tiles mirroring the mockup: annual with the 7-day trial
  /// badge, monthly beside it. [IntrinsicHeight] bounds the Row's height
  /// (a vertical ListView leaves it unbounded) so `stretch` can equalize
  /// both cards to the tallest one.
  Widget _planTiles(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _planCard(
              context,
              name: 'Anual',
              price: 'USD 49.99/año',
              badge: '7 días gratis',
              highlighted: true,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                _planCard(context, name: 'Mensual', price: 'USD 9.99/mes'),
          ),
        ],
      ),
    );
  }

  Widget _planCard(
    BuildContext context, {
    required String name,
    required String price,
    String? badge,
    bool highlighted = false,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KineticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KineticRadii.md),
        border: Border.all(
          color: highlighted ? KineticColors.mint : KineticColors.outline,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: KineticColors.amber,
                borderRadius: BorderRadius.circular(KineticRadii.pill),
              ),
              child: Text(
                badge,
                style: textTheme.labelSmall?.copyWith(
                  color: KineticColors.onAmber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(name, style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            price,
            style: textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  /// Success state once the economy `hasPro` seam is flipped.
  Widget _proActiveCard(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: KineticColors.mintContainer,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
        border: Border.all(color: KineticColors.mint, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✅', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text('PRO activo', style: textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '∞',
                style: textTheme.displaySmall?.copyWith(
                  color: KineticColors.mint,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Corazones infinitos y todos los módulos desbloqueados. '
                  'Gracias por apoyar a Signo.',
                  style: textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noticeCard(
    BuildContext context,
    String message, {
    required Color background,
    required Color border,
  }) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KineticRadii.md),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: border),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: textTheme.bodySmall)),
        ],
      ),
    );
  }
}
