import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/lsc_vocab/lsc_vocab.dart';
import '../../core/settings/settings.dart'
    show AppSettings, settingsProvider;
import '../../widgets/kinetic_button.dart';
import 'curriculum.dart';
import 'economy.dart';
import 'lesson_screen.dart';
import 'lesson_session.dart';
import 'repasar.dart';

/// Aprender tab: the 4-unit serpentine learning path.
///
/// Layout per the mockup: HUD pills (🔥 streak · 💎 gems · ❤️ hearts), the
/// static Repasar card when there are failed signs, then per unit a header
/// card (UNIDAD n + progress + chest) and a vertical path of 64px circular
/// nodes offset ±32px. Completed nodes show a mint check, the single active
/// node pulses with a "¡COMIENZA AQUÍ!" bubble, locked nodes are dimmed
/// locks, and each unit closes with an amber BOSS trophy.
class LearnTreeScreen extends ConsumerWidget {
  const LearnTreeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final EconomyState progress = ref.watch(progressProvider);
    final AsyncValue<Curriculum> curriculum =
        ref.watch(curriculumProvider);

    return curriculum.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: KineticColors.mint),
      ),
      error: (Object error, StackTrace _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se pudo cargar el contenido. Reintenta más tarde.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
      data: (Curriculum data) => _TreeBody(
        curriculum: data,
        progress: progress,
        vocabulary: ref.watch(vocabIndexProvider).value?.entries ??
            const <VocabEntry>[],
      ),
    );
  }
}

class _TreeBody extends ConsumerWidget {
  const _TreeBody({
    required this.curriculum,
    required this.progress,
    required this.vocabulary,
  });

  final Curriculum curriculum;
  final EconomyState progress;
  final List<VocabEntry> vocabulary;

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Delegates to the shared Repasar starter (same state/semantics as the
  /// Profile review entry); kept as a method so the card wiring is unchanged.
  void _startRepasar(BuildContext context, WidgetRef ref) {
    startRepasarSession(context, ref);
  }

  void _startNode(
    BuildContext context,
    WidgetRef ref, {
    required PathNode node,
    required List<VocabEntry> unitSigns,
  }) {
    if (!canStartLesson(progress)) {
      _showSnack(
        context,
        '¡Te quedaste sin corazones! Completa el Repaso para seguir aprendiendo.',
      );
      return;
    }
    ref.read(sessionProvider.notifier).start(
          node.signs,
          nodeId: node.id,
          isBoss: node.isBoss,
          distractorPool: unitSigns.length >= 4 ? unitSigns : vocabulary,
        );
    Navigator.of(context).push(_lessonRoute());
  }

  PageRouteBuilder<void> _lessonRoute() {
    return PageRouteBuilder<void>(
      transitionDuration: Duration.zero,
      pageBuilder: (_, _, _) => const LessonScreen(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<PathNode> allNodes = curriculum.allNodes;
    final List<PathNodeState> states =
        assignNodeStates(allNodes, progress.completedNodeIds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        _HudPills(progress: progress),
        if (progress.failedSignIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          _RepasarCard(
            failedCount: progress.failedSignIds.length,
            onStart: () => _startRepasar(context, ref),
          ),
        ],
        for (final CurriculumUnit unit in curriculum.units) ...[
          const SizedBox(height: 16),
          _UnitHeader(
            unit: unit,
            progress: progress,
            onClaimChest: () {
              ref
                  .read(progressProvider.notifier)
                  .claimChestForUnit(unit.number, unitComplete: true);
              _showSnack(context, '¡+$kChestGems 💎! Cofre reclamado.');
            },
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < unit.nodes.length; i++)
            _NodeRow(
              node: unit.nodes[i],
              state: states[allNodes.indexOf(unit.nodes[i])],
              offsetDx: unit.nodes[i].isBoss ? 0 : (i.isEven ? -32 : 32),
              showStartBubble: states[allNodes.indexOf(unit.nodes[i])] ==
                      PathNodeState.active &&
                  allNodes.indexOf(unit.nodes[i]) ==
                      allNodes.indexWhere(
                        (PathNode n) => !progress.completedNodeIds.contains(n.id),
                      ),
              unitSigns: unit.allSigns,
              onStart: () => _startNode(
                context,
                ref,
                node: unit.nodes[i],
                unitSigns: unit.allSigns,
              ),
              onLockedTap: () => _showSnack(
                context,
                'Completa las lecciones anteriores para desbloquear.',
              ),
              onCompletedTap: () => _showSnack(
                context,
                'Lección completada ✓',
              ),
            ),
        ],
        const SizedBox(height: 8),
        Text(
          'Contenido: MonikLSC L1–L5 · señas en video del abecedario, '
              'frases y acciones',
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(
            color: KineticColors.textLow,
          ),
        ),
      ],
    );
  }
}

/// Top HUD: streak / gems / hearts pills (mockup header).
class _HudPills extends StatelessWidget {
  const _HudPills({required this.progress});

  final EconomyState progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HudPill(label: '🔥 ${progress.streak}'),
        const SizedBox(width: 8),
        _HudPill(label: '💎 ${progress.gems}'),
        const SizedBox(width: 8),
        _HudPill(label: progress.hasPro ? '❤️ ∞' : '❤️ ${progress.hearts}'),
      ],
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: KineticColors.surfaceContainerLow,
          border: Border.all(color: KineticColors.outline),
          borderRadius: BorderRadius.circular(KineticRadii.pill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}

/// Static Repasar card: URGENTE badge + failed count + start button.
/// Launches a lesson-like session over the failed signs; completing it
/// clears the list.
class _RepasarCard extends StatelessWidget {
  const _RepasarCard({required this.failedCount, required this.onStart});

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

/// Unit header card: UNIDAD n, title, progress bar and the gem chest.
class _UnitHeader extends StatelessWidget {
  const _UnitHeader({
    required this.unit,
    required this.progress,
    required this.onClaimChest,
  });

  final CurriculumUnit unit;
  final EconomyState progress;
  final VoidCallback onClaimChest;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int completed = unit.nodes
        .where((PathNode node) => progress.completedNodeIds.contains(node.id))
        .length;
    final bool complete = unit.isComplete(progress.completedNodeIds);
    final bool claimed = progress.claimedChestUnits.contains(unit.number);
    final IconData chestIcon = claimed
        ? Icons.redeem
        : complete
            ? Icons.card_giftcard
            : Icons.inventory_2_outlined;
    final Color chestColor = claimed
        ? KineticColors.textLow
        : complete
            ? KineticColors.amber
            : KineticColors.textLow;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KineticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'UNIDAD ${unit.number}',
                  style: textTheme.labelMedium?.copyWith(
                    color: KineticColors.mint,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(unit.title, style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(KineticRadii.pill),
                        child: LinearProgressIndicator(
                          value:
                              unit.nodes.isEmpty ? 0 : completed / unit.nodes.length,
                          minHeight: 8,
                          backgroundColor: KineticColors.outline,
                          color: KineticColors.mint,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$completed/${unit.nodes.length}',
                      style: textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: claimed
                ? 'Cofre reclamado'
                : complete
                    ? 'Reclamar cofre de +$kChestGems 💎'
                    : 'Completa la unidad para abrir el cofre',
            onPressed: complete && !claimed ? onClaimChest : null,
            icon: Icon(chestIcon, color: chestColor, size: 28),
          ),
        ],
      ),
    );
  }
}

/// One path node on the serpentine: 64px circle over a darker 3D rim,
/// horizontally offset, with state visuals and the start bubble.
class _NodeRow extends ConsumerWidget {
  const _NodeRow({
    required this.node,
    required this.state,
    required this.offsetDx,
    required this.showStartBubble,
    required this.unitSigns,
    required this.onStart,
    required this.onLockedTap,
    required this.onCompletedTap,
  });

  final PathNode node;
  final PathNodeState state;
  final double offsetDx;
  final bool showStartBubble;
  final List<VocabEntry> unitSigns;
  final VoidCallback onStart;
  final VoidCallback onLockedTap;
  final VoidCallback onCompletedTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: showStartBubble ? 108 : 84,
      child: Center(
        child: Transform.translate(
          offset: Offset(offsetDx, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showStartBubble) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: KineticColors.mint,
                    borderRadius: BorderRadius.circular(KineticRadii.pill),
                  ),
                  child: Text(
                    '¡COMIENZA AQUÍ!',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: KineticColors.onMint,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              _PathNodeButton(
                node: node,
                state: state,
                onTap: switch (state) {
                  PathNodeState.active => onStart,
                  PathNodeState.locked => onLockedTap,
                  PathNodeState.completed => onCompletedTap,
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The 64px circular node button with its rim and per-state visuals.
class _PathNodeButton extends ConsumerStatefulWidget {
  const _PathNodeButton({
    required this.node,
    required this.state,
    required this.onTap,
  });

  final PathNode node;
  final PathNodeState state;
  final VoidCallback onTap;

  @override
  ConsumerState<_PathNodeButton> createState() => _PathNodeButtonState();
}

class _PathNodeButtonState extends ConsumerState<_PathNodeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 0.5,
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reducedMotion =
        ref.watch(settingsReducedMotionProvider) ||
        MediaQuery.disableAnimationsOf(context);
    final bool pulsing =
        widget.state == PathNodeState.active && !reducedMotion;
    if (pulsing && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!pulsing && _pulse.isAnimating) {
      _pulse.stop();
    }

    final bool isBoss = widget.node.isBoss;
    final (Color face, Color rim, Color icon, IconData iconData) =
        switch (widget.state) {
      PathNodeState.completed when !isBoss => (
          KineticColors.mint,
          KineticColors.mintRim,
          KineticColors.onMint,
          Icons.check,
        ),
      PathNodeState.completed => (
          KineticColors.amber,
          KineticColors.amber.withValues(alpha: 0.5),
          KineticColors.onAmber,
          Icons.emoji_events,
        ),
      PathNodeState.active when !isBoss => (
          KineticColors.mint,
          KineticColors.mintRim,
          KineticColors.onMint,
          Icons.play_arrow,
        ),
      PathNodeState.active => (
          KineticColors.amber,
          KineticColors.amber,
          KineticColors.onAmber,
          Icons.emoji_events,
        ),
      PathNodeState.locked when !isBoss => (
          KineticColors.surfaceContainerHigh,
          KineticColors.outline,
          KineticColors.textLow,
          Icons.lock,
        ),
      PathNodeState.locked => (
          KineticColors.surfaceContainerHigh,
          KineticColors.outline,
          KineticColors.textLow,
          Icons.emoji_events,
        ),
    };

    Widget button = GestureDetector(
      onTap: widget.onTap,
      child: Opacity(
        opacity: widget.state == PathNodeState.locked ? 0.65 : 1.0,
        child: Semantics(
          button: true,
          label: '${widget.node.title} (${widget.state.name})',
          child: Container(
            width: 64,
            height: 68,
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: rim,
              shape: BoxShape.circle,
              boxShadow: isBoss && widget.state != PathNodeState.locked
                  ? <BoxShadow>[
                      BoxShadow(
                        color: KineticColors.amber.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Container(
              decoration: BoxDecoration(color: rim, shape: BoxShape.circle),
              child: ClipOval(
                child: ColoredBox(
                  color: face,
                  child: Center(
                    child: Icon(iconData, color: icon, size: 30),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (pulsing) {
      button = ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.06).animate(
          CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
        ),
        child: button,
      );
    }
    return button;
  }
}

/// Reduced-motion setting exposed as a plain provider so widgets can watch
/// it without pulling the whole settings object.
final Provider<bool> settingsReducedMotionProvider = Provider<bool>(
  (Ref ref) => ref.watch(settingsProvider.select((AppSettings s) => s.reducedMotion)),
);
