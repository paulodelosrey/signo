import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed emoji list for the anonymous local profile avatar picker.
const List<String> kAvatarEmojis = <String>[
  '🐱', '🦄', '🐙', '🦊', '🐼', '🦉', '🐳', '🤖',
];

/// Daily goal choices offered during onboarding, in minutes per day.
const List<int> kDailyGoalChoices = <int>[5, 15, 20];

/// Immutable snapshot of the locally persisted app settings.
class AppSettings {
  const AppSettings({
    required this.onboardingSeen,
    required this.reducedMotion,
    required this.largeText,
    required this.dailyGoalMinutes,
    required this.profileName,
    required this.avatarIndex,
  });

  final bool onboardingSeen;
  final bool reducedMotion;

  /// Accessibility toggle: scales all text up app-wide (spec a11y
  /// font-scaling requirement; applied in the router's `builder`).
  final bool largeText;
  final int dailyGoalMinutes;
  final String profileName;
  final int avatarIndex;

  AppSettings copyWith({
    bool? onboardingSeen,
    bool? reducedMotion,
    bool? largeText,
    int? dailyGoalMinutes,
    String? profileName,
    int? avatarIndex,
  }) {
    return AppSettings(
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      largeText: largeText ?? this.largeText,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      profileName: profileName ?? this.profileName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.onboardingSeen == onboardingSeen &&
        other.reducedMotion == reducedMotion &&
        other.largeText == largeText &&
        other.dailyGoalMinutes == dailyGoalMinutes &&
        other.profileName == profileName &&
        other.avatarIndex == avatarIndex;
  }

  @override
  int get hashCode => Object.hash(
    onboardingSeen,
    reducedMotion,
    largeText,
    dailyGoalMinutes,
    profileName,
    avatarIndex,
  );
}

/// Key-value settings persistence on top of [SharedPreferences].
class SettingsRepository {
  SettingsRepository(this._prefs);

  static const String _kOnboardingSeen = 'signo.onboardingSeen';
  static const String _kReducedMotion = 'signo.reducedMotion';
  static const String _kLargeText = 'signo.largeText';
  static const String _kDailyGoalMinutes = 'signo.dailyGoalMinutes';
  static const String _kProfileName = 'signo.profileName';
  static const String _kAvatarIndex = 'signo.avatarIndex';

  final SharedPreferences _prefs;

  /// Reads the current settings, applying fresh-install defaults.
  AppSettings load() {
    final int avatarIndex = _prefs.getInt(_kAvatarIndex) ?? 0;
    return AppSettings(
      onboardingSeen: _prefs.getBool(_kOnboardingSeen) ?? false,
      reducedMotion: _prefs.getBool(_kReducedMotion) ?? false,
      largeText: _prefs.getBool(_kLargeText) ?? false,
      dailyGoalMinutes: _prefs.getInt(_kDailyGoalMinutes) ?? 15,
      profileName: _prefs.getString(_kProfileName) ?? 'Aprendiz',
      avatarIndex: avatarIndex.clamp(0, kAvatarEmojis.length - 1),
    );
  }

  Future<void> setOnboardingSeen(bool value) =>
      _prefs.setBool(_kOnboardingSeen, value);

  Future<void> setReducedMotion(bool value) =>
      _prefs.setBool(_kReducedMotion, value);

  Future<void> setLargeText(bool value) => _prefs.setBool(_kLargeText, value);

  Future<void> setDailyGoalMinutes(int minutes) =>
      _prefs.setInt(_kDailyGoalMinutes, minutes);

  Future<void> setProfile({String? name, int? avatarIndex}) async {
    if (name != null) {
      await _prefs.setString(_kProfileName, name);
    }
    if (avatarIndex != null) {
      await _prefs.setInt(_kAvatarIndex, avatarIndex);
    }
  }
}

/// Injectable [SharedPreferences] provider; overridden in `main` and tests.
final Provider<SharedPreferences> sharedPreferencesProvider = Provider<
  SharedPreferences
>((Ref ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden with a real instance.',
  );
});

/// Riverpod controller exposing [AppSettings] and write-through mutations.
class SettingsController extends Notifier<AppSettings> {
  SettingsRepository get _repository =>
      SettingsRepository(ref.watch(sharedPreferencesProvider));

  @override
  AppSettings build() => _repository.load();

  /// Stores the onboarding daily goal and marks onboarding as seen.
  Future<void> completeOnboarding({required int dailyGoalMinutes}) async {
    await _repository.setDailyGoalMinutes(dailyGoalMinutes);
    await _repository.setOnboardingSeen(true);
    state = _repository.load();
  }

  Future<void> setReducedMotion(bool value) async {
    await _repository.setReducedMotion(value);
    state = _repository.load();
  }

  Future<void> setLargeText(bool value) async {
    await _repository.setLargeText(value);
    state = _repository.load();
  }

  Future<void> setDailyGoalMinutes(int minutes) async {
    await _repository.setDailyGoalMinutes(minutes);
    state = _repository.load();
  }

  Future<void> updateProfile({String? name, int? avatarIndex}) async {
    await _repository.setProfile(name: name, avatarIndex: avatarIndex);
    state = _repository.load();
  }
}

/// Current app settings, shared app-wide.
final NotifierProvider<SettingsController, AppSettings> settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );
