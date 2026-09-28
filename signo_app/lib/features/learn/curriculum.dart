import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/lsc_vocab/lsc_vocab.dart';

/// Maximum number of signs in one lesson node on the path.
const int kMaxSignsPerLesson = 8;

/// Maximum number of exercises in a BOSS review session.
const int kBossExerciseCap = 10;

/// Kind of a node on the learning path.
enum NodeKind { lesson, boss }

/// One stop of the learning path: a lesson of ~5-8 signs or the unit's
/// final BOSS review.
class PathNode {
  const PathNode({
    required this.id,
    required this.title,
    required this.kind,
    required this.signs,
  });

  /// Stable id used for progress persistence (`u1-l1`, `u2-boss`, ...).
  final String id;
  final String title;
  final NodeKind kind;

  /// Signs practiced in this node, in deterministic (CSV) order.
  final List<VocabEntry> signs;

  bool get isBoss => kind == NodeKind.boss;
}

/// One of the units of the path: a header card plus a serpentine
/// sequence of lesson nodes ending in a BOSS review.
class CurriculumUnit {
  const CurriculumUnit({
    required this.number,
    required this.title,
    required this.nodes,
  });

  /// 1-based unit number (UNIDAD 1..5).
  final int number;
  final String title;
  final List<PathNode> nodes;

  /// Returns the unit's BOSS node, or null for an empty unit.
  PathNode? get boss {
    for (final PathNode node in nodes) {
      if (node.isBoss) {
        return node;
      }
    }
    return null;
  }

  /// Every sign of the unit (lessons only; the BOSS is a capped review).
  List<VocabEntry> get allSigns => <VocabEntry>[
        for (final PathNode node in nodes)
          if (!node.isBoss) ...node.signs,
      ];

  /// Whether every node of the unit (BOSS included) is completed.
  bool isComplete(Set<String> completedNodeIds) => nodes.isNotEmpty &&
      nodes.every((PathNode node) => completedNodeIds.contains(node.id));
}

/// The full learning path.
class Curriculum {
  const Curriculum(this.units);

  final List<CurriculumUnit> units;

  List<PathNode> get allNodes =>
      <PathNode>[for (final CurriculumUnit unit in units) ...unit.nodes];
}

/// Derived visual state of a node on the path.
enum PathNodeState { completed, active, locked }

/// Assigns sequential states: every completed id stays completed, the FIRST
/// non-completed node becomes the single active node, everything after it is
/// locked (spec `locked-node`: prerequisites incomplete → locked, no start).
List<PathNodeState> assignNodeStates(
  List<PathNode> nodes,
  Set<String> completedNodeIds,
) {
  bool activeAssigned = false;
  return List<PathNodeState>.generate(nodes.length, (int i) {
    final PathNode node = nodes[i];
    if (completedNodeIds.contains(node.id)) {
      return PathNodeState.completed;
    }
    if (!activeAssigned) {
      activeAssigned = true;
      return PathNodeState.active;
    }
    return PathNodeState.locked;
  });
}

/// Per-unit selection rule: which CSV rows feed the unit.
class _UnitConfig {
  const _UnitConfig(
    this.number,
    this.title,
    this.lessonNumber,
    this.subtemaAllowList,
  );

  final int number;
  final String title;

  /// MonikLSC lesson the unit draws from (U3/U4 take the whole lesson).
  final int lessonNumber;

  /// When non-null, only these normalized subtemas of [lessonNumber] are
  /// included (U1/U2/U5 split MonikLSC L1 between them).
  final Set<String>? subtemaAllowList;

  bool accepts(VocabEntry entry) {
    if (entry.lesson != lessonNumber) {
      return false;
    }
    final Set<String>? allow = subtemaAllowList;
    if (allow == null) {
      return true;
    }
    return allow.contains(normalizeForMatch(entry.subtema));
  }
}

const List<_UnitConfig> _unitConfigs = <_UnitConfig>[
  _UnitConfig(1, 'Saludos y expresiones', 1, <String>{
    'saludos informales',
    'saludos formales',
    'despedida',
    'tonalidades',
  }),
  _UnitConfig(2, 'Números, colores y familia', 1, <String>{
    'numeros',
    'colores',
    'familia',
    'calendario',
  }),
  _UnitConfig(3, 'Tiempo, lugares y acciones', 3, null),
  _UnitConfig(4, 'Comida y animales', 4, null),
  // Dactilología: the 27 alphabet clips the compiler expands out of the
  // single `Abecedarioa(A-Z)` spreadsheet row, each with its own video.
  _UnitConfig(5, 'Abecedario (dactilología)', 1, <String>{'abecedario'}),
];

/// Splits [signs] into [parts] near-equal chunks (deterministic; leftovers
/// go to the leading chunks).
List<List<VocabEntry>> _splitBalanced(List<VocabEntry> signs, int parts) {
  final List<List<VocabEntry>> chunks = <List<VocabEntry>>[];
  final int base = signs.length ~/ parts;
  final int remainder = signs.length % parts;
  int cursor = 0;
  for (int i = 0; i < parts; i++) {
    final int size = base + (i < remainder ? 1 : 0);
    chunks.add(signs.sublist(cursor, cursor + size));
    cursor += size;
  }
  return chunks;
}

const List<String> _roman = <String>[
  'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
];

/// Builds the 5-unit path from the compiled vocabulary.
///
/// Determinism contract: everything derives from the CSV order of [entries]
/// — subtema grouping keeps first-appearance order, oversized subtemas split
/// into near-equal parts, and adjacent parts merge while they fit within
/// [kMaxSignsPerLesson]. Each unit ends in a BOSS node reviewing (an evenly
/// spaced sample of) the unit's signs.
Curriculum buildCurriculum(List<VocabEntry> entries) {
  final List<CurriculumUnit> units = <CurriculumUnit>[];
  for (final _UnitConfig config in _unitConfigs) {
    final List<VocabEntry> unitSigns = <VocabEntry>[
      for (final VocabEntry entry in entries)
        if (config.accepts(entry)) entry,
    ];

    // Group by subtema, preserving first-appearance order.
    final Map<String, List<VocabEntry>> bySubtema =
        <String, List<VocabEntry>>{};
    for (final VocabEntry entry in unitSigns) {
      bySubtema.putIfAbsent(entry.subtema, () => <VocabEntry>[]).add(entry);
    }

    // Chunk oversized subtemas, then merge adjacent chunks that fit together.
    final List<(String, List<VocabEntry>)> chunks =
        <(String, List<VocabEntry>)>[];
    for (final MapEntry<String, List<VocabEntry>> group
        in bySubtema.entries) {
      final List<VocabEntry> signs = group.value;
      if (signs.length <= kMaxSignsPerLesson) {
        chunks.add((group.key, signs));
      } else {
        for (final List<VocabEntry> part
            in _splitBalanced(signs, (signs.length / kMaxSignsPerLesson)
                .ceil())) {
          chunks.add((group.key, part));
        }
      }
    }
    final List<List<(String, List<VocabEntry>)>> merged =
        <List<(String, List<VocabEntry>)>>[];
    for (final (String, List<VocabEntry>) chunk in chunks) {
      final int currentSize = merged.isEmpty
          ? 0
          : merged.last.fold(0, (int sum, c) => sum + c.$2.length);
      if (merged.isNotEmpty &&
          currentSize + chunk.$2.length <= kMaxSignsPerLesson) {
        merged.last.add(chunk);
      } else {
        merged.add(<(String, List<VocabEntry>)>[chunk]);
      }
    }

    // Lesson nodes with stable ids and plain titles.
    final List<PathNode> nodes = <PathNode>[];
    for (int i = 0; i < merged.length; i++) {
      final List<(String, List<VocabEntry>)> groups = merged[i];
      final Set<String> subtemas =
          <String>{for (final (String, List<VocabEntry>) g in groups) g.$1};
      final String primary = groups.first.$1;
      nodes.add(PathNode(
        id: 'u${config.number}-l${i + 1}',
        title: subtemas.length == 1 ? primary : '$primary y más',
        kind: NodeKind.lesson,
        signs: <VocabEntry>[
          for (final (String, List<VocabEntry>) g in groups) ...g.$2,
        ],
      ));
    }
    // Disambiguate repeated titles (`Números`, `Números` → `Números I/II`).
    final Map<String, int> titleCounts = <String, int>{};
    for (final PathNode node in nodes) {
      titleCounts.update(node.title, (int n) => n + 1, ifAbsent: () => 1);
    }
    final Map<String, int> titleSeen = <String, int>{};
    final List<PathNode> titled = <PathNode>[];
    for (final PathNode node in nodes) {
      if (titleCounts[node.title]! > 1) {
        final int part = (titleSeen[node.title] ?? 0) + 1;
        titleSeen[node.title] = part;
        titled.add(PathNode(
          id: node.id,
          title: '${node.title} ${_roman[part - 1]}',
          kind: node.kind,
          signs: node.signs,
        ));
      } else {
        titled.add(node);
      }
    }

    // BOSS review: evenly spaced sample of the unit's signs.
    if (unitSigns.isNotEmpty) {
      titled.add(PathNode(
        id: 'u${config.number}-boss',
        title: 'Repaso de unidad',
        kind: NodeKind.boss,
        signs: sampleEvenly(unitSigns, kBossExerciseCap),
      ));
    }

    units.add(CurriculumUnit(
      number: config.number,
      title: config.title,
      nodes: titled,
    ));
  }
  return Curriculum(units);
}

/// Picks at most [cap] entries, evenly spaced across [signs] (deterministic,
/// keeps the first and spreads over the whole range).
List<VocabEntry> sampleEvenly(List<VocabEntry> signs, int cap) {
  if (signs.length <= cap) {
    return List<VocabEntry>.of(signs);
  }
  return List<VocabEntry>.generate(
    cap,
    (int i) => signs[(i * signs.length) ~/ cap],
  );
}

/// Human-facing Spanish word for an entry, derived from its gloss
/// (`BUENOS-DIAS` → `Buenos dias`). Sentence case: only the first letter is
/// capitalized. Accents are already stripped by the compile pipeline;
/// restoring them is deferred to video curation (T4).
String displayWordFor(VocabEntry entry) {
  final String spaced = entry.gloss.toLowerCase().replaceAll('-', ' ');
  final StringBuffer buffer = StringBuffer();
  bool capitalized = false;
  for (final int rune in spaced.runes) {
    final String ch = String.fromCharCode(rune);
    if (!capitalized && ch.trim().isNotEmpty) {
      buffer.write(ch.toUpperCase());
      capitalized = true;
    } else {
      buffer.write(ch);
    }
  }
  return buffer.toString();
}

/// Path availability, derived from the compiled vocabulary index.
final FutureProvider<Curriculum> curriculumProvider =
    FutureProvider<Curriculum>((Ref ref) async {
  final VocabIndex index = await ref.watch(vocabIndexProvider.future);
  return buildCurriculum(index.entries);
});
