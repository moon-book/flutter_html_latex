import 'package:flutter/material.dart';
import 'package:flutter_html_latex/src/helper/array_column_spec.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('expandArrayColumnRepeats', () {
    test('expands *{n}{l} to the number of columns actually used', () {
      expect(
        expandArrayColumnRepeats(
          r'\begin{array}{*{35}{l}} x=1+t \\ y=t \\ z=-2t \\ \end{array}',
        ),
        r'\begin{array}{l} x=1+t \\ y=t \\ z=-2t \\ \end{array}',
      );
    });

    test('keeps one column per & separated cell', () {
      expect(
        expandArrayColumnRepeats(
          r'\begin{array}{*{35}{l}} 0 & a \\ 0,5 & b \\ \end{array}',
        ),
        r'\begin{array}{ll} 0 & a \\ 0,5 & b \\ \end{array}',
      );
    });

    test('expands repeats mixed with other column specs', () {
      expect(
        expandArrayColumnRepeats(r'\begin{array}{|*{2}{c|}} a & b \end{array}'),
        r'\begin{array}{|c|c|} a & b \end{array}',
      );
    });

    test('expands every array in the formula', () {
      expect(
        expandArrayColumnRepeats(
          r'\begin{array}{*{3}{l}} a \end{array}+\begin{array}{*{3}{r}} b & c \end{array}',
        ),
        r'\begin{array}{l} a \end{array}+\begin{array}{rr} b & c \end{array}',
      );
    });

    test('leaves formulas without repeat specs untouched', () {
      const tex = r'\begin{array}{l} x \\ y \end{array}';
      expect(expandArrayColumnRepeats(tex), same(tex));
      expect(expandArrayColumnRepeats(r'a*b'), r'a*b');
    });

    test('leaves malformed repeat specs untouched', () {
      const tex = r'\begin{array}{*{x}{l}} a \end{array}';
      expect(expandArrayColumnRepeats(tex), tex);
    });
  });

  testWidgets('flutter_math parses the expanded MathType array', (
    tester,
  ) async {
    Object? error;
    final tex = expandArrayColumnRepeats(
      r'd:\left\{ \begin{array}{*{35}{l}} x=1+t \\ y=t \\ z=-2t \\ '
      r'\end{array}\quad \left( t\in \mathbb{R} \right) \right.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Math.tex(
            tex,
            options: MathOptions(fontSize: 17.7, style: MathStyle.text),
            onErrorFallback: (e) {
              error = e;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    expect(error, isNull);
  });
}
