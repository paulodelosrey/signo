import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/lsc_vocab/lsc_vocab.dart';
import '../learn/lesson_screen.dart' show SignView;

/// Detail page for one dictionary sign.
///
/// Reuses the same [SignView] seam the lessons and the translator use, so a
/// clip-backed sign plays here with no structural change.
///
/// This is the ONE surface that legitimately reaches the text-mode card: the
/// dictionary indexes the complete vocabulary (201 signs), while the learning
/// path, the exercises and the translator are gated to clip-backed signs only.
///
/// It is also the only surface allowed to SAY that a clip is missing. Everywhere
/// else the rule is "no surface renders a 'video en curaduría' box", because a
/// sign is only ever shown there when a clip exists. Here, for a sign that has
/// no clip at all, a quiet honest line under the card is the truthful answer;
/// the user is about to press play and nothing will happen, so the UI owes them
/// the reason.
///
/// Trade-off: a sign whose clip is DECLARED but fails a runtime decode also
/// degrades to the same text card (see `SignVideoPlayer`'s fallback), and in
/// that rare case this note stays silent. That is deliberate — a wrong claim
/// ("no clip exists") is worse than no claim, and the playable-clips badge in
/// the browse list still communicates that a clip was expected.
class SignDetailScreen extends StatelessWidget {
  const SignDetailScreen({super.key, required this.entry});

  final VocabEntry entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: kineticAppBar(entry.gloss),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SignView(entry: entry),
          if (!entry.isVideoBacked) ...<Widget>[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.videocam_off_outlined,
                  size: 16,
                  color: KineticColors.textLow,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Vídeo no disponible por ahora',
                        style: textTheme.bodySmall?.copyWith(
                          color: KineticColors.textLow,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Second line: the reason is production, not a bug and
                      // not an apology. One short sentence is the most this
                      // surface owes — the dictionary stays a lookup tool, not
                      // a place to negotiate the backlog.
                      Text(
                        'Estamos produciendo los vídeos restantes.',
                        style: textTheme.bodySmall?.copyWith(
                          color: KineticColors.textLow,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text('Cómo se dice', style: textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String lemma in entry.lemmas)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: KineticColors.surfaceContainerMid,
                    borderRadius: BorderRadius.circular(KineticRadii.pill),
                    border: Border.all(color: KineticColors.outline),
                  ),
                  child: Text(lemma, style: textTheme.bodyMedium),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KineticColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(KineticRadii.lg),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, color: KineticColors.iris),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Unidad ${entry.lesson} · ${entry.subtema}',
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
