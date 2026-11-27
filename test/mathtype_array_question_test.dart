import 'package:flutter/material.dart';
import 'package:flutter_html_latex/flutter_html_latex.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tex/flutter_tex.dart';

/// Question 957651: inline system of equations exported by MathType.
const _lineSystemQuestion =
    r'Trong không gian $\left( {Oxyz} \right)$ cho đường thẳng '
    r'$d:\left\{ \begin{array}{*{35}{l}} x=1+t \\ y=t \\ z=-2t \\ '
    r'\end{array}\quad \left( t\in \mathbb{R} \right) \right.$. Gọi '
    r'$\Delta $ là đường thẳng.';

/// Question 11156239: piecewise friction with HTML-escaped `&` and `>`.
const _frictionQuestion =
    r'hệ số ma sát $\text{ }\!\!\mu\!\!\text{ }$ thay đổi như sau '
    r'$\text{ }\!\!\mu\!\!\text{ }=\left\{ \begin{array}{*{35}{l}}'
    '\n'
    r'   0 &amp; \text{ }\!\!~\!\!\text{ khi }\!\!~\!\!\text{ x}\le 0  \\'
    '\n'
    r'   0,5 &amp; \text{ }\!\!~\!\!\text{ khi }\!\!~\!\!\text{ x}&gt;0  \\'
    '\n'
    r'\end{array} \right.$'
    '\nBan đầu giữ vật.';

Future<void> _pumpQuestion(WidgetTester tester, String html) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HtmlLatex(
          html,
          style: const TextStyle(fontSize: 15),
          enableFallback: true,
          primaryScaleInline: 1.18,
          primaryScaleBlock: 1.0,
          mathJaxSupported: true,
        ),
      ),
    ),
  );
}

void main() {
  for (final (name, html) in [
    ('line system (957651)', _lineSystemQuestion),
    ('piecewise friction (11156239)', _frictionQuestion),
  ]) {
    testWidgets('renders $name array with flutter_math, not Math2SVG', (
      tester,
    ) async {
      await _pumpQuestion(tester, html);

      expect(find.byType(Math2SVG), findsNothing);
      expect(find.textContaining(r'\begin{array}'), findsNothing);

      final formulas = tester.widgetList<Math>(find.byType(Math)).toList();
      expect(formulas, isNotEmpty);
      for (final math in formulas) {
        expect(math.parseError, isNull);
        expect(math.options!.fontSize, closeTo(15 * 1.18, 0.001));
      }
    });
  }
}
