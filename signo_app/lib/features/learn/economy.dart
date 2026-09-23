import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/settings/settings.dart' show sharedPreferencesProvider;

/// Economy tuning constants (spec `economy`: simplified — no refills, no
/// timers, no store).
const int kInitialHearts = 5;
const int kXpPerLesson = 10;
const int kChestGems = 50;

/// Streak bonus caps at one week so missing one day never feels hopeless.
const int kStreakBonusCap = 7;

/// Persistence key for the whole progress blob.
const String kProgressPrefsKey = 'signo.progress.v1';

/// Immutable snapshot of learning progress + economy.
///
/// `hasPro` is the M6 monetization seam: when RevenueCat grants the `pro`
/// entitlement the controller flips this flag and hearts become infinite —
/// no other rule changes.
class EconomyState {
  const EconomyState({
    required this.hearts,
    required this.xp,
    required this.gems,
    required this.streak,
    required this.lastPlayedOn,
    required this.failedSignIds,
    required this.completedNodeIds,
    required this.claimedChestUnits,
    required this.hasPro,
  });

  final int hearts;
  final int xp;
  final int gems;

  /// Consecutive-day practice count; 0 until the first session completes.
  final int streak;

  /// Local date key (`yyyy-MM-dd`) of the last completed session.
  final String? lastPlayedOn;

  /// Gloss sign ids answered wrong (seeds the static Repasar card).
  final List<String> failedSignIds;

  /// Path node ids completed (`u1-l1`, `u2-boss`, ...).
  final Set<String> completedNodeIds;

  /// Unit numbers whose gem chest has been claimed.
  final Set<int> claimedChestUnits;

  /// PRO seam (M6): RevenueCat entitlement → infinite hearts.
  final bool hasPro;

  EconomyState copyWith({
    int? hearts,
    int? xp,
    int? gems,
    int? streak,
    String? lastPlayedOn,
    bool clearLastPlayed = false,
    List<String>? failedSignIds,
    Set<String>? completedNodeIds,
    Set<int>? claimedChestUnits,
    bool? hasPro,
  }) {
    return EconomyState(
      hearts: hearts ?? this.hearts,
      xp: xp ?? this.xp,
      gems: gems ?? this.gems,
      streak: streak ?? this.streak,
      lastPlayedOn: clearLastPlayed ? null : (lastPlayedOn ?? this.lastPlayedOn),
      failedSignIds: failedSignIds ?? this.failedSignIds,
      completedNodeIds: completedNodeIds ?? this.completedNodeIds,
      claimedChestUnits: claimedChestUnits ?? this.claimedChestUnits,
      hasPro: hasPro ?? this.hasPro,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'hearts': hearts,
        'xp': xp,
        'gems': gems,
        'streak': streak,
        'lastPlayedOn': lastPlayedOn,
        'failedSignIds': failedSignIds,
        'completedNodeIds': completedNodeIds.toList(),
        'claimedChestUnits': claimedChestUnits.toList(),
        'hasPro': hasPro,
      };

  factory EconomyState.fromJson(Map<String, Object?> json) => EconomyState(
        hearts: (json['hearts']! as num).toInt(),
        xp: (json['xp']! as num).toInt(),
        gems: (json['gems']! as num).toInt(),
        streak: (json['streak']! as num).toInt(),
        lastPlayedOn: json['lastPlayedOn'] as String?,
        failedSignIds:
            (json['failedSignIds']! as List<Object?>).cast<String>(),
        completedNodeIds: (json['completedNodeIds']! as List<Object?>)
            .cast<String>()
            .toSet(),
        claimedChestUnits: (json['claimedChestUnits']! as List<Object?>)
            .map((Object? e) => (e! as num).toInt())
            .toSet(),
        hasPro: json['hasPro']! as bool,
      );
}

/// Fresh-install state.
EconomyState freshEconomyState() => EconomyState(
      hearts: kInitialHearts,
      xp: 0,
      gems: 0,
      streak: 0,
      lastPlayedOn: null,
      failedSignIds: <String>[],
      completedNodeIds: <String>{},
      claimedChestUnits: <int>{},
      hasPro: false,
    );

// ---------------------------------------------------------------------------
// Pure economy rules — unit-tested without prefs or widgets.
// ---------------------------------------------------------------------------

/// Local date key with zero-padding (`2026-09-25`). Never UTC: streaks must
/// follow the user's wall clock.
String localDateKey(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

int _daysBetweenKeys(String a, String b) {
  final DateTime dateA = DateTime.parse('${a}T00:00:00.000');
  final DateTime dateB = DateTime.parse('${b}T00:00:00.000');
  return dateB.difference(dateA).inDays;
}

/// XP granted on top of a lesson: one bonus point per streak day, capped.
int streakBonus(int streak) =>
    streak < kStreakBonusCap ? streak : kStreakBonusCap;

/// Hearts gate (spec `hearts-gate`): a lesson starts only with hearts left,
/// unless PRO grants infinite hearts.
bool canStartLesson(EconomyState state) => state.hasPro || state.hearts > 0;

/// Wrong answer: −1 heart (floored at 0) and the sign joins the failed list
/// (deduped). PRO players lose nothing — infinite hearts.
EconomyState applyWrongAnswer(EconomyState state, String signId) {
  final EconomyState seeded = state.failedSignIds.contains(signId)
      ? state
      : state.copyWith(
          failedSignIds: <String>[...state.failedSignIds, signId]);
  if (state.hasPro) {
    return seeded;
  }
  return seeded.copyWith(hearts: state.hearts > 0 ? state.hearts - 1 : 0);
}

/// Session completed: streak rolls daily (same day keeps the count, next day
/// increments, any gap resets to 1) and XP = base + streak bonus of the NEW
/// streak. Optionally marks a path node complete and/or clears the failed
/// list (Repasar flow).
EconomyState applySessionComplete(
  EconomyState state, {
  String? completedNodeId,
  required String todayKey,
  bool clearsFailedSigns = false,
}) {
  final String? last = state.lastPlayedOn;
  final int streak;
  if (last == null) {
    streak = 1;
  } else if (last == todayKey) {
    streak = state.streak;
  } else if (_daysBetweenKeys(last, todayKey) == 1) {
    streak = state.streak + 1;
  } else {
    streak = 1;
  }
  return state.copyWith(
    xp: state.xp + kXpPerLesson + streakBonus(streak),
    streak: streak,
    lastPlayedOn: todayKey,
    completedNodeIds: completedNodeId == null
        ? null
        : <String>{...state.completedNodeIds, completedNodeId},
    failedSignIds: clearsFailedSigns ? <String>[] : null,
  );
}

/// Claims a unit's gem chest: +[kChestGems] gems, exactly once, and only
/// when the unit is actually complete.
EconomyState claimChest(
  EconomyState state,
  int unitNumber, {
  required bool unitComplete,
}) {
  if (!unitComplete || state.claimedChestUnits.contains(unitNumber)) {
    return state;
  }
  return state.copyWith(
    gems: state.gems + kChestGems,
    claimedChestUnits: <int>{...state.claimedChestUnits, unitNumber},
  );
}

// ---------------------------------------------------------------------------
// Persistence (shared_preferences, one JSON blob — design decision: small KV).
// ---------------------------------------------------------------------------

/// Loads/saves [EconomyState] on [SharedPreferences].
class ProgressRepository {
  ProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  /// Reads progress, falling back to a fresh-install state on corrupt or
  /// missing data (never crashes the app on a bad blob).
  EconomyState load() {
    final String? raw = _prefs.getString(kProgressPrefsKey);
    if (raw == null) {
      return freshEconomyState();
    }
    try {
      return EconomyState.fromJson(
        jsonDecode(raw)! as Map<String, Object?>,
      );
    } on FormatException {
      return freshEconomyState();
    } on TypeError {
      return freshEconomyState();
    }
  }

  Future<void> save(EconomyState state) =>
      _prefs.setString(kProgressPrefsKey, jsonEncode(state.toJson()));
}

/// Riverpod controller: exposes the current [EconomyState] and persists
/// every mutation write-through.
class ProgressController extends Notifier<EconomyState> {
  ProgressRepository get _repository =>
      ProgressRepository(ref.watch(sharedPreferencesProvider));

  @override
  EconomyState build() => _repository.load();

  Future<void> _persist(EconomyState next) async {
    state = next;
    await _repository.save(next);
  }

  /// PRO seam (M6): RevenueCat entitlement callback flips infinite hearts.
  Future<void> setPro(bool value) =>
      _persist(state.copyWith(hasPro: value));

  Future<void> registerWrongAnswer(String signId) =>
      _persist(applyWrongAnswer(state, signId));

  Future<void> completeSession({
    String? completedNodeId,
    bool clearsFailedSigns = false,
  }) {
    return _persist(applySessionComplete(
      state,
      completedNodeId: completedNodeId,
      todayKey: localDateKey(DateTime.now()),
      clearsFailedSigns: clearsFailedSigns,
    ));
  }

  Future<void> claimChestForUnit(
    int unitNumber, {
    required bool unitComplete,
  }) =>
      _persist(claimChest(state, unitNumber, unitComplete: unitComplete));
}

/// Current learning progress, shared app-wide (HUD, tree, lesson flow).
final NotifierProvider<ProgressController, EconomyState> progressProvider =
    NotifierProvider<ProgressController, EconomyState>(
      ProgressController.new,
    );
