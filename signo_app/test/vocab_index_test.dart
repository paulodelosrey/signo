import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';

const String _fixtureJson = '''
{
  "source": "test fixture",
  "count": 4,
  "signs": [
    {"id": "l3-001", "gloss": "CASA", "lemmas": ["casa"], "lesson": 3, "subtema": "Lugar", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-001", "gloss": "TIO", "lemmas": ["tio", "tia"], "lesson": 1, "subtema": "Familia", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-005", "gloss": "BUENOS-DIAS", "lemmas": ["buenos", "dias"], "lesson": 1, "subtema": "Saludos formales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false},
    {"id": "l1-002", "gloss": "CAFE-DUP", "lemmas": ["cafe"], "lesson": 4, "subtema": "Comida", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false}
  ]
}
''';

/// Mixed fixture: one clip-backed sign, one claiming a clip with no path, one
/// plainly clip-less. Exercises the video-only gate without a real asset.
const String _mixedJson = '''
{
  "source": "test fixture",
  "count": 3,
  "signs": [
    {"id": "v1", "gloss": "HOLA", "lemmas": ["hola"], "lesson": 1, "subtema": "Saludos informales", "asset": "assets/signs/hola.mp4", "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true},
    {"id": "v2", "gloss": "GHOST", "lemmas": ["ghost"], "lesson": 1, "subtema": "Saludos informales", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": true},
    {"id": "v3", "gloss": "CASA", "lemmas": ["casa"], "lesson": 3, "subtema": "Lugar", "asset": null, "releasePath": null, "trimStartMs": null, "trimEndMs": null, "hasVideo": false}
  ]
}
''';

void main() {
  group('VocabIndex', () {
    test('builds from JSON string with all entries', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      expect(index.count, 4);
      expect(index.entries.map((VocabEntry e) => e.gloss),
          containsAll(<String>['CASA', 'TIO', 'BUENOS-DIAS']));
    });

    test('resolves lemmas and gloss labels case-insensitively', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      expect(index.lookup('casa')!.id, 'l3-001');
      expect(index.lookup('CASA')!.id, 'l3-001');
      expect(index.lookupLemma('dias')!.gloss, 'BUENOS-DIAS');
    });

    test('exposes gender variants as separate lemmas of one entry', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      final VocabEntry? viaMasculine = index.lookupLemma('tio');
      final VocabEntry? viaFeminine = index.lookupLemma('tia');
      expect(viaMasculine, isNotNull);
      expect(viaFeminine, isNotNull);
      expect(viaMasculine!.id, viaFeminine!.id);
    });

    test('first entry wins when two signs share a lemma', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      // The fixture deliberately declares CAFE-DUP with no earlier CAFE
      // sibling, so it owns the lemma; add one to prove first-wins.
      final VocabIndex withDuplicate = VocabIndex.build(<VocabEntry>[
        const VocabEntry(
          id: 'l1-009',
          gloss: 'CAFE',
          lemmas: <String>['cafe'],
          lesson: 1,
          subtema: 'Colores',
          hasVideo: false,
        ),
        const VocabEntry(
          id: 'l4-008',
          gloss: 'CAFE-DUP',
          lemmas: <String>['cafe'],
          lesson: 4,
          subtema: 'Comida',
          hasVideo: false,
        ),
      ]);

      expect(withDuplicate.lookupLemma('cafe')!.id, 'l1-009');
      expect(index.count, 4);
    });

    test('returns null for unknown lemmas without throwing', () {
      final VocabIndex index = VocabIndex.fromJsonString(_fixtureJson);

      expect(index.lookup('telescopio'), isNull);
      expect(index.lookup(''), isNull);
    });
  });

  group('video-only index (the product rule)', () {
    // Deliberately mixed: a clip-backed sign, a sign whose manifest row claims
    // a clip but carries no path, and a plainly clip-less sign. The second one
    // is why `isVideoBacked` is not just `hasVideo`.
    final List<VocabEntry> mixed = <VocabEntry>[
      const VocabEntry(
        id: 'v1',
        gloss: 'HOLA',
        lemmas: <String>['hola'],
        lesson: 1,
        subtema: 'Saludos informales',
        asset: 'assets/signs/hola.mp4',
        hasVideo: true,
      ),
      const VocabEntry(
        id: 'v2',
        gloss: 'GHOST',
        lemmas: <String>['ghost'],
        lesson: 1,
        subtema: 'Saludos informales',
        // Claims a clip in the manifest but no path to load it from.
        hasVideo: true,
      ),
      const VocabEntry(
        id: 'v3',
        gloss: 'CASA',
        lemmas: <String>['casa'],
        lesson: 3,
        subtema: 'Lugar',
        hasVideo: false,
      ),
    ];

    test('isVideoBacked requires the flag AND the clip path', () {
      expect(mixed[0].isVideoBacked, isTrue);
      expect(mixed[1].isVideoBacked, isFalse, reason: 'flag without a path');
      expect(mixed[2].isVideoBacked, isFalse, reason: 'no flag at all');
    });

    test('videoEntries keeps first-appearance order and drops clip-less signs',
        () {
      final VocabIndex index = VocabIndex.build(mixed);

      expect(index.count, 3, reason: 'the complete index still holds all three');
      expect(
        index.videoEntries.map((VocabEntry e) => e.id).toList(),
        <String>['v1'],
      );
    });

    test('a video-only index cannot resolve a clip-less lemma', () {
      final VocabIndex videoOnly = VocabIndex.build(mixed, videoOnly: true);

      expect(videoOnly.lookup('hola')!.id, 'v1');
      expect(videoOnly.lookupLemma('casa'), isNull);
      expect(videoOnly.lookupLemma('ghost'), isNull);
      expect(videoOnly.count, 1);
    });

    test('the complete index still resolves clip-less lemmas (dictionary)',
        () {
      // The dictionary is the ONE surface allowed to show a clip-less sign, so
      // it must keep resolving them. This is the half of the rule that says
      // the gate is a filter, not a deletion of content.
      final VocabIndex complete = VocabIndex.fromJsonString(_fixtureJson);

      expect(complete.lookup('casa')!.id, 'l3-001');
      expect(complete.lookup('buenos')!.id, 'l1-005');
    });

    test('copyWithVideoOnly matches build(videoOnly: true) without re-parsing',
        () {
      final VocabIndex fromParse = VocabIndex.fromJsonString(_mixedJson);
      final VocabIndex view = fromParse.copyWithVideoOnly();
      final VocabIndex rebuilt = VocabIndex.build(fromParse.entries, videoOnly: true);

      expect(
        view.entries.map((VocabEntry e) => e.id).toList(),
        rebuilt.entries.map((VocabEntry e) => e.id).toList(),
      );
      expect(view.lookupLemma('casa'), isNull);
      expect(view.lookupLemma('hola')!.id, 'v1');
      // The source index is untouched: a view never mutates its origin.
      expect(fromParse.count, 3);
      expect(fromParse.lookupLemma('casa')!.id, 'v3');
    });

    test('a shared lemma promotes the clip-backed sign instead of vanishing',
        () {
      // CAFE exists in two lessons; only the second ships a clip. Filtering the
      // lemma MAP would delete `cafe` and hide a sign that can be played, so
      // the map is re-derived from the survivors instead.
      final VocabIndex index = VocabIndex.build(<VocabEntry>[
        const VocabEntry(
          id: 'c1',
          gloss: 'CAFE',
          lemmas: <String>['cafe'],
          lesson: 1,
          subtema: 'Colores',
          hasVideo: false,
        ),
        const VocabEntry(
          id: 'c2',
          gloss: 'CAFE',
          lemmas: <String>['cafe'],
          lesson: 4,
          subtema: 'Comida',
          asset: 'assets/signs/cafe.mp4',
          hasVideo: true,
        ),
      ], videoOnly: true);

      expect(index.count, 1);
      expect(index.lookup('cafe')!.id, 'c2');
    });
  });

  group('GrammarRuleSet', () {
    test('parses categories normalized and resolves rules in order', () {
      final GrammarRuleSet rules = GrammarRuleSet.fromJson(<String, Object?>{
        'provenance': <String, Object?>{'note': 'fixture'},
        'categories': <String, Object?>{
          'copula': <String>['Es', 'SOY'],
          'connectors': <String>['y'],
        },
        'rules': <Object?>[
          <String, Object?>{
            'id': 'drop-copula',
            'match': <String, Object?>{'category': 'copula'},
            'action': 'drop',
          },
          <String, Object?>{
            'id': 'drop-connectors',
            'match': <String, Object?>{'category': 'connectors'},
            'action': 'drop',
          },
        ],
      });

      expect(rules.matchRule('es')!.id, 'drop-copula');
      expect(rules.matchRule('soy')!.id, 'drop-copula');
      expect(rules.matchRule('y')!.id, 'drop-connectors');
      expect(rules.matchRule('casa'), isNull);
      expect(rules.categoryWords('missing'), isEmpty);
      expect(rules.provenanceNote, 'fixture');
    });
  });
}
