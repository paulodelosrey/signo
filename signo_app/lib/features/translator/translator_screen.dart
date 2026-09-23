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

/// Pictogram quick phrases (spec: pictogram quick phrases MUST exist).
class _QuickPhrase {
  const _QuickPhrase(this.emoji, this.phrase);

  final String emoji;
  final String phrase;
}

const List<_QuickPhrase> _kQuickPhrases = <_QuickPhrase>[
  _QuickPhrase('👋', 'Hola'),
  _QuickPhrase('🌅', 'Buenos días'),
  _QuickPhrase('🙏', 'Gracias'),
  _QuickPhrase('❓', '¿Cómo estás?'),
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final _QuickPhrase phrase in _kQuickPhrases)
              ActionChip(
                avatar: Text(phrase.emoji, style: const TextStyle(fontSize: 18)),
                label: Text(phrase.phrase),
                onPressed: () => _useQuickPhrase(phrase.phrase),
              ),
          ],
        ),
        const SizedBox(height: 16),
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
        const _PlayerCard(),
      ],
    );
  }
}

/// `Secuencia n/n` playback card: current sign (SignView text-mode seam,
/// TODO(T4) swaps in the video player), progress dots, play/pause, speed
/// toggle and repeat-audio controls.
class _PlayerCard extends ConsumerWidget {
  const _PlayerCard();

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
          if (entry != null) SignView(entry: entry),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
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
