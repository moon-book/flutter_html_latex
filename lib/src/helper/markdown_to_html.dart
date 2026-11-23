import 'package:markdown/markdown.dart' as md;

String convertMarkdownToHtml(String markdown) {
  return _convertMarkdownToHtml(markdown, mathBuilder: _buildPlainMathHtml);
}

String convertMarkdownToHtmlLatex(String markdown) {
  return _convertMarkdownToHtml(markdown, mathBuilder: _buildHtmlLatexMathHtml);
}

bool containsLatexMath(String input) {
  return RegExp(r'\\\[[\s\S]+?\\\]').hasMatch(input) ||
      RegExp(r'\\\([\s\S]+?\\\)').hasMatch(input) ||
      input.contains(r'\$') ||
      _containsDollarMath(input);
}

bool _containsDollarMath(String input) {
  if (!input.contains(r'$')) {
    return false;
  }

  final found = <_MathExpression>[];
  _extractDollarMathExpressions(input, found);
  return found.isNotEmpty;
}

String _convertMarkdownToHtml(
  String markdown, {
  required String Function(_MathExpression expression) mathBuilder,
}) {
  final mathExpressions = <_MathExpression>[];
  final codeBlocks = <String>[];

  var text = markdown;

  text = text.replaceAllMapped(
    RegExp(r'^(\s*)(\d+)([.)])(\s)', multiLine: true),
    (match) =>
        '${match.group(1)}${match.group(2)}\\${match.group(3)}${match.group(4)}',
  );

  text = text.replaceAllMapped(RegExp(r'```[\s\S]*?```'), (match) {
    final index = codeBlocks.length;
    codeBlocks.add(match.group(0)!);
    return 'CODEBLOCK${index}XYZ';
  });

  text = _extractDollarMathExpressions(text, mathExpressions);

  text = text.replaceAllMapped(RegExp(r'\\\[([\s\S]*?)\\\]'), (match) {
    final index = mathExpressions.length;
    mathExpressions.add(
      _MathExpression(latex: match.group(1)!.trim(), isBlock: true),
    );
    return '\n\nMATHBLOCK${index}XYZ\n\n';
  });

  text = text.replaceAllMapped(RegExp(r'\\\(([\s\S]*?)\\\)'), (match) {
    final index = mathExpressions.length;
    mathExpressions.add(
      _MathExpression(latex: match.group(1)!.trim(), isBlock: false),
    );
    return 'MATHINLINE${index}XYZ';
  });

  var html = md.markdownToHtml(
    text,
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );

  html = _unwrapStandaloneBlockMathPlaceholders(html);

  for (var i = 0; i < mathExpressions.length; i++) {
    final expression = mathExpressions[i];
    final placeholder = expression.isBlock
        ? 'MATHBLOCK${i}XYZ'
        : 'MATHINLINE${i}XYZ';

    html = html.replaceAll(placeholder, mathBuilder(expression));
  }

  for (var i = 0; i < codeBlocks.length; i++) {
    html = html.replaceAll('CODEBLOCK${i}XYZ', codeBlocks[i]);
  }

  return _preserveNewLines(html);
}

String _buildPlainMathHtml(_MathExpression expression) {
  final escapedLatex = _escapeHtmlText(_normalizeLatex(expression.latex));
  if (expression.isBlock) {
    return '\\[$escapedLatex\\]';
  }

  return '\\($escapedLatex\\)';
}

String _buildHtmlLatexMathHtml(_MathExpression expression) {
  final escapedLatex = _escapeHtmlText(_normalizeLatex(expression.latex));
  if (expression.isBlock) {
    return '<div class="math-display">\\[$escapedLatex\\]</div>';
  }

  return '<span class="math-inline">\\($escapedLatex\\)</span>';
}

String _escapeHtmlText(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

String _decodeHtmlEntities(String text) {
  return text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
}

String _normalizeLatex(String latex) {
  return _normalizeAlignEnvironment(_decodeHtmlEntities(latex));
}

String _normalizeAlignEnvironment(String latex) {
  return latex
      .replaceAllMapped(
        RegExp(r'\\begin\{align\*?\}'),
        (_) => r'\begin{aligned}',
      )
      .replaceAllMapped(
        RegExp(r'\\end\{align\*?\}'),
        (_) => r'\end{aligned}',
      );
}

String _extractDollarMathExpressions(
  String text,
  List<_MathExpression> mathExpressions,
) {
  final buffer = StringBuffer();
  var index = 0;

  while (index < text.length) {
    // `\\` is a literal backslash pair: consume it whole so the second
    // backslash cannot escape a following `$`.
    if (text.startsWith(r'\\', index)) {
      buffer.write(r'\\');
      index += 2;
      continue;
    }

    if (text.startsWith(r'\$', index)) {
      buffer.write(_dollarEntity);
      index += 2;
      continue;
    }

    if (text.startsWith(r'$$', index)) {
      final closeIndex = text.indexOf(r'$$', index + 2);
      if (closeIndex == -1) {
        buffer.write(r'$$');
        index += 2;
        continue;
      }

      final expressionIndex = mathExpressions.length;
      mathExpressions.add(
        _MathExpression(
          latex: text.substring(index + 2, closeIndex).trim(),
          isBlock: true,
        ),
      );
      buffer.write('\n\nMATHBLOCK${expressionIndex}XYZ\n\n');
      index = closeIndex + 2;
      continue;
    }

    if (text.codeUnitAt(index) == _dollarCodeUnit) {
      final closeIndex = _findSingleDollarClose(text, index + 1);
      if (closeIndex == -1) {
        buffer.writeCharCode(_dollarCodeUnit);
        index++;
        continue;
      }

      final expressionIndex = mathExpressions.length;
      mathExpressions.add(
        _MathExpression(
          latex: text.substring(index + 1, closeIndex).trim(),
          isBlock: false,
        ),
      );
      buffer.write('MATHINLINE${expressionIndex}XYZ');
      index = closeIndex + 1;
      continue;
    }

    buffer.writeCharCode(text.codeUnitAt(index));
    index++;
  }

  return buffer.toString();
}

/// Finds the `$` closing an inline formula opened just before [start].
///
/// Escaped `\$` inside the formula is skipped. When the opener looks like
/// currency (`$1 Billion`, `$ 5`), Pandoc's `tex_math_dollars` closing rules
/// apply: the closing `$` must not be preceded by whitespace nor followed by
/// a digit, and the first `$` failing them ends the search (inside real
/// LaTeX every unescaped `$` is a delimiter). Openers that do not start with
/// a digit keep the legacy "next `$` closes" behaviour, so existing data
/// such as MathType output `$\Rightarrow $` still renders as math.
int _findSingleDollarClose(String text, int start) {
  final isCurrencyLike = _looksLikeCurrencyOpener(text, start);

  for (var index = start; index < text.length; index++) {
    final unit = text.codeUnitAt(index);
    if (unit == _backslashCodeUnit) {
      index++;
      continue;
    }

    if (unit != _dollarCodeUnit) {
      continue;
    }

    if (!isCurrencyLike || _isValidClosingDollar(text, index)) {
      return index;
    }

    return -1;
  }

  return -1;
}

/// True when the text right after an opening `$` (ignoring spaces) is a
/// digit, as in `$97 Million` or `$ 5`.
bool _looksLikeCurrencyOpener(String text, int start) {
  for (var index = start; index < text.length; index++) {
    final unit = text.codeUnitAt(index);
    if (unit == _spaceCodeUnit) {
      continue;
    }

    return _isDigit(unit);
  }

  return false;
}

bool _isValidClosingDollar(String text, int index) {
  final previous = text[index - 1];
  if (previous.trim().isEmpty) {
    return false;
  }

  final hasNext = index + 1 < text.length;
  return !(hasNext && _isDigit(text.codeUnitAt(index + 1)));
}

bool _isDigit(int unit) => unit >= _zeroCodeUnit && unit <= _nineCodeUnit;

const _dollarCodeUnit = 36;
const _backslashCodeUnit = 92;
const _spaceCodeUnit = 32;
const _zeroCodeUnit = 48;
const _nineCodeUnit = 57;
const _dollarEntity = '&#36;';

String _unwrapStandaloneBlockMathPlaceholders(String html) {
  return html.replaceAllMapped(
    RegExp(r'<p>\s*(MATHBLOCK\d+XYZ)\s*</p>', caseSensitive: false),
    (match) => match.group(1) ?? '',
  );
}

String _preserveNewLines(String html) {
  final protected = <String>[];

  String protectMatches(String input, RegExp pattern) {
    return input.replaceAllMapped(pattern, (match) {
      final index = protected.length;
      protected.add(match.group(0)!);
      return 'PROTECTED${index}XYZ';
    });
  }

  html = protectMatches(
    html,
    RegExp(
      r'<(pre|code|style|script|table|math)\b[^>]*>[\s\S]*?</\1>',
      caseSensitive: false,
    ),
  );

  html = protectMatches(
    html,
    RegExp(
      r'<(span|div)\b[^>]*class="[^"]*\bmath-(?:tex|inline|display)\b[^"]*"[^>]*>[\s\S]*?</\1>',
      caseSensitive: false,
    ),
  );

  html = protectMatches(
    html,
    RegExp(
      r"<(span|div)\b[^>]*class='[^']*\bmath-(?:tex|inline|display)\b[^']*'[^>]*>[\s\S]*?</\1>",
      caseSensitive: false,
    ),
  );

  html = protectMatches(html, RegExp(r'\\\[[\s\S]*?\\\]'));

  html = html.replaceAll('\n', '<br>');

  for (var i = 0; i < protected.length; i++) {
    html = html.replaceAll('PROTECTED${i}XYZ', protected[i]);
  }

  return html;
}

class _MathExpression {
  const _MathExpression({required this.latex, required this.isBlock});

  final String latex;
  final bool isBlock;
}
