const _alignedBody = r'\\begin\{(aligned|align\*?)\}([\s\S]*?)\\end\{\1\}';

/// An `array` whose whole body is a single aligned block, optionally followed
/// by trailing row breaks:
/// `\begin{array}{spec} \begin{align} ... \end{align} \\ \end{array}`.
final _alignedInArray = RegExp(
  r'\\begin\{array\}\s*\{(?:[^{}]|\{[^{}]*\})*\}\s*'
  '$_alignedBody'
  r'\s*(?:\\\\\s*)*\\end\{array\}',
);

/// A bare `aligned`/`align`/`align*` block.
final _aligned = RegExp(_alignedBody);

final _unescapedAmpersand = RegExp(r'(?<!\\)&');

/// Rewrites MathType's left-aligned blocks into a plain `array{l}`.
///
/// MathType exports systems of equations with `&` only to left-align each
/// row, either bare (`\left\{ \begin{aligned} & x=1 \\ & y=2 \end{aligned}
/// \right.`) or wrapped in an array (`\begin{array}{*{35}{l}}
/// \begin{align} & x=0 \\ & x=4 \end{align} \\ \end{array}`). An inline
/// `aligned` block makes the renderer route the formula to the Math2SVG
/// fallback, which draws it far larger than the surrounding text.
///
/// When every row starts with its only `&`, the block (and a wrapping array)
/// becomes `\begin{array}{l} x=1 \\ y=2 \end{array}`, which flutter_math
/// renders at text size. Blocks with real alignment points (`x &= 1`) are
/// left untouched.
String normalizeLeftAlignedBlocks(String tex) {
  if (!tex.contains(r'\begin{align')) return tex;

  return tex
      .replaceAllMapped(_alignedInArray, _toLeftArray)
      .replaceAllMapped(_aligned, _toLeftArray);
}

/// Builds `\begin{array}{l} ... \end{array}` from a match whose group 2 is
/// the aligned body, or returns the match unchanged when it is not a pure
/// left-aligned block.
String _toLeftArray(Match match) {
  final rows = _leftAlignedRows(match.group(2) ?? '');
  if (rows == null) return match.group(0)!;

  return '\\begin{array}{l} ${rows.join(r' \\ ')} \\end{array}';
}

/// Returns the rows of an aligned body with their leading `&` removed, or
/// null when a row uses `&` for anything other than left alignment.
List<String>? _leftAlignedRows(String body) {
  final rows = body
      .split(r'\\')
      .map((row) => row.trim())
      .where((row) => row.isNotEmpty)
      .toList();
  if (rows.isEmpty) return null;

  final unwrapped = <String>[];
  for (final row in rows) {
    final content = row.startsWith('&') ? row.substring(1).trim() : row;
    if (_unescapedAmpersand.hasMatch(content)) return null;
    unwrapped.add(content);
  }
  return unwrapped;
}
