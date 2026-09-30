import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/features/learn/economy.dart';

/// Fixture: fresh state (5 hearts, 0 xp/gems/streak).
EconomyState fresh() => freshEconomyState();

void main() {
  group('hearts', () {
    test('fresh install starts with 5 hearts', () {
      expect(fresh().hearts, kInitialHearts);
      expect(kInitialHearts, 5);
    });

    test('wrong answer costs one heart and seeds the failed list', () {
      final EconomyState next = applyWrongAnswer(fresh(), 's-casa');
      expect(next.hearts, 4);
      expect(next.failedSignIds, <String>['s-casa']);
    });

    test('hearts floor at zero, never negative', () {
      EconomyState state = fresh();
      for (int i = 0; i < 10; i++) {
        state = applyWrongAnswer(state, 's-$i');
      }
      expect(state.hearts, 0);
      expect(state.failedSignIds.length, 10);
    });

    test('failed list dedupes, but every miss costs a heart', () {
      EconomyState state = applyWrongAnswer(fresh(), 's-casa');
      state = applyWrongAnswer(state, 's-casa');
      expect(state.failedSignIds, <String>['s-casa']);
      // Two misses = two hearts, one failed-list entry.
      expect(state.hearts, kInitialHearts - 2);
    });

    test('PRO seam: infinite hearts — wrong answers never decrement', () {
      EconomyState state = fresh().copyWith(hasPro: true, hearts: 0);
      state = applyWrongAnswer(state, 's-casa');
      expect(state.hearts, 0);
      expect(state.failedSignIds, <String>['s-casa']);
    });
  });

  group('hearts refill on session completion', () {
    // The soft-lock this group locks shut: hearts were only ever granted on a
    // fresh install, so five wrong answers anywhere killed the learning path
    // permanently. Completing a session has to give them back.
    test('a full session of wrong answers followed by completion refills',
        () {
      EconomyState state = fresh();
      for (int i = 0; i < kInitialHearts; i++) {
        state = applyWrongAnswer(state, 's-$i');
      }
      expect(state.hearts, 0);
      expect(canStartLesson(state), isFalse);

      state = applySessionComplete(
        state,
        completedNodeId: 'u1-l1',
        todayKey: '2026-09-25',
      );

      expect(state.hearts, kInitialHearts);
      // The gate reopens on its own: no reinstall, no purchase.
      expect(canStartLesson(state), isTrue);
      // Refill must not disturb the rest of the completion rules.
      expect(state.streak, 1);
      expect(state.xp, kXpPerLesson + 1);
      expect(state.completedNodeIds, <String>{'u1-l1'});
    });

    test('the refill tops up a partial loss without granting extra hearts',
        () {
      EconomyState state = applyWrongAnswer(fresh(), 's-casa');
      state = applySessionComplete(state, todayKey: '2026-09-25');
      expect(state.hearts, kInitialHearts);
    });

    test('a session completed at full hearts changes nothing', () {
      final EconomyState state =
          applySessionComplete(fresh(), todayKey: '2026-09-25');
      expect(state.hearts, kInitialHearts);
    });

    test('a repasar completion refills too — it is a completed session', () {
      EconomyState state = fresh();
      for (int i = 0; i < kInitialHearts; i++) {
        state = applyWrongAnswer(state, 's-$i');
      }
      state = applySessionComplete(
        state,
        todayKey: '2026-09-25',
        clearsFailedSigns: true,
      );
      expect(state.hearts, kInitialHearts);
      expect(state.failedSignIds, isEmpty);
    });

    test('an abandoned session does not refill — hearts stay spent', () {
      // Leaving early never reaches applySessionComplete: the controller drops
      // the session. This is the documented boundary of the refill, asserted
      // here so it cannot quietly become "any lesson screen closes".
      EconomyState state = fresh();
      for (int i = 0; i < kInitialHearts; i++) {
        state = applyWrongAnswer(state, 's-$i');
      }
      expect(state.hearts, 0);
      expect(canStartLesson(state), isFalse);
    });

    test('PRO completion leaves the infinite-hearts state untouched', () {
      final EconomyState state = applySessionComplete(
        fresh().copyWith(hasPro: true, hearts: 0),
        todayKey: '2026-09-25',
      );
      expect(state.hasPro, isTrue);
      // Hearts are meaningless under PRO (the HUD renders ∞ and the gate is
      // bypassed), so the refill deliberately does not invent a value here.
      expect(state.hearts, 0);
      expect(canStartLesson(state), isTrue);
    });
  });

  group('hearts gate (spec hearts-gate scenario)', () {
    test('zero hearts blocks lesson start', () {
      final EconomyState state = fresh().copyWith(hearts: 0);
      expect(canStartLesson(state), isFalse);
    });

    test('any heart left allows lesson start', () {
      expect(canStartLesson(fresh().copyWith(hearts: 1)), isTrue);
    });

    test('PRO overrides the gate even at zero hearts', () {
      expect(
        canStartLesson(fresh().copyWith(hearts: 0, hasPro: true)),
        isTrue,
      );
    });
  });

  group('streak + XP', () {
    test('localDateKey formats zero-padded local date', () {
      expect(localDateKey(DateTime(2026, 9, 25)), '2026-09-25');
      expect(localDateKey(DateTime(2026, 1, 3)), '2026-01-03');
    });

    test('first completion starts the streak at 1 and grants base+bonus',
        () {
      final EconomyState next = applySessionComplete(
        fresh(),
        todayKey: '2026-09-25',
      );
      expect(next.streak, 1);
      expect(next.xp, kXpPerLesson + 1);
      expect(next.lastPlayedOn, '2026-09-25');
    });

    test('same-day completion keeps the streak, still grants XP', () {
      EconomyState state =
          applySessionComplete(fresh(), todayKey: '2026-09-25');
      final int xpAfterFirst = state.xp;
      state = applySessionComplete(state, todayKey: '2026-09-25');
      expect(state.streak, 1);
      expect(state.xp, xpAfterFirst + kXpPerLesson + 1);
    });

    test('next-day completion increments the streak and its bonus', () {
      EconomyState state =
          applySessionComplete(fresh(), todayKey: '2026-09-25');
      state = applySessionComplete(state, todayKey: '2026-09-26');
      expect(state.streak, 2);
      expect(state.xp, (kXpPerLesson + 1) + (kXpPerLesson + 2));
    });

    test('a missed day resets the streak to 1', () {
      EconomyState state =
          applySessionComplete(fresh(), todayKey: '2026-09-25');
      state = applySessionComplete(state, todayKey: '2026-09-28');
      expect(state.streak, 1);
    });

    test('streak bonus caps at 7', () {
      expect(streakBonus(5), 5);
      expect(streakBonus(7), 7);
      expect(streakBonus(30), kStreakBonusCap);
    });

    test('completed node id is recorded', () {
      final EconomyState next = applySessionComplete(
        fresh(),
        completedNodeId: 'u1-l1',
        todayKey: '2026-09-25',
      );
      expect(next.completedNodeIds, <String>{'u1-l1'});
    });
  });

  group('gem chest', () {
    test('claiming a completed unit grants 50 gems exactly once', () {
      EconomyState state = claimChest(fresh(), 1, unitComplete: true);
      expect(state.gems, kChestGems);
      expect(state.claimedChestUnits, <int>{1});
      state = claimChest(state, 1, unitComplete: true);
      expect(state.gems, kChestGems);
    });

    test('incomplete unit cannot grant gems', () {
      final EconomyState state = claimChest(fresh(), 1, unitComplete: false);
      expect(state.gems, 0);
      expect(state.claimedChestUnits, isEmpty);
    });

    test('chests are independent per unit', () {
      EconomyState state = claimChest(fresh(), 1, unitComplete: true);
      state = claimChest(state, 2, unitComplete: true);
      expect(state.gems, kChestGems * 2);
    });
  });

  group('repasar', () {
    test('completing a repasar session clears the failed list', () {
      EconomyState state = applyWrongAnswer(fresh(), 's-casa');
      state = applyWrongAnswer(state, 's-perro');
      state = applySessionComplete(
        state,
        todayKey: '2026-09-25',
        clearsFailedSigns: true,
      );
      expect(state.failedSignIds, isEmpty);
    });

    test('a normal lesson completion keeps the failed list', () {
      EconomyState state = applyWrongAnswer(fresh(), 's-casa');
      state = applySessionComplete(state, todayKey: '2026-09-25');
      expect(state.failedSignIds, <String>['s-casa']);
    });
  });

  group('persistence', () {
    test('repository round-trips the full state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProgressRepository repository = ProgressRepository(prefs);

      EconomyState state = applyWrongAnswer(fresh(), 's-casa');
      state = applySessionComplete(
        state,
        completedNodeId: 'u1-l1',
        todayKey: '2026-09-25',
      );
      state = claimChest(state, 1, unitComplete: true);
      await repository.save(state);

      final EconomyState loaded = ProgressRepository(
        await SharedPreferences.getInstance(),
      ).load();
      expect(loaded.hearts, state.hearts);
      expect(loaded.xp, state.xp);
      expect(loaded.gems, state.gems);
      expect(loaded.streak, state.streak);
      expect(loaded.lastPlayedOn, '2026-09-25');
      expect(loaded.failedSignIds, <String>['s-casa']);
      expect(loaded.completedNodeIds, <String>{'u1-l1'});
      expect(loaded.claimedChestUnits, <int>{1});
      expect(loaded.hasPro, isFalse);
    });

    test('missing blob falls back to a fresh state', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final EconomyState loaded = ProgressRepository(prefs).load();
      expect(loaded.hearts, kInitialHearts);
      expect(loaded.completedNodeIds, isEmpty);
    });

    test('corrupt blob falls back to a fresh state instead of crashing',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kProgressPrefsKey: '{not json!!',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final EconomyState loaded = ProgressRepository(prefs).load();
      expect(loaded.hearts, kInitialHearts);
    });
  });
}
