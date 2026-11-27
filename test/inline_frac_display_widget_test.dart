import 'package:flutter/material.dart';
import 'package:flutter_html_latex/flutter_html_latex.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _renderedTex(
  WidgetTester tester,
  String data, {
  bool? inlineFracAsDisplay,
}) async {
  final captured = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HtmlLatex(
          data,
          inlineFracAsDisplay: inlineFracAsDisplay,
          customMathBuilder: (latex, style) {
            captured.add(latex);
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('promotes inline \\frac by default', (tester) async {
    final tex = await _renderedTex(tester, r'$\frac{3}{10}.$.');
    expect(tex, isNotEmpty);
    expect(tex.every((t) => t.contains(r'\dfrac{3}{10}')), isTrue);
  });

  testWidgets('keeps inline \\frac when inlineFracAsDisplay is off', (
    tester,
  ) async {
    final tex = await _renderedTex(
      tester,
      r'$\frac{3}{10}$',
      inlineFracAsDisplay: false,
    );
    expect(tex, isNotEmpty);
    expect(tex.every((t) => t.contains(r'\frac{3}{10}')), isTrue);
    expect(tex.any((t) => t.contains(r'\dfrac')), isFalse);
  });

  testWidgets('does not touch display math', (tester) async {
    final tex = await _renderedTex(tester, r'$$\frac{3}{10}$$');
    expect(tex, isNotEmpty);
    expect(tex.any((t) => t.contains(r'\dfrac')), isFalse);
  });

  test('config defaults to true and copyWith carries the flag', () {
    const base = LatexHtmlWidgetFactoryConfig();
    expect(base.inlineFracAsDisplay, isTrue);
    expect(
      base.copyWith(inlineFracAsDisplay: false).inlineFracAsDisplay,
      isFalse,
    );
  });
}
