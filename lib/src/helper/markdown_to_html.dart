import 'package:markdown/markdown.dart' as md;

String convertMarkdownToHtml(String markdown) {
  return _convertMarkdownToHtml(
    markdown,
    mathBuilder: _buildPlainMathHtml,
  );
}

String convertMarkdownToHtmlLatex(String markdown) {
  return _convertMarkdownToHtml(
    markdown,
    mathBuilder: _buildHtmlLatexMathHtml,
  );
}

bool containsLatexMath(String input) {
  return RegExp(r'\$\$[\s\S]+?\$\$').hasMatch(input) ||
      RegExp(r'\\\[[\s\S]+?\\\]').hasMatch(input) ||
      RegExp(r'(?<!\$)\$(?!\$)[\s\S]+?(?<!\$)\$(?!\$)').hasMatch(input) ||
      RegExp(r'\\\([\s\S]+?\\\)').hasMatch(input);
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
    (match) => '${match.group(1)}${match.group(2)}\\${match.group(3)}${match.group(4)}',
  );

  text = text.replaceAllMapped(
    RegExp(r'```[\s\S]*?```'),
    (match) {
      final index = codeBlocks.length;
      codeBlocks.add(match.group(0)!);
      return 'CODEBLOCK${index}XYZ';
    },
  );

  text = text.replaceAllMapped(
    RegExp(r'\$\$([\s\S]*?)\$\$'),
    (match) {
      final index = mathExpressions.length;
      mathExpressions.add(
        _MathExpression(
          latex: match.group(1)!.trim(),
          isBlock: true,
        ),
      );
      return '\n\nMATHBLOCK${index}XYZ\n\n';
    },
  );

  text = text.replaceAllMapped(
    RegExp(r'\\\[([\s\S]*?)\\\]'),
    (match) {
      final index = mathExpressions.length;
      mathExpressions.add(
        _MathExpression(
          latex: match.group(1)!.trim(),
          isBlock: true,
        ),
      );
      return '\n\nMATHBLOCK${index}XYZ\n\n';
    },
  );

  text = text.replaceAllMapped(
    RegExp(r'(?<!\$)\$(?!\$)([\s\S]*?)(?<!\$)\$(?!\$)'),
    (match) {
      final index = mathExpressions.length;
      mathExpressions.add(
        _MathExpression(
          latex: match.group(1)!.trim(),
          isBlock: false,
        ),
      );
      return 'MATHINLINE${index}XYZ';
    },
  );

  text = text.replaceAllMapped(
    RegExp(r'\\\(([\s\S]*?)\\\)'),
    (match) {
      final index = mathExpressions.length;
      mathExpressions.add(
        _MathExpression(
          latex: match.group(1)!.trim(),
          isBlock: false,
        ),
      );
      return 'MATHINLINE${index}XYZ';
    },
  );

  var html = md.markdownToHtml(
    text,
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );

  html = _unwrapStandaloneBlockMathPlaceholders(html);

  for (var i = 0; i < mathExpressions.length; i++) {
    final expression = mathExpressions[i];
    final placeholder = expression.isBlock ? 'MATHBLOCK${i}XYZ' : 'MATHINLINE${i}XYZ';

    html = html.replaceAll(
      placeholder,
      mathBuilder(expression),
    );
  }

  for (var i = 0; i < codeBlocks.length; i++) {
    html = html.replaceAll(
      'CODEBLOCK${i}XYZ',
      codeBlocks[i],
    );
  }

  return _preserveNewLines(html);
}

String _buildPlainMathHtml(_MathExpression expression) {
  final escapedLatex = _escapeHtmlText(expression.latex);
  if (expression.isBlock) {
    return '\\[$escapedLatex\\]';
  }

  return '\\($escapedLatex\\)';
}

String _buildHtmlLatexMathHtml(_MathExpression expression) {
  final escapedLatex = _escapeHtmlText(expression.latex);
  if (expression.isBlock) {
    return '<div class="math-display">\\[$escapedLatex\\]</div>';
  }

  return '<span class="math-inline">\\($escapedLatex\\)</span>';
}

String _escapeHtmlText(String text) {
  return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

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

  html = protectMatches(
    html,
    RegExp(r'\\\[[\s\S]*?\\\]'),
  );

  html = html.replaceAll('\n', '<br>');

  for (var i = 0; i < protected.length; i++) {
    html = html.replaceAll('PROTECTED${i}XYZ', protected[i]);
  }

  return html;
}

class _MathExpression {
  const _MathExpression({
    required this.latex,
    required this.isBlock,
  });

  final String latex;
  final bool isBlock;
}
