import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/revenuecat/billing.dart';
import 'package:signo_app/core/revenuecat/billing_provider.dart';
import 'package:signo_app/core/settings/settings.dart'
    show sharedPreferencesProvider;
import 'package:signo_app/features/learn/economy.dart';
import 'package:signo_app/features/paywall/premium_screen.dart';
import 'package:signo_app/widgets/kinetic_button.dart';

/// Fake remote for the configured-gateway tests: pure Dart, never touches a
/// platform channel, so it is safe inside testWidgets FakeAsync zones.
class FakeBillingGateway implements BillingGateway {
  FakeBillingGateway({
    this.entitled = false,
    this.purchaseGrants = true,
    this.throwOnPurchase = false,
  });

  final bool entitled;
  final bool purchaseGrants;
  final bool throwOnPurchase;

  @override
  Future<void> configure() async {}

  @override
  Future<bool> hasProEntitlement() async => entitled;

  @override
  Future<bool> purchasePro() async {
    if (throwOnPurchase) {
      throw const BillingUnavailableError('fake gateway outage');
    }
    return purchaseGrants;
  }
}

/// Complete progress blob fixture (missing keys would make
/// ProgressRepository fall back to a fresh state and mask the assertion).
String progressBlob({bool hasPro = false}) =>
    '{"hearts":5,"xp":0,"gems":0,"streak":0,"lastPlayedOn":null,'
    '"failedSignIds":[],"completedNodeIds":[],"claimedChestUnits":[],'
    '"hasPro":$hasPro}';

late SharedPreferences prefs;

/// Builds a ProviderContainer over mock prefs with an optional gateway
/// override (M5 harness pattern).
Future<ProviderContainer> buildContainer({
  BillingGateway? gateway,
  Map<String, Object>? prefsOverrides,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'signo.reducedMotion': true,
    ...?prefsOverrides,
  });
  prefs = await SharedPreferences.getInstance();
  final ProviderContainer container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (gateway != null) billingGatewayProvider.overrideWithValue(gateway),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Pumps the paywall inside a minimal MaterialApp scaffold (M5 harness
/// pattern: mock prefs + reduced motion on for deterministic settling).
Future<void> pumpPaywall(
  WidgetTester tester, {
  Map<String, Object>? prefsOverrides,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'signo.reducedMotion': true,
    ...?prefsOverrides,
  });
  prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: const Scaffold(body: PremiumScreen()),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    // Keep widget tests offline, exactly like the app runtime.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RevenueCat gateway (keyless stub)', () {
    test('keyless stub never configures and always reports unavailable',
        () async {
      const RevenueCatGateway gateway = RevenueCatGateway();
      expect(gateway.isConfigured, isFalse);
      expect(gateway.apiKey, isEmpty);
      await expectLater(
        gateway.configure(),
        throwsA(isA<BillingUnavailableError>()),
      );
      await expectLater(
        gateway.hasProEntitlement(),
        throwsA(isA<BillingUnavailableError>()),
      );
      await expectLater(
        gateway.purchasePro(),
        throwsA(isA<BillingUnavailableError>()),
      );
    });

    test('only a non-empty build-time key counts as configured', () {
      expect(RevenueCatGateway(apiKey: '').isConfigured, isFalse);
      expect(RevenueCatGateway(apiKey: 'test-key').isConfigured, isTrue);
    });

    test('a provisioned key still stays unavailable until the SDK lands',
        () async {
      // Keyless-demo contract: even WITH a key the remote path must fail
      // fast (never half-work) until purchases_flutter is wired — the user
      // has no RevenueCat account yet (BLOCKED-USER).
      const RevenueCatGateway gateway = RevenueCatGateway(apiKey: 'test-key');
      await expectLater(
        gateway.configure(),
        throwsA(isA<BillingUnavailableError>()),
      );
    });

    test('attribution constant matches the spec string verbatim', () {
      expect(kPoweredByRevenueCat, 'Powered by RevenueCat');
    });
  });

  group('BillingController (keyless demo)', () {
    test('initialize enters demo mode without granting PRO or crashing',
        () async {
      final ProviderContainer container = await buildContainer();
      final BillingController controller =
          container.read(billingProvider.notifier);

      await controller.initialize();

      expect(container.read(billingProvider).mode, BillingMode.keylessDemo);
      expect(container.read(billingProvider).notice, kKeylessDemoNotice);
      expect(container.read(progressProvider).hasPro, isFalse);

      // Idempotent: a second pass keeps the settled demo state.
      await controller.initialize();
      expect(container.read(billingProvider).mode, BillingMode.keylessDemo);
    });

    test('keyless purchase grants PRO and unlocks the gates', () async {
      final ProviderContainer container = await buildContainer();
      final BillingController controller =
          container.read(billingProvider.notifier);
      await controller.initialize();

      await controller.purchasePro();

      expect(container.read(progressProvider).hasPro, isTrue);
      expect(container.read(billingProvider).notice, kDemoPurchaseNotice);
      expect(container.read(billingProvider).pendingAction, isFalse);

      // Gates unlock with zero hearts — the hearts-gate bypass lives in the
      // economy rules and follows the flipped seam.
      final EconomyState pro = container.read(progressProvider);
      expect(canStartLesson(pro.copyWith(hearts: 0)), isTrue);

      // Infinite hearts: wrong answers never decrement (Repasar still seeds).
      final EconomyState hit = applyWrongAnswer(pro.copyWith(hearts: 0), 's-casa');
      expect(hit.hearts, 0);
      expect(hit.failedSignIds, contains('s-casa'));
    });

    test('the PRO grant persists write-through to prefs', () async {
      final ProviderContainer container = await buildContainer();
      final BillingController controller =
          container.read(billingProvider.notifier);
      await controller.initialize();

      await controller.purchasePro();

      expect(prefs.getString(kProgressPrefsKey), contains('"hasPro":true'));
    });

    test('restore in demo mode only informs — it never grants PRO', () async {
      final ProviderContainer container = await buildContainer();
      final BillingController controller =
          container.read(billingProvider.notifier);
      await controller.initialize();

      await controller.restorePurchases();

      expect(container.read(billingProvider).notice, kRestoreDemoMessage);
      expect(container.read(progressProvider).hasPro, isFalse);
    });
  });

  group('BillingController (configured gateway seam)', () {
    test('an active entitlement on initialize grants PRO (restore path)',
        () async {
      final ProviderContainer container = await buildContainer(
        gateway: FakeBillingGateway(entitled: true),
      );
      await container.read(billingProvider.notifier).initialize();

      expect(container.read(billingProvider).mode, BillingMode.revenueCat);
      expect(container.read(billingProvider).notice, isNull);
      expect(container.read(progressProvider).hasPro, isTrue);
    });

    test('a completed purchase grants PRO through the gateway', () async {
      final ProviderContainer container = await buildContainer(
        gateway: FakeBillingGateway(),
      );
      await container.read(billingProvider.notifier).initialize();

      await container.read(billingProvider.notifier).purchasePro();

      expect(container.read(billingProvider).mode, BillingMode.revenueCat);
      expect(container.read(billingProvider).error, isNull);
      expect(container.read(progressProvider).hasPro, isTrue);
    });

    test('a declined purchase keeps the free state and surfaces an error',
        () async {
      final ProviderContainer container = await buildContainer(
        gateway: FakeBillingGateway(purchaseGrants: false),
      );
      await container.read(billingProvider.notifier).initialize();

      await container.read(billingProvider.notifier).purchasePro();

      expect(container.read(progressProvider).hasPro, isFalse);
      expect(container.read(billingProvider).error, kPurchaseFailedMessage);
      expect(container.read(billingProvider).pendingAction, isFalse);
    });

    test('a gateway outage during purchase degrades gracefully', () async {
      final ProviderContainer container = await buildContainer(
        gateway: FakeBillingGateway(throwOnPurchase: true),
      );
      await container.read(billingProvider.notifier).initialize();

      await container.read(billingProvider.notifier).purchasePro();

      expect(container.read(progressProvider).hasPro, isFalse);
      expect(container.read(billingProvider).error, kPurchaseFailedMessage);
    });
  });

  group('PremiumScreen (paywall widget)', () {
    testWidgets(
        'keyless demo paywall renders sandbox notice, prices and attribution',
        (WidgetTester tester) async {
      await pumpPaywall(tester);

      // Keyless-demo scenario: no crash, CTAs alive, mockup pricing mirrored.
      expect(find.text('USD 49.99/año'), findsOneWidget);
      expect(find.text('USD 9.99/mes'), findsOneWidget);
      expect(find.text('7 días gratis'), findsOneWidget);
      expect(find.text('Empezar 7 días gratis'), findsOneWidget);

      // Restore, the sandbox/demo notice and the spec attribution all sit
      // below the fold of the lazy ListView — scroll each into view first
      // (M5 pattern).
      final Finder restore = find.widgetWithText(TextButton, 'Restaurar compras');
      await tester.scrollUntilVisible(
        restore,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(restore, findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(kKeylessDemoNotice),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(kKeylessDemoNotice), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text(kPoweredByRevenueCat),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(kPoweredByRevenueCat), findsOneWidget);
    });

    testWidgets('purchase grants PRO from the paywall and hides the CTAs',
        (WidgetTester tester) async {
      await pumpPaywall(tester);

      await tester.tap(find.text('Empezar 7 días gratis'));
      await tester.pumpAndSettle();

      expect(find.text('PRO activo'), findsOneWidget);
      expect(find.text('∞'), findsOneWidget);
      expect(find.text(kDemoPurchaseNotice), findsOneWidget);
      expect(find.text('Empezar 7 días gratis'), findsNothing);
      // The flip IS the economy seam, persisted write-through.
      expect(prefs.getString(kProgressPrefsKey), contains('"hasPro":true'));
    });

    testWidgets('an existing PRO user sees the active card, not the CTAs',
        (WidgetTester tester) async {
      await pumpPaywall(
        tester,
        prefsOverrides: <String, Object>{
          kProgressPrefsKey: progressBlob(hasPro: true),
        },
      );

      expect(find.text('PRO activo'), findsOneWidget);
      expect(find.text('∞'), findsOneWidget);
      expect(find.text('Empezar 7 días gratis'), findsNothing);
    });

    testWidgets('purchase CTAs and restore stay at or above 48px tall',
        (WidgetTester tester) async {
      await pumpPaywall(tester);

      final Size ctaSize = tester.getSize(find.byType(KineticButton).first);
      expect(ctaSize.height, greaterThanOrEqualTo(48));

      await tester.scrollUntilVisible(
        find.widgetWithText(TextButton, 'Restaurar compras'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final Size restoreSize =
          tester.getSize(find.widgetWithText(TextButton, 'Restaurar compras'));
      expect(restoreSize.height, greaterThanOrEqualTo(48));
    });

    testWidgets('reduced motion keeps the paywall flow deterministic',
        (WidgetTester tester) async {
      await pumpPaywall(
        tester,
        prefsOverrides: <String, Object>{'signo.reducedMotion': true},
      );

      // KineticButton skips the press translation under reduced motion; the
      // purchase flow must still settle with no animation hang.
      await tester.tap(find.text('Empezar 7 días gratis'));
      await tester.pumpAndSettle();

      expect(find.text('PRO activo'), findsOneWidget);
    });

    testWidgets('large-text scaling reaches the paywall surface',
        (WidgetTester tester) async {
      await pumpPaywall(tester, textScaler: const TextScaler.linear(1.3));

      // The surface must inherit (never hard-pin) the app-wide scaler.
      final double scale = MediaQuery.textScalerOf(
        tester.element(find.text('Signo Premium')),
      ).scale(10);
      expect(scale, 13.0);
    });
  });
}
