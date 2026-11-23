import 'package:flutter_html_latex/src/helper/markdown_to_html.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('containsLatexMath', () {
    test('detects supported inline and block latex delimiters', () {
      expect(containsLatexMath(r'Gia tri $x + 1$'), isTrue);
      expect(containsLatexMath(r'Gia tri \(x + 1\)'), isTrue);
      expect(containsLatexMath(r'Cong thuc $$x + 1$$'), isTrue);
      expect(containsLatexMath(r'Cong thuc \[x + 1\]'), isTrue);
    });

    test('ignores strings without latex math delimiters', () {
      expect(
        containsLatexMath('Day la chuoi html/markdown binh thuong.'),
        isFalse,
      );
    });

    test('ignores currency dollar signs in plain text', () {
      expect(
        containsLatexMath(
          r'milestone: $1 Billion <b>(6)</b>__ since!<br>- $97 Million+ raised',
        ),
        isFalse,
      );
      expect(containsLatexMath(r'It costs $5 and $10.'), isFalse);
      expect(containsLatexMath(r'Gia $5, giam con $ 3'), isFalse);
      expect(containsLatexMath(r'Only one $5 here.'), isFalse);
    });

    test('still detects math next to currency', () {
      expect(containsLatexMath(r'Pay $5 when $x$ is even'), isTrue);
    });

    test('detects escaped dollar so it can be unescaped', () {
      expect(containsLatexMath(r'Gia \$5'), isTrue);
    });
  });

  group('currency dollar signs', () {
    test('keeps currency text and does not create inline math', () {
      const markdown =
          r'milestone: $1 Billion <b>(6)</b>__________ since our founding!'
          r'<br>- $97 Million+ raised worldwide.';

      final html = convertMarkdownToHtmlLatex(markdown);

      expect(html, isNot(contains('math-inline')));
      expect(html, contains(r'$1 Billion <b>(6)</b>'));
      expect(html, contains(r'$97 Million+'));
    });

    test('rejects closing dollar followed by a digit', () {
      final html = convertMarkdownToHtmlLatex(r'From $5 to $10 when $x$.');

      expect(html, contains(r'From $5 to $10 when '));
      expect(html, contains(r'<span class="math-inline">\(x\)</span>'));
    });

    test('rejects closing dollar preceded by whitespace for currency', () {
      final html = convertMarkdownToHtmlLatex(r'Tu $5 den $ 10 va $y = 2$');

      expect(html, contains(r'Tu $5 den $ 10 va '));
      expect(html, contains(r'<span class="math-inline">\(y = 2\)</span>'));
    });

    test('renders escaped dollar as a literal dollar', () {
      final html = convertMarkdownToHtmlLatex(r'Gia \$5 va \$10, $x$');

      expect(html, contains(r'Gia $5 va $10, '));
      expect(html, isNot(contains(r'\$')));
      expect(html, contains(r'<span class="math-inline">\(x\)</span>'));
    });

    test('keeps escaped dollar inside a formula', () {
      final html = convertMarkdownToHtmlLatex(r'$\$5 + x$');

      expect(html, contains(r'<span class="math-inline">\(\$5 + x\)</span>'));
    });
  });

  group('legacy data compatibility', () {
    String inline(String latex) =>
        '<span class="math-inline">\\($latex\\)</span>';

    test('keeps MathType formulas with a space before the closing dollar', () {
      final html = convertMarkdownToHtmlLatex(
        r'Ta co $\Rightarrow $ va ${{x}^{2}} $ nen $x + 1 $.',
      );

      expect(html, contains(inline(r'\Rightarrow')));
      expect(html, contains(inline(r'{{x}^{2}}')));
      expect(html, contains(inline(r'x + 1')));
    });

    test('keeps formulas that start with a digit', () {
      final html = convertMarkdownToHtmlLatex(r'Ta co $2x+1$ va $1$ va $3$.');

      expect(html, contains(inline('2x+1')));
      expect(html, contains(inline('1')));
      expect(html, contains(inline('3')));
    });

    test('keeps a formula closed right before a digit when not currency', () {
      final html = convertMarkdownToHtmlLatex(r'Dap an $x$2 dong');

      expect(html, contains(inline('x')));
    });

    test('a double backslash does not escape the following dollar', () {
      final html = convertMarkdownToHtmlLatex(r'a\\$x$ va $a \\$');

      expect(html, contains(inline('x')));
      expect(html, contains(inline(r'a \\')));
    });
  });

  group('convertMarkdownToHtmlLatex', () {
    test('wraps inline latex for HtmlLatex rendering', () {
      const markdown = 'Kim loai K co so hieu nguyen tu la (\$Z = 19\$).';

      final html = convertMarkdownToHtmlLatex(markdown);

      expect(html, contains('<span class="math-inline">\\(Z = 19\\)</span>'));
    });

    test('wraps block latex and escapes html-sensitive characters', () {
      const markdown = r'''$$
\begin{aligned}
f'(x) > 0 &\Rightarrow x < 1
\end{aligned}
$$''';

      final html = convertMarkdownToHtmlLatex(markdown);

      expect(html, contains('<div class="math-display">'));
      expect(html, contains(r'\['));
      expect(html, contains('&gt;'));
      expect(html, contains('&lt;'));
      expect(html, contains(r'&amp;\Rightarrow'));
      expect(html, isNot(contains('<br>\\[')));
      expect(html, isNot(contains('<p><div class="math-display">')));
      expect(html, isNot(contains('</div></p>')));
    });

    test('normalizes html entities inside latex before escaping output', () {
      const markdown =
          r'$x&gt;0$ $\begin{align} &amp; {{x}_{1}}=\frac{3-\sqrt{5}}{4} \\ \end{align}$';

      final html = convertMarkdownToHtmlLatex(markdown);

      expect(html, contains(r'\(x&gt;0\)'));
      expect(html, contains(r'\begin{aligned} &amp; {{x}_{1}}'));
      expect(html, contains(r'\end{aligned}'));
      expect(html, isNot(contains(r'\begin{align}')));
      expect(html, isNot(contains('&amp;gt;')));
      expect(html, isNot(contains('&amp;amp;')));
    });

    test('normalizes inline align environment nested in brackets', () {
      const markdown =
          r'''$\Leftrightarrow 4{{x}^{2}}-6x+1=0\Leftrightarrow \left[ \begin{align}
 &amp; {{x}_{1}}=\frac{3-\sqrt{5}}{4} \\ 
 &amp; {{x}_{2}}=\frac{3+\sqrt{5}}{4} \\ 
\end{align} \right.$''';

      final html = convertMarkdownToHtmlLatex(markdown);

      expect(html, contains(r'\left[ \begin{aligned}'));
      expect(html, contains(r'&amp; {{x}_{1}}'));
      expect(html, contains(r'&amp; {{x}_{2}}'));
      expect(html, contains(r'\end{aligned} \right.'));
      expect(html, isNot(contains(r'\begin{align}')));
      expect(html, isNot(contains('&amp;amp;')));
    });

    test('splits adjacent inline latex delimiters instead of making a block', () {
      const markdown =
          r'Vì nhiệt độ không đổi nên:${p_1}{V_1} = {p_2}{V_2}$$\Rightarrow {V_2} = \frac{{p_1}{V_1}}{{p_2}}$';

      final html = convertMarkdownToHtmlLatex(markdown);

      expect(
        html,
        contains(
          r'<span class="math-inline">\({p_1}{V_1} = {p_2}{V_2}\)</span>',
        ),
      );
      expect(
        html,
        contains(
          r'<span class="math-inline">\(\Rightarrow {V_2} = \frac{{p_1}{V_1}}{{p_2}}\)</span>',
        ),
      );
      expect(html, isNot(contains('MATHBLOCK')));
      expect(html, isNot(contains('math-display')));
    });

    test('keeps plain markdown converter behavior for inline latex', () {
      const markdown = 'Gia tri cua K la \$Z = 19\$.';

      final html = convertMarkdownToHtml(markdown);

      expect(html, contains(r'\(Z = 19\)'));
      expect(html, isNot(contains('math-inline')));
    });

    test('keeps multiline block latex intact in plain converter', () {
      const markdown = r'''$$
\begin{aligned}
f'(x) > 0 &\Rightarrow x < 1
\end{aligned}
$$''';

      final html = convertMarkdownToHtml(markdown);

      expect(html, contains(r'\begin{aligned}'));
      expect(html, contains(r'&amp;\Rightarrow'));
      expect(html, isNot(contains(r'\begin{aligned}<br>')));
      expect(html, isNot(contains(r'<br>\end{aligned}')));
    });

    test('keeps non-math html tags while converting latex wrappers', () {
      const markdown = 'Phan tu Cl<sub>2</sub> va so proton \$Z = 17\$.';

      final html = convertMarkdownToHtmlLatex(markdown);

      expect(html, contains('Cl<sub>2</sub>'));
      expect(html, contains('<span class="math-inline">\\(Z = 17\\)</span>'));
    });
  });
}
