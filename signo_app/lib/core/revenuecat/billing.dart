/// Build-time seam for the RevenueCat key (spec `monetization`): injected via
/// `--dart-define=REVENUECAT_KEY=...` in debug (public by design for the Test
/// Store) and NEVER committed to the repo.
const String kRevenueCatKeyDefine = 'REVENUECAT_KEY';

/// Attribution line the spec requires to be visible on the paywall.
const String kPoweredByRevenueCat = 'Powered by RevenueCat';

/// Thrown by [RevenueCatGateway] while the remote billing path is
/// unavailable. `BillingController` catches it and falls back to the keyless
/// demo — the same failed-remote contract as GeminiStrategy (M4).
class BillingUnavailableError implements Exception {
  const BillingUnavailableError(this.reason);

  final String reason;

  @override
  String toString() => 'BillingUnavailableError: $reason';
}

/// Remote billing seam. Three operations only: prepare the SDK, read the
/// `pro` entitlement, and run a purchase through the paywall.
abstract class BillingGateway {
  /// Prepares the SDK with the build-time key.
  ///
  /// Throws [BillingUnavailableError] when keyless — the controller treats
  /// that as "enter demo mode" (spec: empty key MUST enter demo mode without
  /// crashing).
  Future<void> configure();

  /// True when the `pro` entitlement is currently active.
  Future<bool> hasProEntitlement();

  /// Presents the paywall and completes a purchase. True when `pro` lands.
  Future<bool> purchasePro();
}

/// RevenueCat-backed [BillingGateway] — fully wired but keyless.
///
/// BLOCKED-USER (M6): there is no RevenueCat account / Test Store key yet,
/// so this gateway ALWAYS fails fast with [BillingUnavailableError] and the
/// controller runs the keyless demo (simulated local PRO) — exactly what the
/// spec requires for an empty key.
///
/// When the key is provisioned: add `purchases_flutter`, replace the TODO
/// bodies below with `Purchases.configure(PurchasesConfiguration(apiKey))`,
/// the `customerInfo.entitlements.active['pro']` read and
/// `Purchases.presentPaywall()` behind this SAME interface. No other file
/// changes: the controller already prefers the gateway and degrades to the
/// keyless demo on any [BillingUnavailableError].
class RevenueCatGateway implements BillingGateway {
  const RevenueCatGateway({
    this.apiKey = const String.fromEnvironment(kRevenueCatKeyDefine),
  });

  /// Build-time injected key; empty means the keyless demo path.
  final String apiKey;

  /// True only when a non-empty key was injected at build time.
  bool get isConfigured => apiKey.isNotEmpty;

  @override
  Future<void> configure() async {
    if (!isConfigured) {
      throw BillingUnavailableError(
        'No $kRevenueCatKeyDefine injected (keyless demo mode).',
      );
    }
    // TODO(revenuecat-key): wire purchases_flutter here when the Test Store
    // key arrives (BLOCKED-USER). Until the SDK dependency lands the remote
    // path must never half-work, so the keyless-demo contract stays intact.
    throw BillingUnavailableError(
      'RevenueCat SDK not wired yet (purchases_flutter pending).',
    );
  }

  @override
  Future<bool> hasProEntitlement() async {
    // Same seam as [configure]: unreachable until the real SDK lands.
    throw const BillingUnavailableError(
      'Entitlement reads require the RevenueCat SDK.',
    );
  }

  @override
  Future<bool> purchasePro() async {
    // TODO(revenuecat-key): presentPaywall() → PaywallResult → entitlement.
    throw const BillingUnavailableError(
      'Purchases require the RevenueCat SDK.',
    );
  }
}
