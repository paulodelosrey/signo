// Build-time CSV → JSON vocabulary compiler for Signo.
//
// Reads the MonikLSC classification spreadsheet (read-only input, never
// bundled) and emits `assets/content/vocab.json`, a typed asset consumed at
// runtime by `lib/core/lsc_vocab`. No CSV parsing happens in the app.
//
// Run from `signo_app/`:
//   dart run tool/parse_vocab.dart
//
// Input columns (verified against the real file):
//   `Lección #` | `Subtema` | `Video / seña disponible` | `Estado`
// The "Video / seña disponible" cell holds the sign label itself, not a file
// path, so `hasVideo` only turns true when the cell looks like a media file
// reference (none today — video curation is a later task).
import 'dart:convert';
import 'dart:io';

/// Lexical signs known to have a typo in the source spreadsheet.
/// Key: diacritics-stripped lowercase cleaned value; value: display fix.
const Map<String, String> _typoCorrections = <String, String>{
  'abecedarioa': 'Abecedario',
};

/// Cells whose value is a note about the lesson, not a lexical sign.
const Set<String> _placeholderValues = <String>{
  'sin senas',
  'sin senas adicionales',
};

/// One compiled vocabulary entry, mirroring the runtime `VocabEntry` model.
class CompiledSign {
  CompiledSign({
    required this.id,
    required this.gloss,
    required this.lemmas,
    required this.lesson,
    required this.subtema,
    required this.hasVideo,
    required this.estado,
  });

  final String id;
  final String gloss;
  final List<String> lemmas;
  final int lesson;
  final String subtema;

  // Video curation (later milestone) fills these in; null until then.
  final String? asset = null;
  final String? releasePath = null;
  final int? trimStartMs = null;
  final int? trimEndMs = null;
  final bool hasVideo;

  final String estado;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'gloss': gloss,
    'lemmas': lemmas,
    'lesson': lesson,
    'subtema': subtema,
    'asset': asset,
    'releasePath': releasePath,
    'trimStartMs': trimStartMs,
    'trimEndMs': trimEndMs,
    'hasVideo': hasVideo,
  };
}

/// Aggregate result of compiling the CSV, plus everything the validation
/// report needs.
class CompileResult {
  CompileResult({
    required this.signs,
    required this.totalRows,
    required this.headerCells,
    required this.perLesson,
    required this.duplicateGlosses,
    required this.missingSignRows,
    required this.placeholderRows,
    required this.estadoCounts,
    required this.sampleGlosses,
  });

  final List<CompiledSign> signs;
  final int totalRows;
  final List<String> headerCells;
  final Map<int, int> perLesson;
  final Map<String, List<int>> duplicateGlosses;
  final List<String> missingSignRows;
  final List<String> placeholderRows;
  final Map<String, int> estadoCounts;
  final List<String> sampleGlosses;
}

/// Strips Spanish diacritics and lowercases for matching keys.
String normalizeLemma(String input) {
  const Map<String, String> accents = <String, String>{
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'à': 'a', 'è': 'e', 'ì': 'i', 'ò': 'o', 'ù': 'u', 'â': 'a', 'ê': 'e',
    'î': 'i', 'ô': 'o', 'û': 'u', 'ã': 'a', 'õ': 'o', 'ç': 'c', 'ï': 'i',
    'ä': 'a', 'ö': 'o', 'ë': 'e', 'å': 'a',
    'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
    'À': 'a', 'È': 'e', 'Ì': 'i', 'Ò': 'o', 'Ù': 'u', 'Â': 'a', 'Ê': 'e',
    'Î': 'i', 'Ô': 'o', 'Û': 'u', 'Ã': 'a', 'Õ': 'o', 'Ç': 'c', 'Ï': 'i',
    'Ä': 'a', 'Ö': 'o', 'Ë': 'e', 'Å': 'a',
  };
  final StringBuffer buffer = StringBuffer();
  for (final int rune in input.runes) {
    final String ch = String.fromCharCode(rune);
    buffer.write(accents[ch] ?? ch.toLowerCase());
  }
  return buffer.toString();
}

/// Decodes bytes as UTF-8, falling back to Latin-1 (the spreadsheet's
/// encoding). Also removes a leading BOM if present.
String decodeSpreadsheetBytes(List<int> bytes) {
  String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException {
    text = latin1.decode(bytes, allowInvalid: true);
  }
  return text.startsWith('\uFEFF') ? text.substring(1) : text;
}

/// Minimal CSV field splitter supporting double-quoted cells.
List<String> splitCsvLine(String line) {
  final List<String> fields = <String>[];
  final StringBuffer buffer = StringBuffer();
  bool inQuotes = false;
  for (var i = 0; i < line.length; i++) {
    final String ch = line[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
      continue;
    }
    if (ch == ',' && !inQuotes) {
      fields.add(buffer.toString().trim());
      buffer.clear();
      continue;
    }
    buffer.write(ch);
  }
  fields.add(buffer.toString().trim());
  return fields;
}

/// Expands inline gender/variant pairs: `Tío/a` → [Tío, Tía]; `El/Ella`
/// keeps both full words.
List<String> expandVariants(String cleaned) {
  final List<String> parts = cleaned.split('/');
  final String base = parts.first.trim();
  if (parts.length == 1 || base.isEmpty) {
    return base.isEmpty ? <String>[] : <String>[base];
  }
  final List<String> variants = <String>[base];
  for (final String raw in parts.skip(1)) {
    final String suffix = raw.trim();
    if (suffix.isEmpty) {
      continue;
    }
    final bool isShortSuffix = suffix.length <= 2 &&
        <String>['a', 'o', 'as', 'os'].contains(normalizeLemma(suffix));
    if (isShortSuffix && base.isNotEmpty) {
      final String stem = <String>['o', 'a', 'ó', 'á']
          .contains(base.substring(base.length - 1))
          ? base.substring(0, base.length - 1)
          : base;
      variants.add('$stem$suffix');
    } else {
      variants.add(suffix);
    }
  }
  return variants;
}

/// Builds the uppercase compound gloss (hyphen per DBLSC notation for
/// compound signs) from the first variant of the cleaned value.
String buildGloss(String cleaned) {
  final String noPunctuation = cleaned
      .replaceAll(RegExp(r'[¿?¡!]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final String firstVariant = expandVariants(noPunctuation).first;
  return normalizeLemma(firstVariant)
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

/// Word-level lemmas (diacritics-stripped, lowercase) for every variant.
/// Purely numeric rows (e.g. `1-19`) yield no word tokens, so the whole
/// normalized value becomes the single lemma to keep entries reachable.
List<String> buildLemmas(String cleaned) {
  final Set<String> lemmas = <String>{};
  for (final String variant in expandVariants(cleaned)) {
    for (final String word
        in variant.split(RegExp(r'[^A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+'))) {
      if (word.isEmpty) {
        continue;
      }
      final String lemma = normalizeLemma(word);
      lemmas.add(_typoCorrections[lemma] ?? lemma);
    }
  }
  if (lemmas.isEmpty) {
    final String whole = normalizeLemma(cleaned);
    lemmas.add(_typoCorrections[whole] ?? whole);
  }
  return lemmas.toList();
}

/// Compiles the raw spreadsheet text into signs + report data.
CompileResult compileVocab(String csvText) {
  final List<String> lines = csvText
      .split(RegExp(r'\r?\n'))
      .map((String line) => line.trim())
      .where((String line) => line.isNotEmpty)
      .toList();
  if (lines.isEmpty) {
    throw StateError('Empty CSV input');
  }

  // Identify columns from the (possibly mojibake) header by loose match,
  // falling back to the verified fixed order.
  final List<String> header = splitCsvLine(lines.first);
  int indexOf(bool Function(String) test, int fallback) {
    for (var i = 0; i < header.length; i++) {
      if (test(normalizeLemma(header[i]))) {
        return i;
      }
    }
    return fallback;
  }

  final int lessonCol = indexOf((String h) => h.contains('leccion'), 0);
  final int subtemaCol = indexOf((String h) => h.contains('subtema'), 1);
  final int signCol = indexOf((String h) => h.contains('video'), 2);
  final int estadoCol = indexOf((String h) => h.contains('estado'), 3);

  final List<CompiledSign> signs = <CompiledSign>[];
  final Map<int, int> perLesson = <int, int>{};
  final Map<String, List<int>> duplicateGlosses = <String, List<int>>{};
  final Map<String, int> estadoCounts = <String, int>{};
  final List<String> missingSignRows = <String>[];
  final List<String> placeholderRows = <String>[];

  for (final String line in lines.skip(1)) {
    final List<String> cells = splitCsvLine(line);
    final String lessonCell = lessonCol < cells.length ? cells[lessonCol] : '';
    final String subtema = subtemaCol < cells.length ? cells[subtemaCol] : '';
    final String signCell = signCol < cells.length ? cells[signCol] : '';
    final String estado = estadoCol < cells.length ? cells[estadoCol] : '';

    final String estadoKey = normalizeLemma(estado);
    estadoCounts.update(estadoKey, (int v) => v + 1, ifAbsent: () => 1);

    final RegExpMatch? lessonMatch =
        RegExp(r'(\d+)').firstMatch(lessonCell);
    final int lesson = lessonMatch != null ? int.parse(lessonMatch.group(1)!) : 0;

    if (signCell.isEmpty) {
      missingSignRows.add(line);
      continue;
    }

    // Strip parenthetical annotations ("(A-Z)", "(Enero-Diciembre)") and
    // interjection marks before normalizing / matching / glossing.
    final String annotationFree = signCell
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'[¿?¡!]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final String normalizedValue = normalizeLemma(annotationFree);

    if (annotationFree.isEmpty) {
      missingSignRows.add(line);
      continue;
    }

    final bool isPlaceholder = _placeholderValues.contains(normalizedValue) ||
        normalizedValue.startsWith('imagenes');
    if (isPlaceholder) {
      placeholderRows.add(line);
      continue;
    }

    // Apply documented typo fixes at the value level (display + lemmas).
    final String cleaned = _typoCorrections[normalizedValue] ?? annotationFree;

    final String gloss = buildGloss(cleaned);
    duplicateGlosses.putIfAbsent(gloss, () => <int>[]).add(lesson);
    final String id = 'l$lesson-${(signs.length + 1).toString().padLeft(3, '0')}';
    signs.add(CompiledSign(
      id: id,
      gloss: gloss,
      lemmas: buildLemmas(cleaned),
      lesson: lesson,
      subtema: subtema,
      hasVideo: RegExp(r'\.(mp4|mov|webm|m4v)$', caseSensitive: false)
          .hasMatch(signCell),
      estado: estado,
    ));
    perLesson.update(lesson, (int v) => v + 1, ifAbsent: () => 1);
  }

  duplicateGlosses.removeWhere(
    (String gloss, List<int> lessons) => lessons.length < 2,
  );

  return CompileResult(
    signs: signs,
    totalRows: lines.length - 1,
    headerCells: header,
    perLesson: perLesson,
    duplicateGlosses: duplicateGlosses,
    missingSignRows: missingSignRows,
    placeholderRows: placeholderRows,
    estadoCounts: estadoCounts,
    sampleGlosses: signs.take(8).map((CompiledSign s) => s.gloss).toList(),
  );
}

/// Renders the human-readable validation report.
String buildReport(CompileResult result) {
  final StringBuffer out = StringBuffer();
  out.writeln('=== vocab.json validation report ===');
  out.writeln('Columns found     : ${result.headerCells.join(' | ')}');
  out.writeln('Total data rows   : ${result.totalRows}');
  out.writeln('Compiled signs    : ${result.signs.length}');
  out.writeln('Skipped (no sign) : ${result.missingSignRows.length}');
  out.writeln('Skipped (note row): ${result.placeholderRows.length}');
  out.writeln('');
  out.writeln('Per-lesson compiled signs:');
  for (final int lesson in const <int>[1, 2, 3, 4, 5, 6, 7]) {
    final int count = result.perLesson[lesson] ?? 0;
    final String coverage = count > 0 ? 'covered' : 'EMPTY';
    out.writeln('  L$lesson: $count ($coverage)');
  }
  out.writeln('');
  out.writeln('Estado distribution:');
  result.estadoCounts.forEach((String estado, int count) {
    out.writeln('  "$estado": $count');
  });
  out.writeln('');
  out.writeln('Duplicate glosses (kept, first wins at index):');
  if (result.duplicateGlosses.isEmpty) {
    out.writeln('  none');
  } else {
    result.duplicateGlosses.forEach((String gloss, List<int> lessons) {
      out.writeln('  $gloss → lessons $lessons');
    });
  }
  out.writeln('');
  out.writeln('Missing-sign rows:');
  for (final String row in result.missingSignRows) {
    out.writeln('  $row');
  }
  if (result.missingSignRows.isEmpty) {
    out.writeln('  none');
  }
  out.writeln('');
  out.writeln('Sample glosses: ${result.sampleGlosses.join(', ')}');
  return out.toString();
}

Future<void> main() async {
  final File input = File('../MonikLSC/clasificacion_senas_lsc.csv');
  if (!input.existsSync()) {
    stderr.writeln(
      'Input CSV not found at ${input.absolute.path}. '
      'Run from signo_app/ with the MonikLSC folder as a sibling of the repo.',
    );
    exitCode = 1;
    return;
  }

  final String csvText = decodeSpreadsheetBytes(input.readAsBytesSync());
  final CompileResult result = compileVocab(csvText);
  if (result.signs.isEmpty) {
    stderr.writeln('No signs compiled — refusing to write vocab.json.');
    exitCode = 1;
    return;
  }

  final Map<String, Object?> payload = <String, Object?>{
    'source': 'MonikLSC/clasificacion_senas_lsc.csv',
    'count': result.signs.length,
    'signs': result.signs.map((CompiledSign s) => s.toJson()).toList(),
  };

  final Directory outDir = Directory('assets/content');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }
  final File outFile = File('assets/content/vocab.json');
  outFile.writeAsStringSync(jsonEncode(payload), flush: true);

  stdout.write(buildReport(result));
  stdout.writeln('Wrote ${outFile.path} (${result.signs.length} signs).');
}
