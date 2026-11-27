const _arrayBegin = r'\begin{array}';
const _arrayEnd = r'\end{array}';
const _rowBreak = r'\\';

/// Expands `*{n}{spec}` column repeats in `array` environments.
///
/// MathType exports arrays as `\begin{array}{*{35}{l}}`, a LaTeX shorthand
/// that flutter_math_fork rejects ("Unknown column alignment: *"). That
/// failure pushes the formula to the MathJax SVG fallback, which renders it
/// at its own (much larger) size or not at all.
///
/// Each repeat is capped at the number of columns the array body really
/// uses, so `{*{35}{l}}` over a two-column body becomes `{ll}` instead of
/// 35 empty columns. Malformed specs are left untouched.
String expandArrayColumnRepeats(String tex) {
  if (!tex.contains(_arrayBegin) || !tex.contains('*')) return tex;

  final buffer = StringBuffer();
  var cursor = 0;

  while (true) {
    final beginIndex = tex.indexOf(_arrayBegin, cursor);
    if (beginIndex == -1) break;

    final specStart = _skipSpaces(tex, beginIndex + _arrayBegin.length);
    final spec = _readBraceGroup(tex, specStart);
    if (spec == null) break;

    final columnCount = _countColumns(tex, spec.end);
    final expanded = _expandSpec(spec.content, columnCount);

    buffer
      ..write(tex.substring(cursor, specStart))
      ..write('{${expanded ?? spec.content}}');
    cursor = spec.end;
  }

  buffer.write(tex.substring(cursor));
  return buffer.toString();
}

/// Returns [spec] with every `*{n}{s}` replaced by `s` repeated
/// `min(n, maxRepeat)` times, or null when a repeat is malformed.
String? _expandSpec(String spec, int maxRepeat) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < spec.length) {
    if (spec[index] != '*') {
      buffer.write(spec[index]);
      index++;
      continue;
    }

    final count = _readBraceGroup(spec, _skipSpaces(spec, index + 1));
    if (count == null) return null;
    final body = _readBraceGroup(spec, _skipSpaces(spec, count.end));
    if (body == null) return null;

    final repeat = int.tryParse(count.content.trim());
    final expandedBody = _expandSpec(body.content, maxRepeat);
    if (repeat == null || repeat < 0 || expandedBody == null) return null;

    buffer.write(expandedBody * (repeat < maxRepeat ? repeat : maxRepeat));
    index = body.end;
  }

  return buffer.toString();
}

/// Counts the widest row of the array body starting at [bodyStart].
int _countColumns(String tex, int bodyStart) {
  final endIndex = tex.indexOf(_arrayEnd, bodyStart);
  final body = tex.substring(bodyStart, endIndex == -1 ? tex.length : endIndex);

  var maxColumns = 1;
  for (final row in body.split(_rowBreak)) {
    final columns = RegExp(r'(?<!\\)&').allMatches(row).length + 1;
    if (columns > maxColumns) maxColumns = columns;
  }
  return maxColumns;
}

int _skipSpaces(String text, int index) {
  var i = index;
  while (i < text.length && text[i].trim().isEmpty) {
    i++;
  }
  return i;
}

/// Reads the balanced `{...}` group opening at [start].
({String content, int end})? _readBraceGroup(String text, int start) {
  if (start >= text.length || text[start] != '{') return null;

  var depth = 0;
  for (var i = start; i < text.length; i++) {
    final char = text[i];
    if (char == r'\') {
      i++;
    } else if (char == '{') {
      depth++;
    } else if (char == '}') {
      depth--;
      if (depth == 0) {
        return (content: text.substring(start + 1, i), end: i + 1);
      }
    }
  }
  return null;
}
