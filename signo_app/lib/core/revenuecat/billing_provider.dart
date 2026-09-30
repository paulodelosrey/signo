import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart' show PackageType;

import '../../features/learn/economy.dart' show progressProvider;
import 'billing.dart';

/// User-facing notice shown while the keyless demo is active (spec
/// `monetization`: empty key → demo mode with a sandbox notice, no crash).
const String kKeylessDemoNotice =
    'Modo demostración (sandbox): sin clave de RevenueCat, la compra se '
    'simula localmente.';

/// Notice after a simulated keyless-demo purchase.
const String kDemoPurchaseNotice =
    'Compra simulada: PRO activado en modo demostración.';

/// Generic user-facing failure for the configured (real RevenueCat) path.
const String kPurchaseFailedMessage =
    'No se pudo completar la compra. Intenta de nuevo.';

/// Failure when a specific plan was requested and the offering does not carry
/// it. Distinct from [kPurchaseFailedMessage] on purpose: the user did nothing
/// wrong, so the copy must not read as "your payment failed".
const String kPackageUnavailableMessage =
    'Ese plan no está disponible en este momento. Intenta con el plan anual.';

/// Restore outcome inside the keyless demo: nothing to restore.
const String kRestoreDemoMessage =
    'Restaurar no aplica en el modo demostración.';

/// Restore outcome on the configured path when there are no prior purchases.
const String kRestoreNothingMessage = 'No encontramos compras previas.';

/// Restore failure on the configured path.
const String kRestoreFailedMessage =
    'No se pudo restaurar la compra. Intenta de nuevo.';

/// Which billing backend the controller settled on.
enum BillingMode {
  /// [BillingController.initialize] has not run yet.
  pending,

  /// Keyless demo: purchases simulate PRO locally (no RevenueCat key).
  keylessDemo,

  /// Real RevenueCat path (Test Store key + purchases_flutter SDK).
  revenueCat,
}

/// Immutable UI state of the billing flow.
///
/// It deliberately does NOT carry `hasPro`: the single source of truth for
/// PRO is the economy (`progressProvider.hasPro`, the T7 seam) and this
/// controller only flips it.
class BillingState {
  const BillingState({
    this.mode = BillingMode.pending,
    this.pendingAction = false,
    this.notice,
    this.error,
  });

  final BillingMode mode;

  /// True while a purchase/restore round-trip is in flight (CTAs disabled).
  final bool pendingAction;

  /// Informational line (demo notice, simulated purchase, restore outcome).
  final String? notice;

  /// Last failure worth surfacing on the paywall (purchase/restore).
  final String? error;

  bool get isKeylessDemo => mode == BillingMode.keylessDemo;

  BillingState copyWith({
    BillingMode? mode,
    bool? pendingAction,
    String? notice,
    String? error,
    bool clearNotice = false,
    bool clearError = false,
  }) {
    return BillingState(
      mode: mode ?? this.mode,
      pendingAction: pendingAction ?? this.pendingAction,
      notice: clearNotice ? null : (notice ?? this.notice),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Injectable gateway; overridden with a fake in tests.
final Provider<BillingGateway> billingGatewayProvider =
    Provider<BillingGateway>((Ref ref) => const RevenueCatGateway());

/// Riverpod controller: settles the billing mode once, routes
/// purchase/restore to the gateway, and flips the economy `hasPro` seam
/// (T7) on every grant — infinite hearts and the hearts-gate bypass live in
/// `features/learn/economy.dart`, never duplicated here.
class BillingController extends Notifier<BillingState> {
  @override
  BillingState build() => const BillingState();

  BillingGateway get _gateway => ref.read(billingGatewayProvider);

  /// Prepares the backend. Keyless → demo mode with the sandbox notice;
  /// configured → refreshes the entitlement (an active one restores PRO).
  /// Idempotent: only the first call transitions out of [BillingMode.pending].
  Future<void> initialize() async {
    if (state.mode != BillingMode.pending) {
      return;
    }
    try {
      await _gateway.configure();
    } on BillingUnavailableError {
      state = const BillingState(
        mode: BillingMode.keylessDemo,
        notice: kKeylessDemoNotice,
      );
      return;
    }
    try {
      if (await _gateway.hasProEntitlement()) {
        await _grantPro(mode: BillingMode.revenueCat);
      } else {
        state = const BillingState(mode: BillingMode.revenueCat);
      }
    } on BillingUnavailableError {
      state = const BillingState(
        mode: BillingMode.keylessDemo,
        notice: kKeylessDemoNotice,
      );
    }
  }

  /// Runs the purchase. Keyless demo simulates it locally (judges experience
  /// PRO without a real purchase); the configured path goes through the
  /// gateway and degrades to a surfaced error — never a crash.
  ///
  /// [packageType] targets ONE plan instead of the paywall: the monthly CTA
  /// passes [PackageType.monthly] so it can never settle an annual charge.
  /// The gateway refuses to substitute another plan, so a missing plan
  /// surfaces [kPackageUnavailableMessage] rather than quietly buying
  /// something else. Null keeps the primary CTA on the paywall.
  Future<void> purchasePro({PackageType? packageType}) async {
    state = state.copyWith(pendingAction: true, clearError: true);
    if (state.isKeylessDemo) {
      await _grantPro(mode: BillingMode.keylessDemo);
      return;
    }
    try {
      final bool granted = await _gateway.purchasePro(packageType: packageType);
      if (granted) {
        await _grantPro(mode: BillingMode.revenueCat);
      } else {
        state = state.copyWith(
          pendingAction: false,
          error: kPurchaseFailedMessage,
        );
      }
    } on PackageUnavailableError {
      state = state.copyWith(
        pendingAction: false,
        error: kPackageUnavailableMessage,
      );
    } on BillingUnavailableError {
      state = state.copyWith(
        pendingAction: false,
        error: kPurchaseFailedMessage,
      );
    }
  }

  /// Restore: the configured path re-reads the entitlement; the demo only
  /// informs (there is nothing real to restore without a key).
  Future<void> restorePurchases() async {
    if (state.isKeylessDemo) {
      state = state.copyWith(notice: kRestoreDemoMessage, clearError: true);
      return;
    }
    state = state.copyWith(pendingAction: true, clearError: true);
    try {
      if (await _gateway.hasProEntitlement()) {
        await _grantPro(mode: BillingMode.revenueCat);
      } else {
        state = state.copyWith(
          pendingAction: false,
          notice: kRestoreNothingMessage,
        );
      }
    } on BillingUnavailableError {
      state = state.copyWith(
        pendingAction: false,
        error: kRestoreFailedMessage,
      );
    }
  }

  /// The ONE economy touch (T7 seam): `setPro` persists `hasPro` and every
  /// gate rule (infinite hearts, gate bypass, PRO badge) follows from it.
  Future<void> _grantPro({required BillingMode mode}) async {
    await ref.read(progressProvider.notifier).setPro(true);
    state = BillingState(
      mode: mode,
      notice: mode == BillingMode.keylessDemo ? kDemoPurchaseNotice : null,
    );
  }
}

/// Current billing state, shared app-wide (the paywall watches it).
final NotifierProvider<BillingController, BillingState> billingProvider =
    NotifierProvider<BillingController, BillingState>(BillingController.new);
