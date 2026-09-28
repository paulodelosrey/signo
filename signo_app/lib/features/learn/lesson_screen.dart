import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/lsc_vocab/lsc_vocab.dart';
import '../../widgets/kinetic_button.dart';
import '../../widgets/sign_video_player.dart';
import 'curriculum.dart' show displayWordFor;
import 'lesson_end_screen.dart';
import 'lesson_session.dart';

/// Renders one sign: its bundled video clip, or the text-mode card.
///
/// VIDEO MODE (T4): when curation fills `asset` with `hasVideo == true` the
/// clip is played through [SignVideoPlayer] inside the very same Kinetic
/// surface. Every entry still has `hasVideo == false` today, so exercises
/// render in TEXT MODE — a big kinetic card carrying the gloss label styled as
/// the video placeholder, with a subtle "video en curaduría" note. A declared
/// clip that is missing at runtime also falls back to that same text mode.
class SignView extends StatelessWidget {
  const SignView({super.key, required this.entry, this.compact = false});

  final VocabEntry entry;

  /// Compact variant for match-exercise option cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String? asset = entry.asset;
    // Text mode is the fallback AND the current default: it stays byte-for-byte
    // what it was before the video player existed.
    final Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sign_language,
          size: compact ? 28 : 44,
          color: KineticColors.iris,
        ),
        SizedBox(height: compact ? 6 : 12),
        Text(
          entry.gloss,
          textAlign: TextAlign.center,
          style: (compact ? textTheme.titleLarge : textTheme.headlineMedium)
              ?.copyWith(
            color: KineticColors.textHigh,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 13,
              color: KineticColors.textLow,
            ),
            const SizedBox(width: 4),
            Text(
              'video en curaduría',
              style: textTheme.labelSmall?.copyWith(
                color: KineticColors.textLow,
              ),
            ),
          ],
        ),
      ],
    );

    final Widget face = Container(
      width: double.infinity,
      height: compact ? null : 220,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: KineticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
      ),
      // The clip is confined to the same padded box, so the surface height
      // (220 prompt / grid cell compact) and the Kinetic tokens are
      // untouched. Missing asset => SignVideoPlayer renders `content`.
      child: entry.hasVideo && asset != null
          ? SignVideoPlayer(
              key: ValueKey<String>(asset),
              assetPath: asset,
              fallback: content,
              autoplay: !compact,
            )
          : content,
    );

    // Compact cards fill their grid cell; the prompt card keeps a fixed
    // height so the layout does not jump between exercises.
    return compact
        ? Container(
            decoration: BoxDecoration(
              color: KineticColors.outline,
              borderRadius: BorderRadius.circular(KineticRadii.lg),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KineticRadii.lg - 2),
              child: face,
            ),
          )
        : Container(
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: KineticColors.outline,
              borderRadius: BorderRadius.circular(KineticRadii.lg),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KineticRadii.lg - 2),
              child: face,
            ),
          );
  }
}

/// Full-screen lesson flow: ordered exercises, n/n progress dots, exit
/// confirmation, and inline feedback with heart penalties.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _pushedEnd = false;

  Future<bool?> _confirmExit() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        backgroundColor: KineticColors.surfaceContainerMid,
        title: const Text('¿Salir de la lección?'),
        content: const Text(
          'Perderás el progreso de esta lección y los corazones ya gastados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir aquí'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  Future<void> _onExitRequested() async {
    final bool? exit = await _confirmExit();
    if (exit == true && mounted) {
      ref.read(sessionProvider.notifier).dismiss();
      Navigator.of(context).pop();
    }
  }

  void _onSessionFinished() {
    if (_pushedEnd) {
      return;
    }
    _pushedEnd = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => const LessonEndScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final LessonSessionState? session = ref.watch(sessionProvider);
    if (session == null) {
      // Session dropped underneath us (exit or completion) — go back.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(body: SizedBox.expand());
    }
    if (session.result != null) {
      _onSessionFinished();
    }

    final Exercise? exercise = session.current;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        _onExitRequested();
      },
      child: Scaffold(
        body: SafeArea(
          child: session.finished || exercise == null
              ? const SizedBox.expand()
              : Column(
                  children: [
                    _LessonHeader(
                      session: session,
                      onExit: _onExitRequested,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: _ExerciseBody(
                          key: ValueKey<int>(session.index),
                          exercise: exercise,
                          session: session,
                        ),
                      ),
                    ),
                    _FeedbackBar(session: session),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Close button + n/n progress dots.
class _LessonHeader extends StatelessWidget {
  const _LessonHeader({required this.session, required this.onExit});

  final LessonSessionState session;
  final Future<void> Function() onExit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Salir de la lección',
            onPressed: () => onExit(),
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                for (int i = 0; i < session.total; i++)
                  Expanded(
                    child: Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: i < session.index
                            ? KineticColors.mint
                            : i == session.index
                                ? KineticColors.iris
                                : KineticColors.outline,
                        borderRadius:
                            BorderRadius.circular(KineticRadii.pill),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${session.index + 1}/${session.total}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      ),
    );
  }
}

/// The current exercise: recognize (sign card → 4 words) or match (word →
/// 4 sign cards), with per-option answer feedback styling.
class _ExerciseBody extends ConsumerWidget {
  const _ExerciseBody({super.key, required this.exercise, required this.session});

  final Exercise exercise;
  final LessonSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? selected = session.selectedOption;

    final Widget prompt = exercise.type == ExerciseType.recognize
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Qué palabra significa esta seña?',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SignView(entry: exercise.entry),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '¿Cuál es la seña de «${displayWordFor(exercise.entry)}»?',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          );

    final Widget options = exercise.type == ExerciseType.recognize
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (int i = 0; i < exercise.options.length; i++)
                _WordOption(
                  label: displayWordFor(exercise.options[i]),
                  state: _optionState(i, selected, exercise),
                  onTap:
                      selected == null ? () => _answer(context, ref, i) : null,
                ),
            ],
          )
        : GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: <Widget>[
              for (int i = 0; i < exercise.options.length; i++)
                _SignOption(
                  entry: exercise.options[i],
                  state: _optionState(i, selected, exercise),
                  onTap:
                      selected == null ? () => _answer(context, ref, i) : null,
                ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        prompt,
        const SizedBox(height: 16),
        options,
      ],
    );
  }

  void _answer(BuildContext context, WidgetRef ref, int optionIndex) {
    ref.read(sessionProvider.notifier).answer(optionIndex);
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

_OptionState _optionState(int index, int? selected, Exercise exercise) {
  final int? chosen = selected;
  if (chosen == null) {
    return _OptionState.idle;
  }
  if (index == exercise.correctIndex) {
    return _OptionState.correct;
  }
  if (index == chosen) {
    return _OptionState.wrong;
  }
  return _OptionState.dimmed;
}

/// Word option button (recognize exercises).
class _WordOption extends StatelessWidget {
  const _WordOption({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color face, Color border, Color text, double opacity) =
        switch (state) {
      _OptionState.idle => (
          KineticColors.surfaceContainerLow,
          KineticColors.outline,
          KineticColors.textHigh,
          1.0,
        ),
      _OptionState.correct => (
          KineticColors.mintContainer,
          KineticColors.mint,
          KineticColors.onMintContainer,
          1.0,
        ),
      _OptionState.wrong => (
          KineticColors.errorContainer,
          KineticColors.error,
          KineticColors.onErrorContainer,
          1.0,
        ),
      _OptionState.dimmed => (
          KineticColors.surfaceContainerLow,
          KineticColors.outline,
          KineticColors.textLow,
          0.5,
        ),
    };

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: face,
          borderRadius: BorderRadius.circular(KineticRadii.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(KineticRadii.md),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border.all(color: border),
                borderRadius: BorderRadius.circular(KineticRadii.md),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: text,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sign-card option (match exercises): the same kinetic card as the prompt,
/// compact, with feedback styling.
class _SignOption extends StatelessWidget {
  const _SignOption({
    required this.entry,
    required this.state,
    required this.onTap,
  });

  final VocabEntry entry;
  final _OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border = switch (state) {
      _OptionState.correct => KineticColors.mint,
      _OptionState.wrong => KineticColors.error,
      _OptionState.dimmed => KineticColors.outline,
      _OptionState.idle => KineticColors.outline,
    };
    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KineticRadii.lg + 2),
            border: Border.all(
              color: border,
              width: state == _OptionState.idle ? 1 : 2,
            ),
          ),
          child: SignView(entry: entry, compact: true),
        ),
      ),
    );
  }
}

/// Bottom feedback banner: correct (mint), wrong (error + the right answer)
/// with the "Seguir" action to advance.
class _FeedbackBar extends ConsumerWidget {
  const _FeedbackBar({required this.session});

  final LessonSessionState session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int? selected = session.selectedOption;
    final TextTheme textTheme = Theme.of(context).textTheme;
    if (selected == null) {
      return const SizedBox.shrink();
    }
    final Exercise exercise = session.exercises[session.index];
    final bool correct = exercise.isCorrect(selected);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: correct
            ? KineticColors.mintContainer
            : KineticColors.errorContainer,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(KineticRadii.md),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  correct ? Icons.check_circle : Icons.heart_broken,
                  color: correct
                      ? KineticColors.mint
                      : KineticColors.error,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    correct
                        ? '¡Correcto!'
                        : '¡Casi! Era: ${displayWordFor(exercise.entry)}',
                    style: textTheme.titleSmall?.copyWith(
                      color: correct
                          ? KineticColors.onMintContainer
                          : KineticColors.onErrorContainer,
                    ),
                  ),
                ),
                if (!correct)
                  Icon(
                    Icons.favorite,
                    color: KineticColors.error,
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            KineticButton(
              label: 'Seguir',
              expand: true,
              variant: correct
                  ? KineticButtonVariant.primary
                  : KineticButtonVariant.secondary,
              onPressed: () => ref.read(sessionProvider.notifier).advance(),
            ),
          ],
        ),
      ),
    );
  }
}
