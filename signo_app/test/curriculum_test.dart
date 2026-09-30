import 'package:flutter_test/flutter_test.dart';
import 'package:signo_app/core/lsc_vocab/lsc_vocab.dart';
import 'package:signo_app/features/learn/curriculum.dart';

/// Fixture mirroring the real MonikLSC shape: U1/U2/U5 split L1 by subtema,
/// U3 = L3, U4 = L4; L2 and L5 rows exist but feed NO unit. Row order is
/// CSV order — the determinism source.
///
/// Every sign is clip-backed, because that is what `curriculumProvider` feeds
/// `buildCurriculum` (`VocabIndex.videoEntries`). The chunking contract is what
/// these tests are about; the video-only contract is pinned separately, in
/// [buildCurriculum drops a unit whose signs are all clip-less].
VocabEntry entry(
  String id,
  String gloss,
  int lesson,
  String subtema,
) =>
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[normalizeForMatch(gloss)],
      lesson: lesson,
      subtema: subtema,
      hasVideo: true,
      asset: 'assets/signs/$id.mp4',
    );

/// Deliberately clip-less twin of [entry]. Used ONLY where the point of the
/// test is a sign the app cannot play — never as filler, because filler that
/// is clip-less would be silently dropped by the video-only gate and change
/// the expectations these chunking tests were written against.
VocabEntry clipLessEntry(
  String id,
  String gloss,
  int lesson,
  String subtema,
) =>
    VocabEntry(
      id: id,
      gloss: gloss,
      lemmas: <String>[normalizeForMatch(gloss)],
      lesson: lesson,
      subtema: subtema,
      hasVideo: false,
    );

final List<VocabEntry> fixture = <VocabEntry>[
  // L1 — U1 subtemas (10 signs: 2+2+3+3) plus one U5 alphabet sign.
  entry('s1', 'HOLA', 1, 'Saludos informales'),
  entry('s2', 'QUE-TAL', 1, 'Saludos informales'),
  entry('s3', 'CHAU', 1, 'Despedida'),
  entry('s4', 'HASTA-LUEGO', 1, 'Despedida'),
  entry('s5', 'BUENOS-DIAS', 1, 'Saludos formales'),
  entry('s6', 'BUENAS-TARDES', 1, 'Saludos formales'),
  entry('s7', 'BUENAS-NOCHES', 1, 'Saludos formales'),
  entry('s8', 'A', 1, 'Abecedario'),
  entry('s9', 'TONO1', 1, 'Tonalidades'),
  entry('s10', 'TONO2', 1, 'Tonalidades'),
  entry('s11', 'TONO3', 1, 'Tonalidades'),
  // L1 — U2 subtemas (33 signs: numeros 9, colores 11, familia 8, calendario 5).
  ...List<VocabEntry>.generate(
    9,
    (int i) => entry('n$i', 'NUM$i', 1, 'Números'),
  ),
  ...List<VocabEntry>.generate(
    11,
    (int i) => entry('c$i', 'COLOR$i', 1, 'Colores'),
  ),
  ...List<VocabEntry>.generate(
    8,
    (int i) => entry('f$i', 'FAM$i', 1, 'Familia'),
  ),
  ...List<VocabEntry>.generate(
    5,
    (int i) => entry('k$i', 'CAL$i', 1, 'Calendario'),
  ),
  // L2 — excluded from the path entirely.
  entry('x1', 'CLAS1', 2, 'Clasificadores'),
  entry('x2', 'TIPO1', 2, 'Tipos de señas'),
  // L3 — U3 (sujeto 7, acciones 15, tiempo 8, lugar 6 → here smaller counts).
  ...List<VocabEntry>.generate(
    7,
    (int i) => entry('su$i', 'SUJ$i', 3, 'Sujeto'),
  ),
  ...List<VocabEntry>.generate(
    15,
    (int i) => entry('a$i', 'ACC$i', 3, 'Acciones'),
  ),
  ...List<VocabEntry>.generate(
    8,
    (int i) => entry('t$i', 'TIE$i', 3, 'Tiempo'),
  ),
  ...List<VocabEntry>.generate(
    6,
    (int i) => entry('l$i', 'LUG$i', 3, 'Lugar'),
  ),
  // L4 — U4 (comida 9, animales 5, ciudad 1).
  ...List<VocabEntry>.generate(
    9,
    (int i) => entry('co$i', 'COM$i', 4, 'Comida'),
  ),
  ...List<VocabEntry>.generate(
    5,
    (int i) => entry('an$i', 'ANI$i', 4, 'Animales'),
  ),
  entry('ci1', 'CIUDAD', 4, 'Ciudad'),
  // L5 — excluded.
  entry('q1', 'QUE', 5, 'Preguntas'),
];

Curriculum build() => buildCurriculum(fixture);

void main() {
  group('buildCurriculum', () {
    test('produces exactly the 5 designed units with designed titles', () {
      final Curriculum curriculum = build();
      expect(curriculum.units.length, 5);
      expect(
        curriculum.units.map((CurriculumUnit u) => u.title).toList(),
        <String>[
          'Saludos y expresiones',
          'Números, colores y familia',
          'Tiempo, lugares y acciones',
          'Comida y animales',
          'Abecedario (dactilología)',
        ],
      );
    });

    test('U1 merges its small L1 subtemas into ~5-8 sign lessons', () {
      final CurriculumUnit u1 = build().units[0];
      final List<PathNode> lessons = u1.nodes
          .where((PathNode n) => !n.isBoss)
          .toList();
      // 10 signs in subtemas of 2/2/3/3 (CSV order) merge greedily ≤ 8.
      expect(lessons.length, 2);
      expect(lessons[0].signs.length, 7);
      expect(lessons[1].signs.length, 3);
      expect(lessons.expand((PathNode n) => n.signs).length, 10);
    });

    test('U5 takes the alphabet out of U1 as its own dactilology unit', () {
      final Curriculum curriculum = build();
      final CurriculumUnit u5 = curriculum.units[4];
      expect(u5.number, 5);
      expect(
        u5.allSigns.map((VocabEntry e) => e.id).toList(),
        <String>['s8'],
      );
      expect(u5.boss, isNotNull);
      // The alphabet is not duplicated inside U1.
      expect(
        curriculum.units[0].allSigns.map((VocabEntry e) => e.id),
        isNot(contains('s8')),
      );
    });

    test('a full 27-letter alphabet splits into capped lessons plus a BOSS',
        () {
      final List<VocabEntry> letters = <VocabEntry>[
        for (int i = 0; i < 27; i++)
          entry('L${i.toString().padLeft(2, '0')}', 'LETRA$i', 1, 'Abecedario'),
      ];
      // U1–U4 hold no alphabet sign at all, so the video-only view leaves the
      // dactilología unit as the ONLY unit — and renumbered to 1.
      final CurriculumUnit u5 = buildCurriculum(
        VocabIndex.build(letters).videoEntries,
      ).units.single;
      final List<PathNode> lessons =
          u5.nodes.where((PathNode n) => !n.isBoss).toList();

      expect(u5.number, 1, reason: 'renumbered: it is the first unit now');
      expect(u5.title, 'Abecedario (dactilología)');
      expect(u5.allSigns.length, 27);
      // ceil(27 / 8) = 4 lessons, none over the cap, and a BOSS after them.
      expect(lessons.length, 4);
      expect(lessons.every(
          (PathNode n) => n.signs.length <= kMaxSignsPerLesson), isTrue);
      expect(u5.nodes.last.isBoss, isTrue);
    });

    test('every lesson node holds at most kMaxSignsPerLesson signs', () {
      for (final CurriculumUnit unit in build().units) {
        for (final PathNode node in unit.nodes) {
          if (!node.isBoss) {
            expect(node.signs.length,
                lessThanOrEqualTo(kMaxSignsPerLesson));
          }
        }
      }
    });

    test('each unit ends in a BOSS node reviewing capped unit signs', () {
      final Curriculum curriculum = build();
      for (final CurriculumUnit unit in curriculum.units) {
        final PathNode boss = unit.nodes.last;
        expect(boss.isBoss, isTrue);
        expect(boss.kind, NodeKind.boss);
        expect(boss.signs.length,
            lessThanOrEqualTo(kBossExerciseCap));
        expect(unit.nodes.where((PathNode n) => n.isBoss).length, 1);
        // Every BOSS sign belongs to the unit.
        final Set<String> unitIds = <String>{
          for (final VocabEntry e in unit.allSigns) e.id,
        };
        for (final VocabEntry sign in boss.signs) {
          expect(unitIds.contains(sign.id), isTrue);
        }
      }
      // U4 has 15 unit signs → BOSS capped at 10.
      expect(build().units[3].nodes.last.signs.length, 10);
    });

    test('split subtemas get disambiguated roman-numeral titles', () {
      // Números (9) splits 5+4 → two pure lessons → `Números I/II`.
      final List<String> u2Titles = build()
          .units[1]
          .nodes
          .map((PathNode n) => n.title)
          .toList();
      expect(u2Titles.contains('Números I'), isTrue);
      expect(u2Titles.contains('Números II'), isTrue);
    });

    test('L2 and L5 rows are excluded from the path', () {
      final Set<String> allIds = <String>{
        for (final PathNode node in build().allNodes)
          ...node.signs.map((VocabEntry e) => e.id),
      };
      expect(allIds.contains('x1'), isFalse);
      expect(allIds.contains('x2'), isFalse);
      expect(allIds.contains('q1'), isFalse);
    });

    test('U3 and U4 take their whole MonikLSC lesson', () {
      final Curriculum curriculum = build();
      final Set<String> u3Ids = <String>{
        for (final VocabEntry e in curriculum.units[2].allSigns) e.id,
      };
      expect(u3Ids.contains('su0'), isTrue);
      expect(u3Ids.contains('l5'), isTrue);
      final Set<String> u4Ids = <String>{
        for (final VocabEntry e in curriculum.units[3].allSigns) e.id,
      };
      expect(u4Ids.contains('ci1'), isTrue);
    });

    test('node ids are deterministic and stable', () {
      final List<String> ids = <String>[
        for (final PathNode node in build().allNodes) node.id,
      ];
      expect(ids.first, 'u1-l1');
      expect(ids, <String>[
        for (final PathNode node in build().allNodes) node.id,
      ]);
      expect(ids.where((String id) => id.endsWith('boss')).length, 5);
    });

    test('building twice yields identical structures', () {
      final Curriculum a = build();
      final Curriculum b = buildCurriculum(fixture);
      expect(a.allNodes.length, b.allNodes.length);
      for (int i = 0; i < a.allNodes.length; i++) {
        expect(a.allNodes[i].id, b.allNodes[i].id);
        expect(a.allNodes[i].title, b.allNodes[i].title);
        expect(
          a.allNodes[i].signs.map((VocabEntry e) => e.id).toList(),
          b.allNodes[i].signs.map((VocabEntry e) => e.id).toList(),
        );
      }
    });
  });

  group('video-only contract', () {
    test('buildCurriculum drops a unit whose signs are all clip-less', () {
      // Real shape of the shipped content: U2 (números/colores/familia) and
      // U4 (comida/animales) have zero bundled clips today, so they must not
      // appear on the path at all — no header card, no nodes, no BOSS.
      final List<VocabEntry> withClipLessUnits = <VocabEntry>[
        entry('s1', 'HOLA', 1, 'Saludos informales'),
        entry('s2', 'CHAU', 1, 'Despedida'),
        // U2 — every row clip-less.
        clipLessEntry('n0', 'NUM0', 1, 'Números'),
        clipLessEntry('c0', 'COLOR0', 1, 'Colores'),
        // U3 — playable.
        entry('a0', 'ACC0', 3, 'Acciones'),
        entry('a1', 'ACC1', 3, 'Acciones'),
        // U4 — every row clip-less.
        clipLessEntry('co0', 'COM0', 4, 'Comida'),
        clipLessEntry('an0', 'ANI0', 4, 'Animales'),
        // U5 — playable.
        entry('l0', 'LETRA0', 1, 'Abecedario'),
      ];

      // The real path: video-only view of the complete index, then build.
      final VocabIndex index = VocabIndex.build(withClipLessUnits);
      final Curriculum curriculum = buildCurriculum(index.videoEntries);

      expect(
        curriculum.units
            .map((CurriculumUnit u) => u.title)
            .toList(),
        <String>[
          'Saludos y expresiones',
          'Tiempo, lugares y acciones',
          'Abecedario (dactilología)',
        ],
        reason: 'U2 and U4 are gone entirely',
      );
    });

    test('surviving units are renumbered 1..N with no gaps', () {
      // Otherwise the learner would read "UNIDAD 1 … UNIDAD 3 … UNIDAD 5"
      // with no UNIDAD 2 anywhere, and a chest claim keyed on unit 3 or 5
      // would never line up with what is on screen.
      final VocabIndex index = VocabIndex.build(<VocabEntry>[
        entry('s1', 'HOLA', 1, 'Saludos informales'),
        clipLessEntry('n0', 'NUM0', 1, 'Números'),
        clipLessEntry('n1', 'NUM1', 1, 'Números'),
        entry('a0', 'ACC0', 3, 'Acciones'),
        clipLessEntry('co0', 'COM0', 4, 'Comida'),
        entry('l0', 'LETRA0', 1, 'Abecedario'),
      ]);
      final Curriculum curriculum = buildCurriculum(index.videoEntries);

      expect(
        curriculum.units.map((CurriculumUnit u) => u.number).toList(),
        <int>[1, 2, 3],
      );
      // Node ids follow the renumbered unit, so progress keys stay consistent
      // with the header the learner is looking at.
      for (final CurriculumUnit unit in curriculum.units) {
        for (final PathNode node in unit.nodes) {
          expect(node.id, startsWith('u${unit.number}-'));
        }
      }
      expect(
        curriculum.allNodes.map((PathNode n) => n.id).toList(),
        <String>['u1-l1', 'u1-boss', 'u2-l1', 'u2-boss', 'u3-l1', 'u3-boss'],
      );
    });

    test('a sign that keeps only the flag but no clip path is still dropped',
        () {
      // `hasVideo` alone is not enough: without a path there is nothing for
      // the player to load, so the entry is not playable and not taught.
      const VocabEntry ghost = VocabEntry(
        id: 'g0',
        gloss: 'GHOST',
        lemmas: <String>['ghost'],
        lesson: 1,
        subtema: 'Números',
        hasVideo: true, // flag set…
      ); // …but `asset` stays null.
      expect(ghost.isVideoBacked, isFalse);
      expect(
        buildCurriculum(VocabIndex.build(<VocabEntry>[ghost]).videoEntries)
            .units,
        isEmpty,
      );
    });

    test('no node on the built path ever holds a clip-less sign', () {
      // The invariant in its most direct form: whatever the input, every sign
      // reachable from the path can actually be played.
      final VocabIndex index = VocabIndex.build(<VocabEntry>[
        ...fixture.take(5).map((VocabEntry e) => e),
        clipLessEntry('ghost1', 'GHOST1', 1, 'Números'),
        clipLessEntry('ghost2', 'GHOST2', 4, 'Comida'),
      ]);
      for (final PathNode node in buildCurriculum(index.videoEntries).allNodes) {
        for (final VocabEntry sign in node.signs) {
          expect(sign.isVideoBacked, isTrue, reason: '${sign.gloss} is dead');
        }
      }
    });
  });

  group('assignNodeStates (spec locked-node scenario)', () {
    test('empty progress: first node active, everything else locked', () {
      final List<PathNodeState> states =
          assignNodeStates(build().allNodes, <String>{});
      expect(states.first, PathNodeState.active);
      expect(states.skip(1).every((PathNodeState s) => s == PathNodeState.locked), isTrue);
    });

    test('completing a node activates the next one in sequence', () {
      final Curriculum curriculum = build();
      final List<PathNode> nodes = curriculum.allNodes;
      final List<PathNodeState> states = assignNodeStates(
        nodes,
        <String>{nodes.first.id},
      );
      expect(states[0], PathNodeState.completed);
      expect(states[1], PathNodeState.active);
      expect(states.skip(2).every((PathNodeState s) => s == PathNodeState.locked), isTrue);
    });

    test('finishing a unit BOSS unlocks the next unit start', () {
      final Curriculum curriculum = build();
      final List<PathNode> nodes = curriculum.allNodes;
      final int u1Boss = nodes.indexWhere((PathNode n) => n.isBoss);
      final List<PathNodeState> states = assignNodeStates(
        nodes,
        <String>{for (int i = 0; i <= u1Boss; i++) nodes[i].id},
      );
      expect(states[u1Boss], PathNodeState.completed);
      // Exactly one active node: the first lesson of the next unit.
      expect(states[u1Boss + 1], PathNodeState.active);
      expect(
        states.where((PathNodeState s) => s == PathNodeState.active).length,
        1,
      );
    });

    test('fully completed path has no locked or active nodes', () {
      final Curriculum curriculum = build();
      final List<PathNodeState> states = assignNodeStates(
        curriculum.allNodes,
        <String>{for (final PathNode n in curriculum.allNodes) n.id},
      );
      expect(states.every((PathNodeState s) => s == PathNodeState.completed),
          isTrue);
    });
  });

  group('sampleEvenly + displayWordFor', () {
    test('sampleEvenly returns distinct capped entries in order', () {
      final List<VocabEntry> sampled =
          sampleEvenly(fixture, kBossExerciseCap);
      expect(sampled.length, kBossExerciseCap);
      final Set<String> ids = <String>{for (final VocabEntry e in sampled) e.id};
      expect(ids.length, kBossExerciseCap);
    });

    test('sampleEvenly passes through short lists untouched', () {
      final List<VocabEntry> head = fixture.sublist(0, 3);
      expect(sampleEvenly(head, 10).map((VocabEntry e) => e.id).toList(),
          head.map((VocabEntry e) => e.id).toList());
    });

    test('displayWordFor humanizes glosses', () {
      expect(
        displayWordFor(entry('d', 'BUENOS-DIAS', 1, 'Saludos formales')),
        'Buenos dias',
      );
      expect(
        displayWordFor(entry('h', 'HOLA', 1, 'Saludos informales')),
        'Hola',
      );
    });
  });
}
