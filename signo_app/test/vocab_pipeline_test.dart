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

    test('marks hasVideo false because no cell references a media file', () {
      expect(result.signs.every((parser.CompiledSign s) => !s.hasVideo), isTrue);
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
