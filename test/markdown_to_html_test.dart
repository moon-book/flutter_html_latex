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
