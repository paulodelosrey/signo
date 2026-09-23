import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/settings/settings.dart';
import '../../widgets/kinetic_button.dart';
import '../learn/economy.dart';
import '../learn/repasar.dart';

/// Profile screen: anonymous local profile (name + emoji avatar), the
/// learning stats surfaced from the progress store (XP, streak, gems,
/// hearts/∞ PRO), the Repasar entry point (shared semantics with the
/// Aprender tree card) and the accessibility toggles, all persisted through
/// the settings/progress repositories.
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
    final EconomyState progress = ref.watch(progressProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: kineticAppBar('Perfil'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tu progreso', style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          _StatsGrid(progress: progress),
          if (progress.failedSignIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            _RepasarEntry(
              failedCount: progress.failedSignIds.length,
              onStart: () => startRepasarSession(context, ref),
            ),
          ],
          const SizedBox(height: 20),
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Texto grande'),
            subtitle: Text(
              'Aumenta el tamaño del texto en toda la app.',
              style: textTheme.bodyMedium?.copyWith(
                color: KineticColors.textLow,
              ),
            ),
            value: settings.largeText,
            onChanged: (bool value) =>
                ref.read(settingsProvider.notifier).setLargeText(value),
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

/// Learning stats from the progress store: 2×2 tiles mirroring the Aprender
/// HUD (streak · gems · XP · hearts). PRO shows infinite hearts and a badge.
class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.progress});

  final EconomyState progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                emoji: '🔥',
                value: '${progress.streak}',
                label: 'Racha',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                emoji: '💎',
                value: '${progress.gems}',
                label: 'Gemas',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                emoji: '⭐',
                value: '${progress.xp}',
                label: 'XP',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                emoji: '❤️',
                value: progress.hasPro ? '∞' : '${progress.hearts}',
                label: 'Corazones',
                badge: progress.hasPro ? 'PRO' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One read-only stat tile (no tap target, so the 48px rule does not apply).
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.emoji,
    required this.value,
    required this.label,
    this.badge,
  });

  final String emoji;
  final String value;
  final String label;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KineticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
        border: Border.all(color: KineticColors.outline),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: KineticColors.amber,
                    borderRadius: BorderRadius.circular(KineticRadii.pill),
                  ),
                  child: Text(
                    badge!,
                    style: textTheme.labelSmall?.copyWith(
                      color: KineticColors.onAmber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: KineticColors.textLow,
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile Repasar entry: same card semantics as the Aprender tree card
/// (URGENTE badge + failed count + start button) driven by the SAME shared
/// starter — no duplicated session logic.
class _RepasarEntry extends StatelessWidget {
  const _RepasarEntry({required this.failedCount, required this.onStart});

  final int failedCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KineticColors.errorContainer,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: KineticColors.error,
                  borderRadius: BorderRadius.circular(KineticRadii.pill),
                ),
                child: Text(
                  'URGENTE',
                  style: textTheme.labelSmall?.copyWith(
                    color: KineticColors.onError,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$failedCount ${failedCount == 1 ? 'seña fallida' : 'señas fallidas'}',
                  style: textTheme.titleSmall?.copyWith(
                    color: KineticColors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          KineticButton(
            label: 'Repasar ahora',
            variant: KineticButtonVariant.secondary,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}
