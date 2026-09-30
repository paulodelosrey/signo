import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/lsc_vocab/lsc_vocab.dart';
import '../learn/curriculum.dart';
import '../learn/economy.dart';
import '../learn/lesson_screen.dart';
import '../learn/lesson_session.dart';

/// Práctica tab: hub of the two exercise types the app actually ships.
///
/// Product decision: only the two MVP exercise types are here (recognize /
/// match, over signs from completed lessons). Simón and Bingo were also listed,
/// disabled and badged "Próximamente"; they were removed rather than shipped
/// as dead cards. A tab offering two working exercises demos better than one
/// offering two working exercises and two promises — and an unimplemented
/// "Próximamente" card is a claim the code cannot back.
class PracticeHubScreen extends ConsumerWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final EconomyState progress = ref.watch(progressProvider);
    final AsyncValue<Curriculum> curriculum =
        ref.watch(curriculumProvider);
    final Curriculum? data = curriculum.value;

    // Signs from completed LESSON nodes (BOSS excluded), curriculum order.
    //
    // No video filter here on purpose: every sign in [pool] came out of
    // `curriculumProvider`, which is GATE A and is fed
    // `VocabIndex.videoEntries`. Re-filtering would be a second, drifting copy
    // of a gate that is already provably upstream; the invariant is locked by
    // buildExercises (GATE B) anyway, which filters `signs` and
    // `distractorPool` before an exercise is ever constructed.
    final List<VocabEntry> pool = <VocabEntry>[];
    if (data != null) {
      for (final PathNode node in data.allNodes) {
        if (!node.isBoss &&
            progress.completedNodeIds.contains(node.id)) {
          pool.addAll(node.signs);
        }
      }
    }
    final bool hasPool = pool.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        Text(
          'Elige un ejercicio',
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          hasPool
              ? 'Practicas con las señas de tus lecciones completadas.'
              : 'Completa lecciones en Aprender para desbloquear la práctica.',
          style: textTheme.bodyMedium?.copyWith(
            color: KineticColors.textLow,
          ),
        ),
        const SizedBox(height: 16),
        _ExerciseTypeCard(
          icon: Icons.visibility_outlined,
          title: 'Reconocer',
          subtitle: 'Mira la seña y elige la palabra correcta.',
          enabled: hasPool,
          onTap: () => _start(context, ref, pool,
              fixedType: ExerciseType.recognize),
        ),
        _ExerciseTypeCard(
          icon: Icons.style_outlined,
          title: 'Asociar',
          subtitle: 'Mira la palabra y elige la seña correcta.',
          enabled: hasPool,
          onTap: () =>
              _start(context, ref, pool, fixedType: ExerciseType.match),
        ),
      ],
    );
  }

  void _start(
    BuildContext context,
    WidgetRef ref,
    List<VocabEntry> pool, {
    required ExerciseType fixedType,
  }) {
    ref.read(sessionProvider.notifier).start(
          sampleEvenly(pool, kBossExerciseCap),
          fixedType: fixedType,
          distractorPool: pool,
        );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const LessonScreen(),
      ),
    );
  }
}

/// One hub card.
///
/// [enabled] is false when there is nothing to practise yet (no completed
/// lesson). The card stays rendered at full touch-target size, dimmed, so the
/// tab keeps its shape instead of reflowing when the user has no pool yet —
/// there is no badge on it: the card is real, it is just locked.
class _ExerciseTypeCard extends StatelessWidget {
  const _ExerciseTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: KineticColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(KineticRadii.lg),
          child: InkWell(
            borderRadius: BorderRadius.circular(KineticRadii.lg),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: KineticColors.surfaceContainerHigh,
                      borderRadius:
                          BorderRadius.circular(KineticRadii.md),
                    ),
                    child:
                        Icon(icon, color: KineticColors.mint, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: KineticColors.textLow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: enabled
                        ? KineticColors.textHigh
                        : KineticColors.textLow,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
