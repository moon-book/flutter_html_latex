import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_html_latex/flutter_html_latex.dart';
import 'package:flutter_math_fork/flutter_math.dart';

void main() {
  testWidgets('renders math-tex span as Math widget', (tester) async {
    const html = '<span class="math-tex">\\(4.2-6.3\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(html, factoryBuilder: LatexHtmlWidgetFactory.new),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(find.text('4.2-6.3'), findsNothing);
  });

  testWidgets('renders math-inline span as Math widget', (tester) async {
    const html = '<span class="math-inline">\\(x^2+y^2\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(html, factoryBuilder: LatexHtmlWidgetFactory.new),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(find.text('x^2+y^2'), findsNothing);
  });

  testWidgets('keeps inline math font size equal to surrounding style', (
    tester,
  ) async {
    const html = '<span class="math-inline">\\(x+y\\)</span>';
    const textStyle = TextStyle(fontSize: 20);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HtmlLatex(html, style: textStyle)),
      ),
    );

    final math = tester.widget<Math>(find.byType(Math));
    expect(math.options, isNotNull);
    expect(math.options!.fontSize, 20);
    expect(math.options!.sizeUnderTextStyle, MathSize.normalsize);
  });

  testWidgets('applies primary inline scale to Math.tex font size', (
    tester,
  ) async {
    const html = '<span class="math-inline">\\(x+y\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlLatex(
            html,
            style: TextStyle(fontSize: 20),
            primaryScaleInline: 1.1,
          ),
        ),
      ),
    );

    final math = tester.widget<Math>(find.byType(Math));
    expect(math.options, isNotNull);
    expect(math.options!.fontSize, 22);
    expect(math.textStyle?.fontSize, 22);
  });

  testWidgets('applies HtmlLatex text style to normal html text', (
    tester,
  ) async {
    const textStyle = TextStyle(fontSize: 22);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HtmlLatex('<p>plain text</p>', style: textStyle)),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('plain text'),
      ),
    );

    final span = richText.text as TextSpan;
    expect(span.style?.fontSize, 22);
  });

  testWidgets('auto converts latex markdown when enabled', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlLatex(
            r'Gia tri cua K la $Z = 19$.',
            autoConvertLatex: true,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsOneWidget);
    expect(find.text('Z = 19'), findsNothing);
  });

  testWidgets('does not auto convert latex markdown when disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlLatex(
            r'Gia tri cua K la $Z = 19$.',
            autoConvertLatex: false,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsNothing);
  });

  testWidgets('skips markdown conversion when auto convert finds no latex', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlLatex('**plain markdown**', autoConvertLatex: true),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('**plain markdown**'),
      ),
    );

    expect(richText.text.toPlainText(), contains('**plain markdown**'));
    expect(find.byType(Math), findsNothing);
  });

  testWidgets('falls back to text for empty delimiters', (tester) async {
    const html = '<span class="math-tex">\\(\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(html, factoryBuilder: LatexHtmlWidgetFactory.new),
        ),
      ),
    );

    expect(find.byType(Math), findsNothing);
    expect(find.text(r'\(\)'), findsOneWidget);
  });

  testWidgets('falls back to text for empty inline delimiters', (tester) async {
    const html = '<span class="math-inline">\\(\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(html, factoryBuilder: LatexHtmlWidgetFactory.new),
        ),
      ),
    );

    expect(find.byType(Math), findsNothing);
    expect(find.text(r'\(\)'), findsOneWidget);
  });

  testWidgets('does not overflow for long formulas on narrow width', (
    tester,
  ) async {
    const html =
        '<span class="math-tex">\\(\\frac{\\sum_{i=1}^{n} a_i^2}{\\sqrt{b^2+c^2+d^2+e^2+f^2+g^2+h^2+i^2+j^2}} + \\int_{0}^{\\infty} x^2 dx\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: HtmlWidget(html, factoryBuilder: LatexHtmlWidgetFactory.new),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('auto line breaks oversized display formulas', (tester) async {
    const html =
        '<div class="math-display">\\[P(x)=a_0+a_1x+a_2x^2+a_3x^3+a_4x^4+a_5x^5+a_6x^6+a_7x^7+a_8x^8+a_9x^9+a_{10}x^{10}+a_{11}x^{11}+a_{12}x^{12}+a_{13}x^{13}+a_{14}x^{14}+a_{15}x^{15}+a_{16}x^{16}+a_{17}x^{17}+a_{18}x^{18}+a_{19}x^{19}+a_{20}x^{20}\\]</div>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: HtmlWidget(html, factoryBuilder: _AutoLineBreakFactory.new),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.byType(Math), findsWidgets);
    expect(find.byType(Math).evaluate().length, greaterThan(1));
  });

  testWidgets('handles MathJax equation environment without throwing', (
    tester,
  ) async {
    const html =
        '<span class="math-tex">\\begin{equation}E = mc^2\\end{equation}</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(html, factoryBuilder: LatexHtmlWidgetFactory.new),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles ID 1438 aligned inline content without freezing', (
    tester,
  ) async {
    const html =
        '<p><span class="math-tex">\\(\\begin{aligned}\\n&amp;f(x)=\\frac{x}{x^2+1} \\\\ \\n&amp; \\Rightarrow f^{\\prime}(x)=\\frac{\\left(x^2+1\\right) \\cdot 1-x \\cdot 2 x}{\\left(x^2+1\\right)^2}=\\frac{\\left(1-x^2\\right)}{\\left(x^2+1\\right)^2}\\n\\end{aligned}\\)</span></p>'
        '<p><span class="math-tex">\\(\\begin{aligned}\\n&amp; \\mathrm{f}^{\\prime}(\\mathrm{x})&gt;0 \\Rightarrow \\frac{1-\\mathrm{x}^2}{\\left(\\mathrm{x}^2+1\\right)^2}&gt;0 \\\\ \\n&amp; \\Rightarrow 1-\\mathrm{x}^2&gt;0 \\Rightarrow \\mathrm{x}^2&lt;1 \\Rightarrow-1&lt;\\mathrm{x}&lt;1 \\Rightarrow \\mathrm{x}=(-1,1)\\n\\end{aligned}\\)</span></p>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(html, factoryBuilder: LatexHtmlWidgetFactory.new),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class _AutoLineBreakFactory extends LatexHtmlWidgetFactory {
  _AutoLineBreakFactory()
    : super(
        config: const LatexHtmlWidgetFactoryConfig(
          autoLineBreak: true,
          responsiveLayout: true,
        ),
      );
}
