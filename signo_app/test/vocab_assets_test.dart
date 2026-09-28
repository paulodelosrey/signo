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

      expect(index.count, 201, reason: '190 usable CSV rows → 175 lexical '
          'signs after removing 14 note rows and 1 empty-sign row, minus the '
          'aggregate ABECEDARIO row plus its 27 expanded letter signs');
      expect(
        index.entries.every((VocabEntry e) => e.lemmas.isNotEmpty),
        isTrue,
      );
    });

    test('vocab.json carries the bundled clips from the sign manifest', () async {
      final VocabIndex index = VocabIndex.fromJsonString(
        await rootBundle.loadString(kVocabAssetPath),
      );

      final List<VocabEntry> withVideo =
          index.entries.where((VocabEntry e) => e.hasVideo).toList();
      // 27 alphabet clips + 15 acciones + 7 frases + 10 question forms of
      // existing signs. 4 manifest clips (que_pregunta, se_va, bienvenido,
      // esperar) have no vocabulary entry yet and stay unused on purpose.
      expect(withVideo.length, 59);
      expect(
        withVideo.every((VocabEntry e) =>
            e.asset != null && e.asset!.startsWith('assets/signs/')),
        isTrue,
      );
      // `releasePath` stays null until the GitHub Release step.
      expect(
        index.entries.every(
            (VocabEntry e) => e.releasePath == null &&
                e.trimStartMs == null &&
                e.trimEndMs == null),
        isTrue,
      );
    });

    test('the 27 alphabet signs are individual entries with their own clip',
        () async {
      final VocabIndex index = VocabIndex.fromJsonString(
        await rootBundle.loadString(kVocabAssetPath),
      );

      final List<VocabEntry> letters = index.entries
          .where((VocabEntry e) => normalizeForMatch(e.subtema) == 'abecedario')
          .toList();
      expect(letters.length, 27);
      expect(
        letters.every((VocabEntry e) =>
            e.lesson == 1 && e.hasVideo && e.asset != null),
        isTrue,
      );
      expect(letters.map((VocabEntry e) => e.gloss).toList(),
          <String>['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L',
            'M', 'N', 'Ñ', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
            'Y', 'Z']);
      // The aggregate row is gone: it is not a sign anymore.
      expect(index.lookupLemma('abecedario'), isNull);
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
