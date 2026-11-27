const _fracCommand = r'\frac';
const _displayFracCommand = r'\dfrac';

/// Rewrites top-level `\frac` commands in [tex] to `\dfrac`.
///
/// Inline math is rendered in text style, where `\frac` shrinks its numerator
/// and denominator to script size. Promoting only top-level fractions keeps
/// the fraction readable while leaving nested fractions and fractions inside
/// `^`/`_` scripts (or any `{...}` group) in their natural, smaller size.
String promoteInlineFractions(String tex) {
  if (!tex.contains(_fracCommand)) return tex;

  final buffer = StringBuffer();
  var depth = 0;
  var i = 0;

  while (i < tex.length) {
    final char = tex[i];

    if (char == r'\') {
      if (depth == 0 && _isFracAt(tex, i) && !_followsScriptMarker(tex, i)) {
        buffer.write(_displayFracCommand);
        i += _fracCommand.length;
        continue;
      }
      // Copy the backslash together with the escaped char (e.g. `\{`, `\\`).
      final end = i + 2 <= tex.length ? i + 2 : tex.length;
      buffer.write(tex.substring(i, end));
      i = end;
      continue;
    }

    if (char == '{') depth++;
    if (char == '}' && depth > 0) depth--;
    buffer.write(char);
    i++;
  }

  return buffer.toString();
}

bool _isFracAt(String tex, int index) {
  if (!tex.startsWith(_fracCommand, index)) return false;
  final next = index + _fracCommand.length;
  if (next >= tex.length) return true;
  return !_isAsciiLetter(tex.codeUnitAt(next));
}

bool _followsScriptMarker(String tex, int index) {
  var j = index - 1;
  while (j >= 0 && tex[j].trim().isEmpty) {
    j--;
  }
  return j >= 0 && (tex[j] == '^' || tex[j] == '_');
}

bool _isAsciiLetter(int code) =>
    (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
