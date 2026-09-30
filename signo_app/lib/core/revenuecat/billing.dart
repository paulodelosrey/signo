import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// Build-time seam for the RevenueCat key (spec `monetization`): injected via
/// `--dart-define=REVENUECAT_KEY=...` in debug (public by design for the Test
/// Store) and NEVER committed to the repo.
const String kRevenueCatKeyDefine = 'REVENUECAT_KEY';

/// Entitlement identifier that unlocks PRO in the RevenueCat dashboard.
const String kProEntitlementId = 'pro';

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

/// Raised when a SPECIFIC plan was requested and the current offering does not
/// carry it (not configured in the dashboard, wrong store, plan withdrawn).
///
/// Split from [BillingUnavailableError] so the controller can say "that plan
/// is unavailable" instead of the misleading "your payment failed", and so no
/// caller has to string-match a reason to tell the two apart. It is NOT a
/// fallback signal: the gateway never substitutes a different plan for the one
/// that was asked for.
class PackageUnavailableError extends BillingUnavailableError {
  const PackageUnavailableError(super.reason);
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
  ///
  /// [packageType] selects WHICH plan is bought when no paywall is configured:
  /// null keeps the legacy preference (annual, else the first available
  /// package). A concrete type MUST resolve to exactly that package or the call
  /// fails — silently buying a different plan than the one the button promised
  /// is the one failure mode this parameter exists to prevent.
  Future<bool> purchasePro({PackageType? packageType});
}

/// RevenueCat-backed [BillingGateway] over the real `purchases_flutter` SDK.
///
/// Keyless contract (unchanged): with no `--dart-define=REVENUECAT_KEY=...`
/// the gateway fails fast with [BillingUnavailableError] and the controller
/// runs the keyless demo (simulated local PRO).
///
/// With a key: [configure] hands the key to the native SDK, [hasProEntitlement]
/// reads `customerInfo.entitlements.active['pro']` and [purchasePro] presents
/// the RevenueCat paywall, falling back to a direct package purchase (or
/// buying exactly the requested [PackageType] when one is given). Every
/// SDK failure is rethrown as [BillingUnavailableError], which is exactly what
/// the controller already degrades from — the [BillingGateway] shape, the
/// controller and the state are untouched.
class RevenueCatGateway implements BillingGateway {
  const RevenueCatGateway({
    this.apiKey = const String.fromEnvironment(kRevenueCatKeyDefine),
  });

  /// Build-time injected key; empty means the keyless demo path.
  final String apiKey;

  /// True only when a non-empty key was injected at build time.
  bool get isConfigured => apiKey.isNotEmpty;

  /// `purchases_flutter` is a process-wide singleton: configuring it twice
  /// throws natively, so the success is latched here. Static because the
  /// gateway is `const` and the SDK itself is global state.
  static bool _sdkConfigured = false;

  @override
  Future<void> configure() async {
    _requireKey();
    if (_sdkConfigured) {
      return;
    }
    await _guard('Purchases.configure', () async {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(apiKey));
    });
    _sdkConfigured = true;
  }

  @override
  Future<bool> hasProEntitlement() async {
    _requireKey();
    await configure();
    return _guard(
      'Entitlement read',
      () async => _hasPro(await Purchases.getCustomerInfo()),
    );
  }

  @override
  Future<bool> purchasePro({PackageType? packageType}) async {
    _requireKey();
    await configure();
    await _guard(
      'Purchase',
      () => _runPaywallOrPackage(wanted: packageType),
    );
    // The source of truth is the entitlement, not the purchase result: a
    // restored or previously-owned subscription must also settle as PRO.
    return _guard(
      'Entitlement read',
      () async => _hasPro(await Purchases.getCustomerInfo()),
    );
  }

  /// Keyless fast-fail — the exact contract the controller's demo mode relies
  /// on. Never reached on the configured path.
  void _requireKey() {
    if (!isConfigured) {
      throw BillingUnavailableError(
        'No $kRevenueCatKeyDefine injected (keyless demo mode).',
      );
    }
  }

  /// Maps any SDK failure onto [BillingUnavailableError], the single error
  /// type [BillingController] degrades from into the keyless demo.
  static Future<T> _guard<T>(String context, Future<T> Function() action) async {
    try {
      return await action();
    } on BillingUnavailableError {
      rethrow;
    } catch (error) {
      throw BillingUnavailableError('$context failed: $error');
    }
  }

  /// True when `pro` is present in the active entitlement map. The map is
  /// already filtered by the native SDK; the explicit `isActive` check keeps
  /// the intent readable and defends against a stale cache entry.
  static bool _hasPro(CustomerInfo info) {
    final EntitlementInfo? pro = info.entitlements.active[kProEntitlementId];
    return pro != null && pro.isActive;
  }

  /// Prefers the RevenueCat paywall (server-configured pricing, no identifiers
  /// hardcoded here) and falls back to purchasing a package directly when no
  /// paywall is configured in the dashboard.
  ///
  /// A CONCRETE [wanted] type skips the paywall on purpose: the paywall is
  /// server-configured and lets the buyer pick any plan, so routing a
  /// "USD 9.99/mes" tap through it can settle an annual purchase. When the user
  /// tapped a specific plan, that plan is bought directly or the call fails —
  /// it is never quietly swapped for a different one.
  static Future<void> _runPaywallOrPackage({PackageType? wanted}) async {
    if (wanted == null) {
      try {
        await RevenueCatUI.presentPaywall();
        return;
      } catch (_) {
        // No paywall configured (or the UI module is unavailable): continue to
        // the direct package purchase below.
      }
    }

    final Offerings offerings = await Purchases.getOfferings();
    final List<Package> packages =
        offerings.current?.availablePackages ?? const <Package>[];
    if (packages.isEmpty) {
      throw const BillingUnavailableError('No purchasable package available.');
    }
    final Package target = _selectPackage(packages, wanted);
    await Purchases.purchase(PurchaseParams.package(target));
  }

  /// Resolves the package to buy. With no [wanted] type the annual plan wins
  /// (matches the paywall mockup) and the first package is the last resort,
  /// which keeps the primary CTA behaving exactly as it did.
  ///
  /// With a [wanted] type there is NO fallback: an offering that does not
  /// contain that plan (not configured in the dashboard, wrong store, plan
  /// withdrawn) is an error the controller surfaces on the paywall. Falling
  /// back to `packages.first` there would sell an annual subscription to
  /// someone who just tapped "USD 9.99/mes" — a wrong charge, not a wrong
  /// label, and nothing in the UI says what was actually bought.
  static Package _selectPackage(List<Package> packages, PackageType? wanted) {
    if (wanted == null) {
      return packages.firstWhere(
        (Package p) => p.packageType == PackageType.annual,
        orElse: () => packages.first,
      );
    }
    return packages.firstWhere(
      (Package p) => p.packageType == wanted,
      orElse: () => throw PackageUnavailableError(
        'The ${wanted.name} package is not available in the current offering.',
      ),
    );
  }
}
