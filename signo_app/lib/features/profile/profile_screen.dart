import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/settings/settings.dart';

/// Profile screen: anonymous local profile (name + emoji avatar) and the
/// accessibility toggles, persisted through the settings repository.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: ref.read(settingsProvider).profileName,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: kineticAppBar('Perfil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tu perfil', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Perfil anónimo guardado solo en este dispositivo.',
            style: textTheme.bodyMedium?.copyWith(
              color: KineticColors.textLow,
            ),
          ),
          const SizedBox(height: 16),
          Text('Nombre', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) => ref
                .read(settingsProvider.notifier)
                .updateProfile(name: value.trim()),
            decoration: InputDecoration(
              filled: true,
              fillColor: KineticColors.surfaceContainerMid,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KineticRadii.md),
                borderSide: const BorderSide(color: KineticColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KineticRadii.md),
                borderSide: const BorderSide(color: KineticColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(KineticRadii.md),
                borderSide: const BorderSide(color: KineticColors.mint),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Avatar', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List<Widget>.generate(kAvatarEmojis.length, (int index) {
              final bool selected = index == settings.avatarIndex;
              return GestureDetector(
                onTap: () => ref
                    .read(settingsProvider.notifier)
                    .updateProfile(avatarIndex: index),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: KineticColors.surfaceContainerMid,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? KineticColors.mint
                          : KineticColors.outline,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    kAvatarEmojis[index],
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text('Accesibilidad', style: textTheme.titleSmall),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Menos movimiento'),
            subtitle: Text(
              'Reduce las animaciones y transiciones de la app.',
              style: textTheme.bodyMedium?.copyWith(
                color: KineticColors.textLow,
              ),
            ),
            value: settings.reducedMotion,
            onChanged: (bool value) => ref
                .read(settingsProvider.notifier)
                .setReducedMotion(value),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: KineticColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(KineticRadii.lg),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Meta diaria: ${settings.dailyGoalMinutes} minutos',
                    style: textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
