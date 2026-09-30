import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../widgets/kinetic_button.dart';
import 'economy.dart' show kChestGems;
import 'lesson_session.dart';

/// Lesson-end screen (spec `complete-lesson`): XP earned, precision %,
/// streak update, chest notice when a unit completes, and the Kinetic
/// "Continuar" action back to the learning path.
class LessonEndScreen extends ConsumerStatefulWidget {
  const LessonEndScreen({super.key});

  @override
  ConsumerState<LessonEndScreen> createState() => _LessonEndScreenState();
}

class _LessonEndScreenState extends ConsumerState<LessonEndScreen> {
  /// "Continuar" dismisses the session and pops. The dismissal makes
  /// [sessionProvider] null, which sends this very screen down its own
  /// "no result" branch — so without this guard the route pops twice and the
  /// shell underneath is torn down too, leaving a black screen.
  bool _popped = false;

  void _popOnce() {
    if (_popped) {
      return;
    }
    _popped = true;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final LessonSessionState? session = ref.watch(sessionProvider);
    final LessonResult? result = session?.result;
    if (result == null) {
      // No result (deep-link/restore edge) — nothing to show, go back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _popOnce();
        }
      });
      return const Scaffold(body: SizedBox.expand());
    }
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('🎉', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              Text(
                result.isRepasar ? '¡Repaso completado!' : '¡Lección completada!',
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              _ResultRow(
                icon: '⚡',
                label: 'XP ganados',
                value: '+${result.xpGained}',
              ),
              _ResultRow(
                icon: '🎯',
                label: 'Precisión',
                value: '${result.precisionPercent}%',
              ),
              _ResultRow(
                icon: '🔥',
                label: 'Racha',
                value: '${result.streak} ${result.streak == 1 ? 'día' : 'días'}',
              ),
              if (result.unitCompleted) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KineticColors.amber.withValues(alpha: 0.12),
                    border: Border.all(color: KineticColors.amber),
                    borderRadius: BorderRadius.circular(KineticRadii.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.redeem,
                        color: KineticColors.amber,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '¡Unidad completa! Reclama tu cofre de +$kChestGems 💎 en el mapa.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: KineticColors.textHigh,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (result.isRepasar) ...[
                const SizedBox(height: 8),
                Text(
                  'Tu lista de repaso quedó despejada.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: KineticColors.textLow,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              KineticButton(
                label: 'Continuar',
                expand: true,
                onPressed: () {
                  ref.read(sessionProvider.notifier).dismiss();
                  _popOnce();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One result line: emoji + label left, bold value right.
class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: textTheme.bodyLarge)),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: KineticColors.mint,
            ),
          ),
        ],
      ),
    );
  }
}
