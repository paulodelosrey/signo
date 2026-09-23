import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signo_app/core/settings/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepository', () {
    test('load() returns fresh-install defaults on empty prefs', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SettingsRepository repository = SettingsRepository(
        await SharedPreferences.getInstance(),
      );

      final AppSettings settings = repository.load();

      expect(settings.onboardingSeen, isFalse,
          reason: 'first launch must show the onboarding gate');
      expect(settings.reducedMotion, isFalse);
      expect(settings.dailyGoalMinutes, 15);
      expect(settings.profileName, 'Aprendiz');
      expect(settings.avatarIndex, 0);
    });

    test('persists and reloads every field', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SettingsRepository repository = SettingsRepository(
        await SharedPreferences.getInstance(),
      );

      await repository.setOnboardingSeen(true);
      await repository.setReducedMotion(true);
      await repository.setDailyGoalMinutes(5);
      await repository.setProfile(name: 'Moni', avatarIndex: 3);

      final AppSettings settings = repository.load();

      expect(settings.onboardingSeen, isTrue);
      expect(settings.reducedMotion, isTrue);
      expect(settings.dailyGoalMinutes, 5);
      expect(settings.profileName, 'Moni');
      expect(settings.avatarIndex, 3);
    });

    test('clamps an out-of-range avatarIndex into the fixed list', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'signo.avatarIndex': 99,
        'signo.profileName': 'X',
      });
      final SettingsRepository repository = SettingsRepository(
        await SharedPreferences.getInstance(),
      );

      final AppSettings settings = repository.load();

      expect(settings.avatarIndex, kAvatarEmojis.length - 1);
    });
  });
}
