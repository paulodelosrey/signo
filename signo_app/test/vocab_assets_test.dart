import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/translator/local_matcher.dart';
import 'package:signo_app/core/translator/translator_service.dart';

/// Loads the REAL compiled assets (declared in pubspec) through rootBundle,
/// proving the offline asset path works without the source CSV.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('compiled content assets (offline load)', () {
    test('vocab.json loads and indexes every compiled sign', () async {
      final String raw = await rootBundle.loadString(kVocabAssetPath);
      final VocabIndex index = VocabIndex.fromJsonString(raw);

      expect(index.count, 175, reason: '189 usable CSV rows → 175 lexical '
          'signs after removing 14 note rows and 1 empty-sign row');
      expect(
        index.entries.every((VocabEntry e) => e.lemmas.isNotEmpty),
        isTrue,
      );
    });

    test('grammar.json loads with all seven rules', () async {
      final String raw = await rootBundle.loadString(kGrammarAssetPath);
      final GrammarRuleSet rules = GrammarRuleSet.fromJson(
        jsonDecode(raw)! as Map<String, Object?>,
      );

      expect(
        rules.rules.map((GrammarRule r) => r.id),
        containsAll(<String>[
          'drop-copula',
          'drop-connectors',
          'drop-intensifiers',
          'drop-articles',
          'drop-prepositions',
          'time-front',
          'reorder',
        ]),
      );
      expect(rules.categoryWords('copula'), contains('es'));
      expect(rules.provenanceNote, isNotEmpty);
    });
  });

  group('offline scripted translation (spec: translator)', () {
    test('scripted sentence maps time-fronted and verb-final over the '
        'REAL compiled vocab', () async {
      final VocabIndex index = VocabIndex.fromJsonString(
        await rootBundle.loadString(kVocabAssetPath),
      );
      final GrammarRuleSet rules = GrammarRuleSet.fromJson(
        jsonDecode(await rootBundle.loadString(kGrammarAssetPath))!
            as Map<String, Object?>,
      );

      final TranslationResult result = await LocalMatcher(
        index: index,
        rules: rules,
      ).translate('Ayer yo estudiar en la casa');

      // time-front: AYER leads; verb-final: ESTUDIAR closes; `en`/`la`
      // dropped by the article/preposition rules (notice stays clean).
      expect(result.glosses.map((Gloss g) => g.label).toList(), <String>[
        'AYER',
        'YO',
        'CASA',
        'ESTUDIAR',
      ]);
      expect(result.glosses.first.isTime, isTrue);
      expect(result.unknownWords, isEmpty);
      expect(result.notice, isNull);
    });
  });
}
