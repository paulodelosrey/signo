import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/lsc_vocab/lsc_vocab.dart';
import 'dictionary_search.dart';
import 'sign_detail_screen.dart';

/// Read-only visual dictionary (spec `visual-dictionary`).
///
/// Search-sign scenario: a query field filters the compiled vocabulary
/// (case/diacritics-insensitive substring match over glosses and lemmas);
/// with an empty query every sign of the 175-entry vocabulary is listed.
/// Tapping a result opens the sign detail, which reuses the SignView
/// text-mode T4 seam (videos still BLOCKED-USER).
class DictionaryScreen extends ConsumerStatefulWidget {
  const DictionaryScreen({super.key});

  @override
  ConsumerState<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends ConsumerState<DictionaryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final AsyncValue<VocabIndex> vocab = ref.watch(vocabIndexProvider);

    return Scaffold(
      appBar: kineticAppBar('Diccionario'),
      body: vocab.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: KineticColors.mint),
        ),
        error: (Object error, StackTrace _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se pudo cargar el diccionario. Reintenta más tarde.',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
          ),
        ),
        data: (VocabIndex index) {
          final List<VocabEntry> results =
              searchSigns(index.entries, _query);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: TextField(
                  onChanged: (String value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar señas…',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: KineticColors.surfaceContainerMid,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KineticRadii.md),
                      borderSide: const BorderSide(
                        color: KineticColors.outline,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KineticRadii.md),
                      borderSide: const BorderSide(
                        color: KineticColors.outline,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(KineticRadii.md),
                      borderSide: const BorderSide(color: KineticColors.mint),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _query.isEmpty
                        ? '${results.length} señas'
                        : '${results.length} ${results.length == 1 ? 'resultado' : 'resultados'}',
                    style: textTheme.labelMedium?.copyWith(
                      color: KineticColors.textLow,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? _EmptyResults(query: _query)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: results.length,
                        itemBuilder: (BuildContext context, int i) =>
                            _SignRow(entry: results[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One tappable result row. Kept at 48px minimum height (a11y touch-target
/// rule) with merged semantics for screen readers.
class _SignRow extends StatelessWidget {
  const _SignRow({required this.entry});

  final VocabEntry entry;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(KineticRadii.md),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) =>
                    SignDetailScreen(entry: entry),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: KineticColors.surfaceContainerMid,
                      borderRadius: BorderRadius.circular(KineticRadii.md),
                    ),
                    child: const Icon(
                      Icons.sign_language,
                      color: KineticColors.iris,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.gloss,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          entry.lemmas.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: KineticColors.textLow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: KineticColors.textLow,
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

/// Shown when the query matches nothing in the vocabulary.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Sin resultados para "$query"',
              style: textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otra palabra del vocabulario.',
              style: textTheme.bodyMedium?.copyWith(
                color: KineticColors.textLow,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
