import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/gloss_mapper/gloss_mapper.dart';
import '../../core/lsc_vocab/lsc_vocab.dart';
import '../../core/translator/translator_service.dart';
import '../../widgets/kinetic_button.dart';
import '../learn/lesson_screen.dart';
import 'player_controller.dart';

/// Pictogram quick phrase (spec: pictogram quick phrases MUST exist).
class QuickPhrase {
  const QuickPhrase(this.emoji, this.phrase);

  final String emoji;
  final String phrase;
}

/// Seeded phrases — every one of them is a COMPLETE translation: each word is
/// in the curated vocabulary and every resulting gloss carries a bundled clip
/// (verified against `assets/content/vocab.json` +
/// `assets/signs/manifest.json` by `test/quick_phrases_assets_test.dart`, and
/// on the device).
///
/// A phrase is only added here when it resolves with no out-of-vocabulary
/// notice and no text-mode card in the resulting sequence. That is why
/// `hola, buenos días` is NOT seeded: `BUENOS-DIAS` has no bundled clip yet,
/// so the sequence would end on a placeholder instead of a sign.
///
/// The phrase list is unaffected by the video-only rule and must stay that
/// way: [translatorServiceProvider] resolves against a video-only index, so a
/// clip-less word in a chip would now surface the omission notice instead of
/// silently ending on a placeholder. Both outcomes are visible, and the chips
/// exist precisely to avoid the notice.
const List<QuickPhrase> kQuickPhrases = <QuickPhrase>[
  QuickPhrase('👋', 'hola'),
  QuickPhrase('🌇', 'buenas tardes'),
  QuickPhrase('🙏', 'gracias'),
  QuickPhrase('🙂', '¿cómo estás?'),
  QuickPhrase('🤝', 'por favor'),
  QuickPhrase('😔', 'perdón, por favor'),
];

/// Traductor tab: offline-first text → LSC sequence translator.
///
/// Flow (design #172): input → TranslatorService (LocalMatcher default,
/// optional Gemini) → gloss sequence → `Secuencia n/n` player with
/// 0.75x/1x speed and Spanish TTS.
class TranslatorScreen extends ConsumerStatefulWidget {
  const TranslatorScreen({super.key});

  @override
  ConsumerState<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends ConsumerState<TranslatorScreen> {
  @override
  Widget build(BuildContext context) {
    final AsyncValue<TranslatorService> serviceAsync = ref.watch(
      translatorServiceProvider,
    );
    return serviceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No se pudo cargar el traductor. Revisa el contenido de la app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (TranslatorService service) => _TranslatorBody(service: service),
    );
  }
}

class _TranslatorBody extends ConsumerStatefulWidget {
  const _TranslatorBody({required this.service});

  final TranslatorService service;

  @override
  ConsumerState<_TranslatorBody> createState() => _TranslatorBodyState();
}

class _TranslatorBodyState extends ConsumerState<_TranslatorBody> {
  final TextEditingController _input = TextEditingController();
  bool _translating = false;
  TranslationResult? _result;
  Timer? _playbackTimer;

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _input.dispose();
    super.dispose();
  }

  /// Keeps the periodic advance timer in sync with playback state. The
  /// controller itself is timer-free (unit-testable); the UI owns timing.
  void _syncPlaybackTimer(SequencePlayerState player) {
    _playbackTimer?.cancel();
    if (!player.playing) {
      return;
    }
    _playbackTimer = Timer.periodic(player.signDuration, (Timer _) {
      ref.read(sequencePlayerProvider.notifier).advance();
    });
  }

  Future<void> _translate() async {
    final String text = _input.text.trim();
    if (text.isEmpty || _translating) {
      return;
    }
    setState(() => _translating = true);
    try {
      final TranslationResult result = await widget.service.translate(text);
      if (!mounted) {
        return;
      }
      setState(() => _result = result);
      ref.read(sequencePlayerProvider.notifier).load(result.glosses);
    } finally {
      if (mounted) {
        setState(() => _translating = false);
      }
    }
  }

  void _useQuickPhrase(String phrase) {
    _input.text = phrase;
    _translate();
  }

  /// Manual forward step from the on-screen next control.
  ///
  /// The tap itself moves the index immediately — it never waits for the
  /// autoplay tick — and the dwell timer is then restarted so the sign the user
  /// just picked gets a full beat instead of the remainder of the previous
  /// autoplay interval. Works while paused too (the timer simply stays off).
  void _onNext() {
    ref.read(sequencePlayerProvider.notifier).next();
    _syncPlaybackTimer(ref.read(sequencePlayerProvider));
  }

  /// Manual backward step; see [_onNext].
  void _onPrevious() {
    ref.read(sequencePlayerProvider.notifier).previous();
    _syncPlaybackTimer(ref.read(sequencePlayerProvider));
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    ref.listen<SequencePlayerState>(sequencePlayerProvider, (
      SequencePlayerState? previous,
      SequencePlayerState next,
    ) {
      final bool timingChanged =
          previous?.playing != next.playing || previous?.speed != next.speed;
      if (timingChanged) {
        _syncPlaybackTimer(next);
      }
    });

    final String? notice = _result?.notice;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _input,
          textInputAction: TextInputAction.done,
          onSubmitted: (String _) => _translate(),
          decoration: const InputDecoration(
            hintText: 'Escribe una frase en español…',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final QuickPhrase phrase in kQuickPhrases)
              ActionChip(
                avatar: Text(phrase.emoji, style: const TextStyle(fontSize: 18)),
                label: Text(phrase.phrase),
                onPressed: () => _useQuickPhrase(phrase.phrase),
              ),
          ],
        ),
        const SizedBox(height: 12),
        KineticButton(
          label: 'Traducir',
          icon: Icons.translate,
          expand: true,
          onPressed: _translating ? null : _translate,
        ),
        if (notice != null) ...<Widget>[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KineticColors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(KineticRadii.md),
              border: Border.all(
                color: KineticColors.amber.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: KineticColors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    notice,
                    style: textTheme.bodyMedium?.copyWith(
                      color: KineticColors.textHigh,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        _PlayerCard(onNext: _onNext, onPrevious: _onPrevious),
      ],
    );
  }
}

/// `Secuencia n/n` playback card: current sign ([SignView] plays the bundled
/// clip, which the video-only index guarantees it has), progress
/// dots, previous/next controls, play/pause, speed toggle and repeat-audio
/// controls. The card owns the sign cadence; the clip simply loops until the
/// index advances.
class _PlayerCard extends ConsumerWidget {
  const _PlayerCard({required this.onNext, required this.onPrevious});

  /// Manual step intents, owned by the screen so the autoplay dwell timer can
  /// be restarted alongside them.
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final SequencePlayerState player = ref.watch(sequencePlayerProvider);
    if (!player.hasSequence) {
      return const SizedBox.shrink();
    }

    final VocabIndex? index = ref.watch(vocabIndexProvider).value;
    final Gloss? current = player.current;
    final VocabEntry? entry =
        current == null || index == null ? null : index.byId(current.entryId);

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KineticColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(KineticRadii.lg),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.sign_language,
                size: 18,
                color: KineticColors.iris,
              ),
              const SizedBox(width: 8),
              Text(
                player.counterLabel,
                style: textTheme.labelLarge?.copyWith(
                  color: KineticColors.textLow,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // `autoplay: player.playing` is what makes the play/pause icon
          // truthful: the clip follows the state instead of looping on its own
          // while the icon claims playback is stopped. Paused holds the current
          // frame, so the sign stays visible.
          if (entry != null)
            SignView(entry: entry, autoplay: player.playing),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _StepButton(
                icon: Icons.skip_previous,
                tooltip: 'Seña anterior',
                onPressed: player.canGoPrevious ? onPrevious : null,
              ),
              const SizedBox(width: 12),
              for (int i = 0; i < player.sequence.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == player.index ? 18 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == player.index
                        ? KineticColors.mint
                        : KineticColors.outline,
                    borderRadius: BorderRadius.circular(KineticRadii.pill),
                  ),
                ),
              const SizedBox(width: 12),
              _StepButton(
                icon: Icons.skip_next,
                tooltip: 'Seña siguiente',
                onPressed: player.canGoNext ? onNext : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              IconButton(
                tooltip: player.playing ? 'Pausar' : 'Reproducir',
                onPressed: () {
                  final SequencePlayerController controller = ref.read(
                    sequencePlayerProvider.notifier,
                  );
                  player.playing ? controller.pause() : controller.play();
                },
                icon: Icon(
                  player.playing ? Icons.pause_circle : Icons.play_circle,
                  size: 56,
                  color: KineticColors.mint,
                ),
              ),
              const SizedBox(width: 12),
              SegmentedButton<double>(
                segments: const <ButtonSegment<double>>[
                  ButtonSegment<double>(value: 0.75, label: Text('0.75x')),
                  ButtonSegment<double>(value: 1.0, label: Text('1x')),
                ],
                selected: <double>{player.speed},
                showSelectedIcon: false,
                onSelectionChanged: (Set<double> selection) {
                  if (selection.first != player.speed) {
                    ref.read(sequencePlayerProvider.notifier).toggleSpeed();
                  }
                },
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Repetir audio',
                onPressed: ref.read(sequencePlayerProvider.notifier).repeatAudio,
                icon: const Icon(
                  Icons.volume_up,
                  size: 28,
                  color: KineticColors.iris,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Previous/next control for the gloss sequence.
///
/// Built as a tappable surface rather than a bare icon so the affordance is
/// obvious: a mint circle, the same accent as the play control, sized to the
/// minimum 48dp touch target. It follows the same `KineticColors` /
/// `KineticRadii` tokens as the rest of the card.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: tooltip,
        child: Material(
          color: enabled
              ? KineticColors.mint.withValues(alpha: 0.14)
              : KineticColors.surfaceContainerHigh,
          shape: const CircleBorder(
            side: BorderSide(color: KineticColors.mint),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                icon,
                size: 28,
                color: enabled ? KineticColors.mint : KineticColors.textLow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
