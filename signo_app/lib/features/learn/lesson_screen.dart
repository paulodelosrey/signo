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
/// VIDEO-ONLY SURFACES. The learning path, the exercises, Repasar, Práctica
/// and the translator only ever hand [SignView] a sign with a playable clip
/// (`VocabIndex.videoEntries` → `buildCurriculum` → `buildExercises`, and a
/// video-only index in the translator). This card is therefore the
/// DICTIONARY surface for a clip-less sign and nothing else: a sign the user
/// looked up and that the app cannot yet play. It says nothing about why —
/// no "video en curaduría" note, because the library's growth state is not
/// the user's problem to be told about on every row, and a card that
/// apologizes for itself is the placeholder this design removed.
///
/// The clip plays in EVERY direction that shows the sign: the recognize
/// prompt, the match option cards and the translator sequence player. The
/// caller may force [autoplay] off to hold a clip on its current frame.
///
/// Set [showGloss] to false when the card is the prompt of a sign→word
/// exercise: there the gloss IS the answer, so the sign must be identified by
/// the video alone. See [_RecognizeFallback] for the runtime decode failure
/// case, where hiding the gloss would leave the question unanswerable.
class SignView extends StatelessWidget {
  const SignView({
    super.key,
    required this.entry,
    this.compact = false,
    this.showGloss = true,
    this.autoplay,
  });

  final VocabEntry entry;

  /// Compact variant for match-exercise option cards.
  final bool compact;

  /// Whether the text-mode card may print [VocabEntry.gloss]. The clip is
  /// unaffected: a sign with video always plays it.
  final bool showGloss;

  /// Whether the clip loops. Defaults to true: a sign that is being shown is
  /// a sign that must be seen. [SignVideoPlayer] holds its current frame while
  /// this is false, so pausing a sequence freezes the sign on screen instead
  /// of hiding it.
  final bool? autoplay;

  @override
  Widget build(BuildContext context) {
    final String? asset = entry.asset;
    // Text mode: a plain sign glyph plus, optionally, the gloss. Neutral and
    // silent about curation — the dictionary's answer for a sign the app
    // cannot play yet.
    final Widget content = _textCard(context, withGloss: showGloss);

    // RECOGNIZE-PROMPT RESILIENCE. `showGloss: false` means the caller is
    // asking "¿Qué palabra significa esta seña?" — the gloss below IS the
    // answer, so the prompt card must not print it. But the only way a
    // showGloss:false card can ever lose its clip is a runtime decode failure
    // (a broken/partial bundled file), because the exercise builder only hands
    // this widget video-backed signs. Falling back to the gloss-less card there
    // would put four word options under a bare icon: a question with no way to
    // answer it, which is a hard failure. Printing the gloss instead is a soft
    // failure — the learner sees the word they were asked to recognize, the
    // exercise still completes, and they lose the challenge for that one item.
    // A self-answering exercise beats an unanswerable one.
    final Widget fallback = showGloss ? content : _textCard(context, withGloss: true);

    // Loading state: neutral, and deliberately silent about curation. The clip
    // is coming — saying "video en curaduría" for a second before it appears
    // told the user the sign had no video at all.
    final Widget loading = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(
          Icons.play_circle_outline,
          size: compact ? 28 : 44,
          color: KineticColors.textLow,
        ),
        SizedBox(height: compact ? 4 : 10),
        SizedBox(
          width: compact ? 48 : 96,
          height: 3,
          child: const LinearProgressIndicator(
            minHeight: 3,
            color: KineticColors.iris,
            backgroundColor: KineticColors.outline,
          ),
        ),
      ],
    );

    final Widget face = Container(
      width: double.infinity,
      height: compact ? null : 220,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 16,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: KineticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
      ),
      // The clip is confined to the same padded box, so the surface height
      // (220 prompt / grid cell compact) and the Kinetic tokens are
      // untouched. Missing asset => SignVideoPlayer renders `fallback`.
      // The clip autoplays in the compact variant too: a match option card
      // that silently holds a still frame reads as "no video at all".
      child: entry.hasVideo && asset != null
          ? SignVideoPlayer(
              key: ValueKey<String>(asset),
              assetPath: asset,
              fallback: fallback,
              loading: loading,
              autoplay: autoplay ?? true,
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

  /// The text-mode card: sign glyph, plus the gloss when [withGloss].
  ///
  /// Two callers: the direct render for a clip-less sign (the dictionary), and
  /// [SignVideoPlayer]'s runtime fallback. The gloss is a parameter rather
  /// than a fixed child so the recognize prompt can withhold it on the normal
  /// path and reveal it only once the clip is proven unplayable.
  Widget _textCard(BuildContext context, {required bool withGloss}) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sign_language,
          size: compact ? 28 : 44,
          color: KineticColors.iris,
        ),
        if (withGloss) ...<Widget>[
          SizedBox(height: compact ? 4 : 12),
          Text(
            entry.gloss,
            textAlign: TextAlign.center,
            // `titleMedium` (not `titleLarge`) plus a two-line cap: a
            // multi-word gloss such as BUENOS-DIAS wraps to two lines, and at
            // `titleLarge` that second line pushed the column past the grid
            // cell, painting the overflow stripe across the card.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (compact ? textTheme.titleMedium : textTheme.headlineMedium)
                ?.copyWith(
              color: KineticColors.textHigh,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? 0.8 : 1.2,
              height: 1.15,
            ),
          ),
        ],
      ],
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

  /// Guards the single route pop this screen is allowed to perform.
  ///
  /// Leaving the lesson calls `dismiss()` and then pops. `dismiss()` clears
  /// [sessionProvider], so `build` ALSO reaches the "session dropped
  /// underneath us" branch and would schedule a second pop — and two pops
  /// tear down the shell route below as well, leaving an empty Navigator and
  /// a black screen. Every exit path therefore goes through [_popOnce].
  bool _popped = false;

  void _popOnce() {
    if (_popped) {
      return;
    }
    _popped = true;
    Navigator.of(context).pop();
  }

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
      _popOnce();
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
      // Session dropped underneath us without this screen asking for it (a
      // sibling dismissed it). Go back exactly once — [_popOnce] is already
      // set when the drop came from [_onExitRequested], so the deliberate pop
      // is never duplicated into the shell route below.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _popOnce();
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
///
/// MATCH EXERCISES ARE TAP-TO-PLAY, AND THAT IS A DEVICE CONSTRAINT, NOT A
/// STYLE CHOICE. Verified on the TECNO CM6: four `VideoPlayerController`s
/// playing at once all decode but never update their surface — 8 captures 1s
/// apart over one card produced ONE unique frame in 7 seconds, while the
/// single-player surfaces (recognize prompt, translator) animate normally.
/// So a card that is not being previewed renders NO player at all: a neutral
/// face with a play affordance. At most one `VideoPlayerController` ever
/// exists in the grid, which is the only way this exercises reliably.
///
/// That split playback from answering on purpose. Tapping used to commit the
/// answer, so reusing the same tap for playback would let a user "answer" a
/// sign they never watched. Now: tap previews (and moves the single player),
/// and the ✓ that appears on the playing card is what locks the answer. You
/// cannot choose a sign you have not seen move — which is the whole point of
/// a sign-language app.
class _ExerciseBody extends ConsumerStatefulWidget {
  const _ExerciseBody({super.key, required this.exercise, required this.session});

  final Exercise exercise;
  final LessonSessionState session;

  @override
  ConsumerState<_ExerciseBody> createState() => _ExerciseBodyState();
}

class _ExerciseBodyState extends ConsumerState<_ExerciseBody> {
  /// Index of the option whose clip is currently playing; null when idle.
  ///
  /// The parent keys this widget by `session.index`, so advancing to the next
  /// exercise builds a fresh State and the preview never leaks across
  /// exercises.
  int? _previewIndex;

  @override
  Widget build(BuildContext context) {
    final Exercise exercise = widget.exercise;
    final LessonSessionState session = widget.session;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int? selected = session.selectedOption;

    // sign→word: the gloss is the answer, so the card must not print it.
    // The sign is identified by its video alone (or by a neutral visual when
    // no clip is bundled). word→sign never reaches this branch.
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
              SignView(entry: exercise.entry, showGloss: false),
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
                  // Word options need no preview step: the sign to identify is
                  // the single prompt card, already playing above.
                  onTap: selected == null ? () => _answer(ref, i) : null,
                ),
            ],
          )
        : GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // 1.4 gave a ~113dp cell, which the two-line compact gloss
            // overflowed by ~5.5dp. 1.05 raises the cell to ~150dp so a
            // wrapped gloss plus the play affordance always fit.
            childAspectRatio: 1.05,
            children: <Widget>[
              for (int i = 0; i < exercise.options.length; i++)
                _SignOption(
                  entry: exercise.options[i],
                  state: _optionState(i, selected, exercise),
                  isPreviewing: _previewIndex == i,
                  onPreview: selected != null
                      ? null
                      : () => setState(
                            () => _previewIndex =
                                _previewIndex == i ? null : i,
                          ),
                  onChoose:
                      selected == null ? () => _answer(ref, i) : null,
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

  void _answer(WidgetRef ref, int optionIndex) {
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

/// Sign-card option (match exercises), tap-to-play.
///
/// Two mutually exclusive faces, and the split is what keeps the grid down to
/// ONE video player:
/// - **not previewing** → a neutral face with a play glyph and NO
///   `SignVideoPlayer` at all, so no controller is created for this card;
/// - **previewing** → the looping clip, plus a mint ✓ to commit the answer.
///
/// `onPreview` and `onChoose` are separate callbacks on purpose; a single tap
/// that both played and answered would let the user lock a sign they never
/// watched move.
class _SignOption extends StatelessWidget {
  const _SignOption({
    required this.entry,
    required this.state,
    required this.isPreviewing,
    required this.onPreview,
    required this.onChoose,
  });

  final VocabEntry entry;
  final _OptionState state;
  final bool isPreviewing;
  final VoidCallback? onPreview;
  final VoidCallback? onChoose;

  @override
  Widget build(BuildContext context) {
    final Color border = switch (state) {
      _OptionState.correct => KineticColors.mint,
      _OptionState.wrong => KineticColors.error,
      _OptionState.dimmed => KineticColors.outline,
      _OptionState.idle =>
        isPreviewing ? KineticColors.mint : KineticColors.outline,
    };
    final double borderWidth = state == _OptionState.idle && !isPreviewing ? 1 : 2;
    final double radius = KineticRadii.lg + 2;
    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onPreview,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: border,
              width: borderWidth,
            ),
          ),
          // The face MUST be clipped to the border's inner edge. Without this
          // the square-cornered face paints over the rounded border's arcs and
          // the card reads as clipped: the mint "correct" outline was visibly
          // cut at all four corners. The old child (SignView) shipped its own
          // ClipRRect, which is why the artifact only appeared once the idle
          // `_PlayAffordance` replaced it. Insetting the radius by the border
          // width keeps the face just inside the stroke instead of under it.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius - borderWidth),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                if (isPreviewing)
                  SignView(entry: entry, compact: true, autoplay: true)
                else
                  const _PlayAffordance(),
                if (isPreviewing && onChoose != null)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: _ChooseButton(onTap: onChoose!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The idle face of a match option: it advertises that the sign is playable
/// and, more importantly, it instantiates no video player. A play glyph is the
/// honest affordance here — the app is refusing to show a still frame of a
/// sign and asking the user to watch it.
class _PlayAffordance extends StatelessWidget {
  const _PlayAffordance();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: KineticColors.surfaceContainerLow,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(
            Icons.play_circle_outline,
            size: 34,
            color: KineticColors.textLow,
          ),
          const SizedBox(height: 4),
          Text(
            'Ver seña',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: KineticColors.textLow,
                ),
          ),
        ],
      ),
    );
  }
}

/// Mint ✓ committing the answer on the card that is currently playing.
///
/// It is a separate control from the card's own tap because the card's tap
/// already means "play this one"; only this button means "this is my answer".
class _ChooseButton extends StatelessWidget {
  const _ChooseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Elegir esta seña',
      child: Material(
        color: KineticColors.mint,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.check, color: KineticColors.onMint, size: 26),
          ),
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
