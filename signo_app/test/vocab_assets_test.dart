import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/gloss_mapper/gloss_mapper.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/core/translator/local_matcher.dart';
import 'package:signo_app/core/translator/translator_service.dart';
import 'package:signo_app/features/dictionary/dictionary_screen.dart';
import 'package:signo_app/features/dictionary/dictionary_search.dart';
import 'package:signo_app/features/learn/curriculum.dart';

/// Loads the REAL compiled assets (declared in pubspec) through rootBundle,
/// proving the offline asset path works without the source CSV.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('compiled content assets (offline load)', () {
    test('vocab.json loads and indexes every compiled sign', () async {
      final String raw = await rootBundle.loadString(kVocabAssetPath);
      final VocabIndex index = VocabIndex.fromJsonString(raw);

      expect(index.count, 201, reason: '190 usable CSV rows → 201 lexical '
          'signs after removing note rows and one empty-sign row, minus the '
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
      // Every bundled clip that a course row can name is now bound: the
      // pipeline takes all fifteen folders instead of three, so the alphabet,
      // actions, phrases and the Comida/Calendario/Familia/Antonimos sets all
      // reach a sign. A handful of clips still have no course row to match
      // (notably the "Images ..." curriculum rows, which name pictures rather
      // than signs, and the bare month names under the single
      // "Meses del ano (Enero-Diciembre)" row); those stay unused on purpose.
      expect(withVideo.length, 158);
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

  group('the shipped learning path over the REAL assets', () {
    // The product decision, measured against the data the app actually ships:
    // only the 158 clip-backed signs may teach, and of those only the ones
    // inside a unit config reach the path. All five units now carry clips, so
    // none of them is filtered away: 112 signs across 5 units, renumbered 1..5.
    //
    // The gate itself is unchanged by that growth. It was built when only three
    // units had footage and the other two dropped off the path; the same
    // predicate now admits far more signs while still refusing any sign without
    // a bundled clip.
    late VocabIndex index;

    setUpAll(() async {
      index = VocabIndex.fromJsonString(
        await rootBundle.loadString(kVocabAssetPath),
      );
    });

    test('only the 158 clip-backed signs are playable', () {
      expect(index.count, 201);
      expect(index.videoEntries.length, 158);
      expect(
        index.videoEntries.every((VocabEntry e) => e.isVideoBacked),
        isTrue,
      );
    });

    test('a sign listed under several lessons is never half-video', () {
      // The course names the same sign in more than one lesson: GRACIAS is in
      // Leccion 2 and again in Leccion 5, CAFE in Leccion 1 and Leccion 4.
      // When the compiler claimed a clip for the first duplicate only, the app
      // shipped gracias.mp4 while the second entry told the user the video was
      // not available - for the very same word, one search away.
      //
      // Duplicates are legitimate in the curriculum, so this asserts they stay
      // CONSISTENT rather than pretending they do not exist.
      final Map<String, List<VocabEntry>> byGloss = <String, List<VocabEntry>>{};
      for (final VocabEntry e in index.entries) {
        byGloss.putIfAbsent(e.gloss, () => <VocabEntry>[]).add(e);
      }
      final Iterable<MapEntry<String, List<VocabEntry>>> duplicated =
          byGloss.entries.where(
              (MapEntry<String, List<VocabEntry>> e) => e.value.length > 1);

      // Guard the guard: if the curriculum ever stops repeating a sign, this
      // test would pass vacuously, so prove the duplicates are really there.
      expect(duplicated, isNotEmpty,
          reason: 'no duplicated gloss found, the consistency check is blind');

      for (final MapEntry<String, List<VocabEntry>> group in duplicated) {
        final Set<bool> states =
            group.value.map((VocabEntry e) => e.hasVideo).toSet();
        expect(
          states.length,
          1,
          reason: '${group.key} is listed ${group.value.length} times and '
              'disagrees about whether it has video',
        );
        for (final VocabEntry e in group.value) {
          expect(e.asset, isNotNull, reason: '${e.id} has no clip path');
        }
      }
    });

    test('the path is 112 signs across all 5 clip-backed units', () {
      final Curriculum curriculum = buildCurriculum(index.videoEntries);

      expect(
        curriculum.units
            .map((CurriculumUnit u) => '${u.number}: ${u.title}')
            .toList(),
        <String>[
          '1: Saludos y expresiones',
          '2: Números, colores y familia',
          '3: Tiempo, lugares y acciones',
          '4: Comida y animales',
          '5: Abecedario (dactilología)',
        ],
      );
      expect(
        curriculum.units
            .expand((CurriculumUnit u) => u.allSigns)
            .length,
        112,
      );
      // Numbering must be sequential with no gaps left by a filtered unit.
      expect(
        curriculum.units.map((CurriculumUnit u) => u.number).toList(),
        <int>[1, 2, 3, 4, 5],
      );
      // The invariant that matters is not WHICH units survive but that nothing
      // on the path can be dead. A unit with no footage is dropped, never
      // shipped empty; a sign with no clip never becomes playable content.
      for (final CurriculumUnit unit in curriculum.units) {
        expect(unit.allSigns, isNotEmpty, reason: '${unit.title} is empty');
        for (final PathNode node in unit.nodes) {
          for (final VocabEntry sign in node.signs) {
            expect(sign.isVideoBacked, isTrue, reason: '${sign.gloss} is dead');
          }
        }
      }
      // And the gate must not be leaking in the clip-less remainder.
      expect(
        index.videoEntries.length,
        lessThan(index.count),
        reason: 'a video-only index identical to the full one proves no gate',
      );
    });

    test('curriculumProvider builds that same 5-unit path (GATE A)', () async {
      // Goes through the real provider against the real asset, so a revert of
      // the provider back to `index.entries` fails HERE and not only in a
      // hypothetical. This is the gate, asserted at the gate.
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final Curriculum viaProvider =
          await container.read(curriculumProvider.future);

      // `allSigns` (lessons only, no BOSS duplicates) is what "112 signs" means.
      expect(
        viaProvider.units
            .map((CurriculumUnit u) => '${u.number}: ${u.title}')
            .toList(),
        <String>[
          '1: Saludos y expresiones',
          '2: Números, colores y familia',
          '3: Tiempo, lugares y acciones',
          '4: Comida y animales',
          '5: Abecedario (dactilología)',
        ],
      );
      expect(
        viaProvider.units
            .expand((CurriculumUnit u) => u.allSigns)
            .length,
        112,
      );
    });
  });

  group('dictionary coverage line (real assets)', () {
    // The dictionary states its own coverage instead of hiding the clip-less
    // 142 signs. This asserts the ACTUAL numbers the screen renders, so the
    // copy can never claim more video than actually ships.
    late VocabIndex index;

    setUpAll(() async {
      index = VocabIndex.fromJsonString(
        await rootBundle.loadString(kVocabAssetPath),
      );
    });

    test('browse-all states 201 signs and 158 with video', () {
      expect(
        dictionaryCoverageLine(index, index.entries, ''),
        '201 señas · 158 con video',
      );
    });

    test('a search keeps the matches and the total coverage visible', () {
      final List<VocabEntry> results =
          searchSigns(index.entries, 'casa');

      expect(results, isNotEmpty);
      expect(
        dictionaryCoverageLine(index, results, 'casa'),
        '${results.length} ${results.length == 1 ? 'resultado' : 'resultados'} '
        'de 201 señas · 158 con video',
      );
      // The coverage half is unchanged by the query — the point of the line.
      expect(
        dictionaryCoverageLine(index, results, 'casa'),
        contains('158 con video'),
      );
    });

    test('an empty search result still reports the coverage', () {
      expect(
        dictionaryCoverageLine(index, const <VocabEntry>[], 'zzz'),
        '0 resultados de 201 señas · 158 con video',
      );
    });

    test('the count never exceeds the number of clip-backed signs', () {
      expect(index.videoEntries.length, lessThan(index.count));
      expect(index.videoEntries.length, 158);
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
