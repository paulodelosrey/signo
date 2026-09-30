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
// path: `hasVideo`/`asset` are decided by matching the compiled signs against
// `assets/signs/manifest.json`, the manifest emitted by the clip pipeline
// (compression + provenance). Never hand-edit `vocab.json` to attach a video —
// re-run this tool.
import 'dart:convert';
import 'dart:io';

/// Path of the clip manifest, relative to `signo_app/`.
const String kSignManifestPath = 'assets/signs/manifest.json';

/// Normalized value of the spreadsheet row that stands for the WHOLE
/// alphabet (`Abecedarioa(A-Z)`). It is not a sign: it is expanded into one
/// entry per ABECEDARIO clip at compile time.
const String kAbecedarioAggregateValue = 'abecedarioa';

/// Manifest folder holding the dactilology (alphabet) clips.
const String kAbecedarioFolder = 'ABECEDARIO';

/// Suffix marking a question-form clip (`qué_pregunta.mp4`).
const String kPreguntaSuffix = '_pregunta';

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

/// One video clip declared in `assets/signs/manifest.json`.
///
/// [slug] is the file name without extension, normalized for matching
/// (`cómo_pregunta.mp4` → `como_pregunta`), so the compiler can line clips up
/// with vocabulary lemmas and glosses.
class SignClip {
  SignClip({required this.slug, required this.assetPath, required this.folder});

  final String slug;

  /// Bundle-relative path written into `VocabEntry.asset`.
  final String assetPath;

  /// Provenance folder (`ABECEDARIO`, `FRASES COMUNES`, `ACCIONES`).
  final String folder;

  bool get isPregunta => slug.endsWith(kPreguntaSuffix);
}

/// Parses the clip manifest into [SignClip]s, keeping manifest order (the
/// provenance order of the compression pipeline).
List<SignClip> parseSignManifest(String manifestJson) {
  final List<Object?> raw = jsonDecode(manifestJson)! as List<Object?>;
  final List<SignClip> clips = <SignClip>[];
  for (final Object? item in raw) {
    final Map<String, Object?> clip = item! as Map<String, Object?>;
    final String assetPath = clip['asset']! as String;
    final int slash = assetPath.lastIndexOf('/');
    final String fileName =
        slash < 0 ? assetPath : assetPath.substring(slash + 1);
    final int dot = fileName.lastIndexOf('.');
    final String stem = dot < 0 ? fileName : fileName.substring(0, dot);
    clips.add(SignClip(
      slug: slugify(stem),
      assetPath: assetPath,
      folder: clip['folder']! as String,
    ));
  }
  return clips;
}

/// Matching key for a lemma, gloss or clip file stem: diacritics stripped,
/// lowercase, every non-alphanumeric run collapsed to a single `_`. This makes
/// `BUENOS-DIAS`, `buenos días` and `buenos_dias` the same key.
String slugify(String input) {
  final String normalized = normalizeLemma(input).toLowerCase();
  return normalized
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}

/// One compiled vocabulary entry, mirroring the runtime `VocabEntry` model.
class CompiledSign {
  CompiledSign({
    required this.id,
    required this.gloss,
    required this.lemmas,
    required this.lesson,
    required this.subtema,
    required this.estado,
    this.asset,
    this.hasVideo = false,
    this.releasePath,
    this.trimStartMs,
    this.trimEndMs,
  });

  final String id;
  final String gloss;
  final List<String> lemmas;
  final int lesson;
  final String subtema;

  /// Bundled clip for this sign. Filled in by [assignSignAssets] from the clip
  /// manifest; null when no clip matches the sign.
  String? asset;

  /// The GitHub Release copy of the clip — a later download step, still null.
  String? releasePath;
  int? trimStartMs;
  int? trimEndMs;

  /// True when [asset] points at a bundled clip the app can play.
  bool hasVideo;

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
    required this.assets,
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

  /// Which clips reached a sign and which did not.
  final AssetAssignment assets;
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

/// ABECEDARIO clips, in manifest order (a…z with `n_tilde` after `n`).
List<SignClip> abecedarioClips(List<SignClip> clips) =>
    clips.where((SignClip c) => c.folder == kAbecedarioFolder).toList();

/// Display gloss of an alphabet clip: the slug uppercased, except `n_tilde`
/// which is the letter `Ñ` (Spanish has 27 letters, not 26).
String letterGlossFor(SignClip clip) =>
    clip.slug == 'n_tilde' ? 'Ñ' : clip.slug.toUpperCase();

/// Lookup lemma of an alphabet clip: its single letter, lowercase.
///
/// `Ñ` keeps its diacritic here; `VocabIndex` strips it at lookup time, so
/// `Ñ` and `N` share the `n` key and the first entry (the `N` letter) wins.
/// Both signs stay reachable by id, in the dictionary and in unit 5.
String letterLemmaFor(SignClip clip) =>
    clip.slug == 'n_tilde' ? 'ñ' : clip.slug;

/// Stable sequential id (`l1-001`, `l3-042`, ...) in CSV order.
String _nextId(int lesson, int ordinal) =>
    'l$lesson-${(ordinal + 1).toString().padLeft(3, '0')}';

/// Where a clip could not be attached to any sign, and which signs did get a
/// clip — surfaced in the validation report so curation gaps stay visible.
class AssetAssignment {
  AssetAssignment({required this.matchedIds, required this.unmatchedSlugs});

  final List<String> matchedIds;
  final List<String> unmatchedSlugs;
}

/// Attaches clips to [signs] in place.
///
/// Matching rules, applied per clip and in this order (first hit wins, and a
/// sign is only ever claimed by one clip):
///
///  1. Exact slug: lemma index, then gloss index. This is what wires the
///     plain clips (`hola`, `gracias`, `ir`, the 27 letters).
///  2. `*_pregunta` clips are the QUESTION FORM of an existing sign, not new
///     signs: `que_pregunta`, `donde_pregunta`, `cuando_pregunta`,
///     `cual_pregunta`, `quien_pregunta`, `cuanto_pregunta`, `como_pregunta`,
///     `como_siente_pregunta`, `para_que_pregunta` and `por_que_pregunta` map
///     onto the matching entry (QUE, DONDE, ...) so the entry gains a video
///     instead of the vocabulary gaining duplicate question signs. The base
///     slug is tried against the gloss index first, so `como` reaches the L5
///     question sign COMO and not the L1 greeting COMO-ESTAS.
///  3. Still-unmatched `*_pregunta` clips retry with the head of their base
///     slug (`como_siente` → `como`), so an extra-word question form still
///     lands on its base sign.
AssetAssignment assignSignAssets(
  List<CompiledSign> signs,
  List<SignClip> clips,
) {
  // The course lists the same sign under several lessons - "Gracias" appears in
  // both Leccion 2 (Tipos de senas) and Leccion 5 (Frases comunes). Indexing one
  // index per slug, as `putIfAbsent` does, means only the first duplicate can
  // ever receive a clip: the app then ships gracias.mp4 while the second entry
  // renders "Video no disponible por ahora" for the very same word. Both are
  // true at once and a judge finds it in seconds by searching the word.
  //
  // So every slug maps to ALL of its entries, and a clip binds to every one of
  // them. A sign still holds at most one clip: `claimed` keeps the first clip
  // that reaches it and refuses to overwrite it.
  final Map<String, List<int>> byLemma = <String, List<int>>{};
  final Map<String, List<int>> byGloss = <String, List<int>>{};
  for (int i = 0; i < signs.length; i++) {
    for (final String lemma in signs[i].lemmas) {
      byLemma.putIfAbsent(slugify(lemma), () => <int>[]).add(i);
    }
    byGloss.putIfAbsent(slugify(signs[i].gloss), () => <int>[]).add(i);
  }

  final Set<int> claimed = <int>{};
  final Set<String> assignedAssets = <String>{};
  final List<String> matched = <String>[];
  final List<String> unmatched = <String>[];

  // Alphabet clips were already attached by the row expansion.
  for (int i = 0; i < signs.length; i++) {
    final String? asset = signs[i].asset;
    if (signs[i].hasVideo && asset != null) {
      claimed.add(i);
      assignedAssets.add(asset);
      matched.add(signs[i].id);
    }
  }

  // Every unclaimed sign this slug names, gloss hits before lemma hits so the
  // tie-break documented above still decides which GROUP is preferred, and a
  // sign reachable both ways is not returned twice.
  List<int> resolve(String slug, {required bool glossFirst}) {
    final List<int> out = <int>[];
    for (final List<int>? hits in glossFirst
        ? <List<int>?>[byGloss[slug], byLemma[slug]]
        : <List<int>?>[byLemma[slug], byGloss[slug]]) {
      if (hits == null) {
        continue;
      }
      for (final int candidate in hits) {
        if (!claimed.contains(candidate) && !out.contains(candidate)) {
          out.add(candidate);
        }
      }
      if (out.isNotEmpty) {
        break;
      }
    }
    return out;
  }

  // Longest slugs first so a multi-word question form (`como_siente_pregunta`)
  // claims its base sign before the bare form (`como_pregunta`) does. Ties keep
  // manifest order, which keeps the result deterministic.
  final List<SignClip> ordered = <SignClip>[...clips]
    ..sort((SignClip a, SignClip b) =>
        b.slug.split('_').length.compareTo(a.slug.split('_').length));

  for (final SignClip clip in ordered) {
    if (assignedAssets.contains(clip.assetPath)) {
      continue; // already attached (alphabet expansion)
    }
    final List<String> candidates = <String>[];
    if (!clip.isPregunta) {
      candidates.add(clip.slug);
    } else {
      final String base =
          clip.slug.substring(0, clip.slug.length - kPreguntaSuffix.length);
      candidates.add(base);
      // Retry with the head of the base slug: `como_siente` → `como`.
      final List<String> tokens = base.split('_');
      for (int take = tokens.length - 1; take >= 1; take--) {
        candidates.add(tokens.take(take).join('_'));
      }
    }
    // Question forms are gloss-driven (rule 2), plain clips lemma-driven.
    for (final String candidate in candidates) {
      final List<int> indices = resolve(candidate, glossFirst: clip.isPregunta);
      if (indices.isEmpty) {
        continue;
      }
      // Bind the clip to EVERY duplicate this slug names, not just the first.
      for (final int index in indices) {
        signs[index]
          ..asset = clip.assetPath
          ..hasVideo = true;
        claimed.add(index);
        matched.add(signs[index].id);
      }
      assignedAssets.add(clip.assetPath);
      break;
    }
    if (!assignedAssets.contains(clip.assetPath)) {
      unmatched.add('${clip.slug} (${clip.folder})');
    }
  }

  return AssetAssignment(matchedIds: matched, unmatchedSlugs: unmatched);
}

/// Compiles the raw spreadsheet text into signs + report data.
///
/// [clips] is the parsed `assets/signs/manifest.json`; when omitted the
/// compiler behaves exactly as before video curation (no `asset`, no
/// `hasVideo`), which is what the pure CSV unit tests exercise.
CompileResult compileVocab(String csvText, {List<SignClip> clips = const <SignClip>[]}) {
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

    // The alphabet row stands for 27 real clips, not one sign: expand it into
    // one entry per ABECEDARIO clip. Without clips (pure CSV consumers) the row
    // compiles as the single aggregate sign, as it always did.
    if (normalizedValue == kAbecedarioAggregateValue) {
      final List<SignClip> letters = abecedarioClips(clips);
      if (letters.isNotEmpty) {
        for (final SignClip letter in letters) {
          signs.add(CompiledSign(
            id: _nextId(lesson, signs.length),
            gloss: letterGlossFor(letter),
            lemmas: <String>[letterLemmaFor(letter)],
            lesson: lesson,
            subtema: subtema,
            estado: estado,
            asset: letter.assetPath,
            hasVideo: true,
          ));
        }
        perLesson.update(lesson, (int v) => v + letters.length, ifAbsent: () => letters.length);
        continue;
      }
    }

    final String gloss = buildGloss(cleaned);
    duplicateGlosses.putIfAbsent(gloss, () => <int>[]).add(lesson);
    signs.add(CompiledSign(
      id: _nextId(lesson, signs.length),
      gloss: gloss,
      lemmas: buildLemmas(cleaned),
      lesson: lesson,
      subtema: subtema,
      estado: estado,
    ));
    perLesson.update(lesson, (int v) => v + 1, ifAbsent: () => 1);
  }

  duplicateGlosses.removeWhere(
    (String gloss, List<int> lessons) => lessons.length < 2,
  );

  final AssetAssignment assets = assignSignAssets(signs, clips);

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
    assets: assets,
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
  out.writeln('Video (assets/signs/manifest.json):');
  out.writeln('  Signs with a bundled clip : '
      '${result.signs.where((CompiledSign s) => s.hasVideo).length}'
      '/${result.signs.length}');
  out.writeln('  Clips attached to a sign  : ${result.assets.matchedIds.length}');
  if (result.assets.unmatchedSlugs.isEmpty) {
    out.writeln('  Clips with no matching sign: none');
  } else {
    out.writeln('  Clips with no matching sign (${result.assets.unmatchedSlugs.length}):');
    for (final String slug in result.assets.unmatchedSlugs) {
      out.writeln('    $slug');
    }
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

  final File manifest = File(kSignManifestPath);
  final List<SignClip> clips = manifest.existsSync()
      ? parseSignManifest(manifest.readAsStringSync())
      : const <SignClip>[];
  if (clips.isEmpty) {
    stderr.writeln(
      'Clip manifest not found at ${manifest.absolute.path}: compiling '
      'vocabulary WITHOUT videos.',
    );
  }

  final CompileResult result = compileVocab(csvText, clips: clips);
  if (result.signs.isEmpty) {
    stderr.writeln('No signs compiled — refusing to write vocab.json.');
    exitCode = 1;
    return;
  }

  final Map<String, Object?> payload = <String, Object?>{
    'source': 'MonikLSC/clasificacion_senas_lsc.csv',
    'videoManifest': kSignManifestPath,
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
