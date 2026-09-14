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
          body: HtmlWidget(
            html,
            factoryBuilder: LatexHtmlWidgetFactory.new,
          ),
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
          body: HtmlWidget(
            html,
            factoryBuilder: LatexHtmlWidgetFactory.new,
          ),
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
        home: Scaffold(
          body: HtmlLatex(
            html,
            style: textStyle,
          ),
        ),
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
        home: Scaffold(
          body: HtmlLatex(
            '<p>plain text</p>',
            style: textStyle,
          ),
        ),
      ),
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('plain text'),
      ),
    );

    final span = richText.text as TextSpan;
    expect(span.style?.fontSize, 22);
  });

  testWidgets('falls back to text for empty delimiters', (tester) async {
    const html = '<span class="math-tex">\\(\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(
            html,
            factoryBuilder: LatexHtmlWidgetFactory.new,
          ),
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
          body: HtmlWidget(
            html,
            factoryBuilder: LatexHtmlWidgetFactory.new,
          ),
        ),
      ),
    );

    expect(find.byType(Math), findsNothing);
    expect(find.text(r'\(\)'), findsOneWidget);
  });

  testWidgets('does not overflow for long formulas on narrow width', (tester) async {
    const html =
        '<span class="math-tex">\\(\\frac{\\sum_{i=1}^{n} a_i^2}{\\sqrt{b^2+c^2+d^2+e^2+f^2+g^2+h^2+i^2+j^2}} + \\int_{0}^{\\infty} x^2 dx\\)</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: HtmlWidget(
              html,
              factoryBuilder: LatexHtmlWidgetFactory.new,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles MathJax equation environment without throwing', (tester) async {
    const html =
        '<span class="math-tex">\\begin{equation}E = mc^2\\end{equation}</span>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(
            html,
            factoryBuilder: LatexHtmlWidgetFactory.new,
          ),
        ),
      ),
    );

    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('handles ID 1438 aligned inline content without freezing', (tester) async {
    const html =
        '<p><span class="math-tex">\\(\\begin{aligned}\\n&amp;f(x)=\\frac{x}{x^2+1} \\\\ \\n&amp; \\Rightarrow f^{\\prime}(x)=\\frac{\\left(x^2+1\\right) \\cdot 1-x \\cdot 2 x}{\\left(x^2+1\\right)^2}=\\frac{\\left(1-x^2\\right)}{\\left(x^2+1\\right)^2}\\n\\end{aligned}\\)</span></p>'
        '<p><span class="math-tex">\\(\\begin{aligned}\\n&amp; \\mathrm{f}^{\\prime}(\\mathrm{x})&gt;0 \\Rightarrow \\frac{1-\\mathrm{x}^2}{\\left(\\mathrm{x}^2+1\\right)^2}&gt;0 \\\\ \\n&amp; \\Rightarrow 1-\\mathrm{x}^2&gt;0 \\Rightarrow \\mathrm{x}^2&lt;1 \\Rightarrow-1&lt;\\mathrm{x}&lt;1 \\Rightarrow \\mathrm{x}=(-1,1)\\n\\end{aligned}\\)</span></p>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HtmlWidget(
            html,
            factoryBuilder: LatexHtmlWidgetFactory.new,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
