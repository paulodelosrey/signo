import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/lsc_vocab/lsc_vocab.dart';
import '../learn/lesson_screen.dart' show SignView;

/// Detail page for one dictionary sign.
///
/// Reuses the M3 [SignView] text-mode card — the same single TODO(T4) video
/// swap seam used by lessons and the translator player — so when curated
/// clips land, this view gains video with NO structural change (videos are
/// still BLOCKED-USER; the card shows the 'video en curaduría' note).
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
