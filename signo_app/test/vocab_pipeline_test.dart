import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

// The compiler lives under tool/ (build-time script), outside lib/, so a
// relative import is required.
import '../tool/parse_vocab.dart' as parser;

/// In-memory CSV fixture mirroring the real MonikLSC spreadsheet shape
/// (4 columns, accented Latin text, placeholder rows, inline variants).
const String _fixtureCsv = '''
Lección #,Subtema,Video / seña disponible,Estado
Lección 1,Familia,Papá,Registrado
Lección 1,Familia,Tío/a,Registrado
Lección 1,Colores,Café,Registrado
Lección 1,Notas,Sin señas,Registrado
Lección 2,Notas,Imágenes de rasgos no manuales,Registrado
Lección 2,Tipos de señas,Buenas tardes,Registrado
Lección 2,Tipos de señas,Gracias,Registrado
Lección 5,Frases comunes,Gracias,Registrado
Lección 5,Preguntas,¿Cuál?,Registrado
Lección 1,Rasgos distintivos,,Falta grabar / registrar seña
''';

void main() {
  group('decodeSpreadsheetBytes', () {
    test('decodes UTF-8 bytes including BOM', () {
      final List<int> bytes = utf8.encode('Lección');
      // Prepend a UTF-8 BOM.
      final List<int> withBom = <int>[0xEF, 0xBB, 0xBF, ...bytes];

      expect(parser.decodeSpreadsheetBytes(withBom), 'Lección');
    });

    test('falls back to Latin-1 when bytes are not valid UTF-8', () {
      // 0xF3 is 'ó' in Latin-1 and invalid as a standalone UTF-8 byte.
      final List<int> latin1Bytes = <int>[0x4C, 0xF3, 0x6E]; // "Lón"

      expect(parser.decodeSpreadsheetBytes(latin1Bytes), 'Lón');
    });
  });

  group('compileVocab', () {
    late parser.CompileResult result;

    setUp(() {
      result = parser.compileVocab(_fixtureCsv);
    });

    test('compiles only lexical signs, skipping notes and empty cells', () {
      expect(result.totalRows, 10);
      expect(result.signs.length, 7);
      expect(result.placeholderRows.length, 2);
      expect(result.missingSignRows.length, 1);
    });

    test('strips accents for glosses and keeps both gender variants', () {
      final parser.CompiledSign papa =
          result.signs.firstWhere((parser.CompiledSign s) => s.gloss == 'PAPA');
      final parser.CompiledSign tio = result.signs
          .firstWhere((parser.CompiledSign s) => s.gloss == 'TIO');

      expect(papa.lemmas, <String>['papa']);
      expect(tio.lemmas, containsAll(<String>['tio', 'tia']));
    });

    test('strips punctuation and annotations from question signs', () {
      final parser.CompiledSign cual =
          result.signs.firstWhere((parser.CompiledSign s) => s.gloss == 'CUAL');

      expect(cual.lemmas, <String>['cual']);
      expect(cual.subtema, 'Preguntas');
    });

    test('builds compound glosses from multi-word signs', () {
      final parser.CompiledSign buenasTardes = result.signs
          .firstWhere((parser.CompiledSign s) => s.gloss == 'BUENAS-TARDES');

      expect(buenasTardes.lemmas, containsAll(<String>['buenas', 'tardes']));
      expect(buenasTardes.lesson, 2);
    });

    test('reports duplicate glosses across lessons', () {
      expect(result.duplicateGlosses.keys, <String>['GRACIAS']);
      expect(result.duplicateGlosses['GRACIAS'], <int>[2, 5]);
    });

    test('emits stable sequential ids in CSV order', () {
      expect(result.signs.map((parser.CompiledSign s) => s.id).take(3),
          <String>['l1-001', 'l1-002', 'l1-003']);
    });

    test('tracks lesson coverage including empty lessons', () {
      expect(result.perLesson[1], 3);
      expect(result.perLesson[2], 2);
      expect(result.perLesson[5], 2);
      expect(result.perLesson.containsKey(3), isFalse);
    });

    test('leaves hasVideo false without a clip manifest', () {
      expect(result.signs.every((parser.CompiledSign s) => !s.hasVideo), isTrue);
      expect(result.assets.matchedIds, isEmpty);
    });

    test('slugify folds glosses, lemmas and clip stems to one key', () {
      expect(parser.slugify('BUENOS-DIAS'), 'buenos_dias');
      expect(parser.slugify('cómo_pregunta'), 'como_pregunta');
      expect(parser.slugify('Perdón'), 'perdon');
    });

    test('parses the manifest into slugs with folder provenance', () {
      final List<parser.SignClip> clips = parser.parseSignManifest('''
[{"asset":"assets/signs/que_pregunta.mp4","folder":"FRASES COMUNES",
  "source":"qué_pregunta.mp4","bytes":89731},
 {"asset":"assets/signs/n_tilde.mp4","folder":"ABECEDARIO",
  "source":"Ñ.mp4","bytes":16000}]
''');

      expect(clips.map((parser.SignClip c) => c.slug),
          <String>['que_pregunta', 'n_tilde']);
      expect(clips.first.isPregunta, isTrue);
      expect(clips.last.isPregunta, isFalse);
      expect(clips.first.assetPath, 'assets/signs/que_pregunta.mp4');
    });

    test('expands the aggregate alphabet row into one sign per clip', () {
      final List<parser.SignClip> clips = <parser.SignClip>[
        for (final String letter in <String>['a', 'b', 'c', 'n', 'n_tilde'])
          parser.SignClip(
            slug: letter,
            assetPath: 'assets/signs/$letter.mp4',
            folder: 'ABECEDARIO',
          ),
      ];
      final parser.CompileResult alphabet = parser.compileVocab(
        'Lección #,Subtema,Video / seña disponible,Estado\n'
        'Lección 1,Abecedario,Abecedarioa(A-Z),\n'
        'Lección 1,Saludos informales,Hola,Registrado\n',
        clips: clips,
      );

      expect(alphabet.signs.length, 6); // 5 letters + HOLA, no aggregate row.
      expect(alphabet.signs.map((parser.CompiledSign s) => s.gloss).toList(),
          <String>['A', 'B', 'C', 'N', 'Ñ', 'HOLA']);
      expect(alphabet.signs[4].lemmas, <String>['ñ']);
      expect(alphabet.signs[4].asset, 'assets/signs/n_tilde.mp4');
      expect(alphabet.signs[4].hasVideo, isTrue);
      // The last row keeps the sequential id scheme.
      expect(alphabet.signs.last.id, 'l1-006');
    });

    test('*_pregunta clips map onto the existing sign instead of duplicating '
        'it', () {
      final parser.CompileResult mapped = parser.compileVocab(
        'Lección #,Subtema,Video / seña disponible,Estado\n'
        'Lección 5,Preguntas,¿Dónde?,Registrado\n',
        clips: <parser.SignClip>[
          parser.SignClip(
            slug: 'donde_pregunta',
            assetPath: 'assets/signs/donde_pregunta.mp4',
            folder: 'FRASES COMUNES',
          ),
        ],
      );

      expect(mapped.signs.length, 1, reason: 'the question clip must not '
          'compile into a second sign');
      expect(mapped.signs.single.gloss, 'DONDE');
      expect(mapped.signs.single.asset, 'assets/signs/donde_pregunta.mp4');
      expect(mapped.assets.matchedIds, <String>['l5-001']);
    });

    test('a clip with no matching sign is reported, never silently dropped',
        () {
      final parser.CompileResult orphan = parser.compileVocab(
        'Lección #,Subtema,Video / seña disponible,Estado\n'
        'Lección 5,Preguntas,¿Dónde?,Registrado\n',
        clips: <parser.SignClip>[
          parser.SignClip(
            slug: 'esperar',
            assetPath: 'assets/signs/esperar.mp4',
            folder: 'ACCIONES',
          ),
        ],
      );

      expect(orphan.signs.single.hasVideo, isFalse);
      expect(orphan.assets.unmatchedSlugs, <String>['esperar (ACCIONES)']);
      expect(parser.buildReport(orphan), contains('esperar (ACCIONES)'));
    });

    test('report renderer mentions totals and duplicates', () {
      final String report = parser.buildReport(result);

      expect(report, contains('Total data rows   : 10'));
      expect(report, contains('Compiled signs    : 7'));
      expect(report, contains('GRACIAS'));
      expect(report, contains('L3: 0 (EMPTY)'));
    });
  });
}
