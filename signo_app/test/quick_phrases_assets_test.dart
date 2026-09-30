import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/translator/local_matcher.dart';
import 'package:signo_app/core/translator/translator_service.dart';
import 'package:signo_app/features/translator/translator_screen.dart';

/// The seeded quick phrases must be COMPLETE translations.
///
/// A phrase is only worth offering as a one-tap chip if every word is inside
/// the curated vocabulary AND every sign the translator resolves it to ships a
/// bundled clip. Anything else ends the sequence on a text-mode placeholder, or
/// surfaces the "Se omitieron palabras fuera de vocabulario" notice — which is
/// what the chips exist to avoid.
///
/// This test reads the REAL `assets/content/vocab.json`, the REAL
/// `assets/content/grammar.json` and the REAL `assets/signs/manifest.json`, so
/// it fails as soon as a phrase drifts out of the curated layer or a clip is
/// dropped from the bundle.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VocabIndex index;
  late GrammarRuleSet rules;
  late Set<String> manifestAssets;

  setUpAll(() async {
    index = VocabIndex.fromJsonString(
      await rootBundle.loadString(kVocabAssetPath),
    );
    rules = GrammarRuleSet.fromJson(
      jsonDecode(await rootBundle.loadString(kGrammarAssetPath))!
          as Map<String, Object?>,
    );
    final List<Object?> manifest =
        jsonDecode(await rootBundle.loadString('assets/signs/manifest.json'))!
            as List<Object?>;
    manifestAssets = <String>{
      for (final Object? item in manifest)
        (item! as Map<String, Object?>)['asset']! as String,
    };
  });

  Future<TranslationResult> translate(String phrase) =>
      LocalMatcher(index: index, rules: rules).translate(phrase);

  /// The PRODUCTION shape: [translatorServiceProvider] hands the matcher a
  /// video-only view, so a clip-less word simply does not resolve.
  LocalMatcher gatedMatcher() =>
      LocalMatcher(index: index.copyWithVideoOnly(), rules: rules);

  group('seeded quick phrases', () {
    test('every phrase translates with no out-of-vocabulary word', () async {
      for (final QuickPhrase phrase in kQuickPhrases) {
        final TranslationResult result = await translate(phrase.phrase);
        expect(
          result.unknownWords,
          isEmpty,
          reason: '"${phrase.phrase}" leaves words outside the vocabulary',
        );
        expect(
          result.notice,
          isNull,
          reason: '"${phrase.phrase}" surfaces a notice to the user',
        );
        expect(
          result.glosses,
          isNotEmpty,
          reason: '"${phrase.phrase}" resolves to no sign at all',
        );
      }
    });

    test('every resolved sign has a clip bundled in the manifest', () async {
      for (final QuickPhrase phrase in kQuickPhrases) {
        final TranslationResult result = await translate(phrase.phrase);
        for (final Gloss gloss in result.glosses) {
          final VocabEntry entry = index.byId(gloss.entryId)!;
          expect(
            entry.hasVideo,
            isTrue,
            reason: '"${phrase.phrase}" resolves to ${entry.gloss}, which has '
                'no clip bundled',
          );
          expect(
            manifestAssets,
            contains(entry.asset),
            reason: '${entry.gloss} points at ${entry.asset}, absent from '
                'assets/signs/manifest.json',
          );
        }
      }
    });

    test('every phrase also survives the video-only gate the app ships with',
        () async {
      // The chips must work against the index the translator ACTUALLY uses
      // (`copyWithVideoOnly`), not merely against the complete one. Under the
      // video-only rule a clip-less word no longer resolves at all, so a chip
      // that quietly depended on one would now surface the omission notice —
      // the exact thing the chips exist to avoid.
      for (final QuickPhrase phrase in kQuickPhrases) {
        final TranslationResult result =
            await gatedMatcher().translate(phrase.phrase);
        expect(
          result.unknownWords,
          isEmpty,
          reason: '"${phrase.phrase}" leaves a word the translator cannot show',
        );
        expect(
          result.notice,
          isNull,
          reason: '"${phrase.phrase}" surfaces a notice to the user',
        );
        expect(
          result.glosses,
          isNotEmpty,
          reason: '"${phrase.phrase}" resolves to no sign at all',
        );
      }
    });

    test('the phrases stay short enough to be quick phrases', () async {
      for (final QuickPhrase phrase in kQuickPhrases) {
        final TranslationResult result = await translate(phrase.phrase);
        expect(
          result.glosses.length,
          lessThanOrEqualTo(4),
          reason: '"${phrase.phrase}" is too long for a one-tap chip',
        );
      }
    });

    test('the rejected phrase is proven unusable, so it stays out', () async {
      // This test deliberately uses the COMPLETE index: it is proving that a
      // clip-less sign EXISTS in the content, which is only observable through
      // the unfiltered view. The gated behaviour it implies is asserted
      // separately below.
      //
      // `hola, buenos días` was the original first chip and it does NOT hold
      // up: BUENOS-DIAS ships no clip, so the sequence would end on a
      // placeholder instead of a sign.
      final TranslationResult result = await translate('hola, buenos días');
      expect(
        result.glosses.any(
          (Gloss gloss) => !index.byId(gloss.entryId)!.hasVideo,
        ),
        isTrue,
        reason: 'BUENOS-DIAS is expected to stay clip-less until curation',
      );
      expect(
        kQuickPhrases.map((QuickPhrase p) => p.phrase),
        isNot(contains('hola, buenos días')),
      );

      // `quiero` IS in the vocabulary (TE-QUIERO) but that sign has no clip,
      // which is the honest reason `quiero aprender` was dropped.
      final TranslationResult quiero = await translate('quiero aprender');
      expect(
        quiero.unknownWords,
        isEmpty,
        reason: 'the real reason is the missing clip, not the vocabulary',
      );
      expect(
        index.byId('l5-200')!.hasVideo,
        isFalse,
        reason: 'TE-QUIERO ships no clip until curation',
      );
    });
  });

  group('video-only translator (GATE D)', () {
    test('a clip-less word is routed into unknownWords and surfaces the notice',
        () async {
      // BUENOS-DIAS is in the vocabulary but ships no clip. Under the gate it
      // does not merely lose its clip — it cannot be resolved at all, which is
      // what makes the omission EXPLAINABLE: the user is told a word was left
      // out instead of being shown a card that plays nothing.
      final TranslationResult result =
          await LocalMatcher(index: index.copyWithVideoOnly(), rules: rules)
              .translate('hola buenos días');

      expect(
        result.unknownWords,
        containsAll(<String>['buenos', 'días']),
        reason: 'both tokens of a clip-less sign must be reported as omitted',
      );
      expect(
        result.notice,
        startsWith('Se omitieron palabras fuera de vocabulario:'),
      );
      // The playable word still made it through — the gate drops, it does not
      // fail the whole translation.
      expect(result.glosses.map((Gloss g) => g.label).toList(), <String>['HOLA']);
    });

    test('translatorServiceProvider really gates (GATE D, at the provider)',
        () async {
      // Constructing a LocalMatcher by hand proves the index gate works; this
      // proves the PROVIDER actually applies it. Without this, reverting
      // `translatorServiceProvider` back to the complete index would keep the
      // whole suite green while the translator quietly started resolving
      // clip-less words again.
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final TranslatorService service =
          await container.read(translatorServiceProvider.future);

      // `buenos días` is BUENOS-DIAS: in the vocabulary, no bundled clip.
      final TranslationResult result =
          await service.translate('hola buenos días');
      expect(result.unknownWords, isNotEmpty);
      expect(
        result.notice,
        startsWith('Se omitieron palabras fuera de vocabulario:'),
      );
      expect(result.glosses.map((Gloss g) => g.label).toList(), <String>['HOLA']);

      // The keyless Gemini stub is unaffected by the gate: it never consults
      // the vocabulary, and TranslatorService still answers from the local one.
      expect(
        await service.translate('hola'),
        isA<TranslationResult>()
            .having((TranslationResult r) => r.engine, 'engine',
                TranslationEngine.local)
            .having((TranslationResult r) => r.notice, 'notice', isNull),
      );
    });

    test('the same sentence on the complete index resolves the clip-less sign',
        () async {
      // The contrast that proves the gate is the INDEX and not a filter inside
      // the matcher: with the complete index the same input resolves fully.
      final TranslationResult ungated = await translate('hola buenos días');

      expect(ungated.unknownWords, isEmpty);
      expect(ungated.notice, isNull);
      expect(
        ungated.glosses.map((Gloss g) => g.label).toList(),
        <String>['HOLA', 'BUENOS-DIAS'],
      );
    });
  });
}
