import 'package:flutter/material.dart';
import 'package:flutter_html_latex/flutter_html_latex.dart';
import 'package:flutter_html_latex/src/helper/left_aligned_blocks.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';

/// Part c) of question 11817117's solution, as returned by the API.
const _partC =
    '<div>\$-{{x}^{2}}+4x+3=3\\Leftrightarrow -{{x}^{2}}+4x=0\\Leftrightarrow '
    '\\left[ \\begin{array}{*{35}{l}}\r\n   \\begin{align}\r\n'
    '  &amp; x=0 \\\\ \r\n &amp; x=4 \\\\ \r\n\\end{align}  \\\\\r\n'
    '\\end{array} \\right.\$&nbsp;</div>';

/// Part d) of question 11817117's solution, as returned by the API.
const _partD =
    '<div>\$2{{x}^{2}}+x=-2x+5\\Leftrightarrow 2{{x}^{2}}+3x-5=0\\Leftrightarrow '
    '\\left[ \\begin{array}{*{35}{l}}\r\n   \\begin{align}\r\n'
    '  &amp; x=1 \\\\ \r\n &amp; x=-\\frac{5}{2} \\\\ \r\n\\end{align}  \\\\\r\n'
    '\\end{array} \\right.\$&nbsp;</div>';

/// Option A of question 24894612: a bare `aligned` block (no array wrapper).
const _option24894612A =
    '\$\\left\\{ \\begin{aligned}&amp; x=-3-t \\\\&amp; y=1+2t \\\\'
    '&amp; z=-1+4t \\\\\\end{aligned} \\right..\$';

/// Solution of question 23567617: system for point E (bare aligned blocks
/// on both sides of `\Rightarrow`).
const _solution23567617E =
    '\$\\left\\{ \\begin{aligned}  &amp; 3-2t=11-12u \\\\  &amp; 3+t=1+5u \\\\'
    '  &amp; 1=-1+u \\\\ \\end{aligned} \\right.\$\$\\Rightarrow \\left\\{ '
    '\\begin{aligned}  &amp; t=8 \\\\  &amp; u=2 \\\\ \\end{aligned} \\right.\$';

/// Solution of question 23567617, step 3: S1, S2 system.
const _solution23567617S =
    'Khi đó \$\\left\\{ \\begin{aligned}  &amp; {{S}_{1}}={{S}_{CMN}} \\\\'
    '  &amp; {{S}_{2}}={{S}_{MNBA}} \\\\  &amp; {{S}_{1}}+{{S}_{2}}={{S}_{ABC}}'
    ' \\\\ \\end{aligned} \\right..\$';

void main() {
  group('normalizeLeftAlignedBlocks', () {
    test('turns a bare left-aligned block into a plain array', () {
      expect(
        normalizeLeftAlignedBlocks(
          r'\left\{ \begin{aligned}& x=-3-t \\& y=1+2t \\& z=-1+4t \\'
          r'\end{aligned} \right..',
        ),
        r'\left\{ \begin{array}{l} x=-3-t \\ y=1+2t \\ z=-1+4t '
        r'\end{array} \right..',
      );
    });

    test('keeps a bare aligned block with real alignment points', () {
      const tex = r'\begin{aligned} x &= 1 \\ y &= 2 \end{aligned}';
      expect(normalizeLeftAlignedBlocks(tex), tex);
    });

    test('turns an array wrapping one aligned block into a plain array', () {
      expect(
        normalizeLeftAlignedBlocks(
          r'\left[ \begin{array}{ll} \begin{aligned} & x=0 \\ & x=4 \\ '
          r'\end{aligned} \\ \end{array} \right.',
        ),
        r'\left[ \begin{array}{l} x=0 \\ x=4 \end{array} \right.',
      );
    });

    test('handles align and align* written by MathType', () {
      expect(
        normalizeLeftAlignedBlocks(
          r'\begin{array}{l} \begin{align} & a \\ & b \end{align} \end{array}',
        ),
        r'\begin{array}{l} a \\ b \end{array}',
      );
      expect(
        normalizeLeftAlignedBlocks(
          r'\begin{array}{l}\begin{align*}&a\\&b\\\end{align*}\\\end{array}',
        ),
        r'\begin{array}{l} a \\ b \end{array}',
      );
    });

    test('unwraps every matching array in the formula', () {
      expect(
        normalizeLeftAlignedBlocks(
          r'\begin{array}{l}\begin{aligned}&a\end{aligned}\end{array}=\begin{array}{l}\begin{aligned}&b\end{aligned}\end{array}',
        ),
        r'\begin{array}{l} a \end{array}=\begin{array}{l} b \end{array}',
      );
    });

    test('keeps real alignment points inside a row', () {
      const tex =
          r'\begin{array}{l} \begin{aligned} x &= 1 \\ y &= 2 \end{aligned} \end{array}';
      expect(normalizeLeftAlignedBlocks(tex), tex);
    });

    test('keeps the outer array when it holds more than the aligned block', () {
      expect(
        normalizeLeftAlignedBlocks(
          r'\begin{array}{l} a \\ \begin{aligned} & b \end{aligned} \end{array}',
        ),
        r'\begin{array}{l} a \\ \begin{array}{l} b \end{array} \end{array}',
      );
    });

    test('leaves formulas without the pattern untouched', () {
      const tex = r'\left[\begin{array}{l}x=1 \\ x=2\end{array}\right.';
      expect(normalizeLeftAlignedBlocks(tex), same(tex));
    });
  });

  for (final (name, html) in [
    ('c', _partC),
    ('d', _partD),
    ('24894612 option A', _option24894612A),
    ('23567617 step 3 S1/S2 system', _solution23567617S),
  ]) {
    testWidgets('renders solution part $name with flutter_math at text size', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HtmlLatex(
                html,
                style: const TextStyle(fontSize: 15),
                enableFallback: true,
                primaryScaleInline: 1.18,
                primaryScaleBlock: 1.0,
                mathJaxSupported: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Math2SVG), findsNothing);
      final formulas = tester.widgetList<Math>(find.byType(Math)).toList();
      expect(formulas, hasLength(1));
      expect(formulas.single.parseError, isNull);
      expect(formulas.single.options!.fontSize, closeTo(15 * 1.18, 0.001));
    });
  }

  testWidgets('renders both systems around \\Rightarrow at text size', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: HtmlLatex(
              _solution23567617E,
              style: TextStyle(fontSize: 15),
              enableFallback: true,
              primaryScaleInline: 1.18,
              primaryScaleBlock: 1.0,
              mathJaxSupported: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(Math2SVG), findsNothing);
    final formulas = tester.widgetList<Math>(find.byType(Math)).toList();
    expect(formulas, hasLength(2));
    for (final math in formulas) {
      expect(math.parseError, isNull);
      expect(math.options!.fontSize, closeTo(15 * 1.18, 0.001));
    }
  });
}
