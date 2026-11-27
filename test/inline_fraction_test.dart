import 'package:flutter_html_latex/src/helper/inline_fraction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('promoteInlineFractions', () {
    test('promotes a top-level \\frac to \\dfrac', () {
      expect(promoteInlineFractions(r'\frac{3}{10}.'), r'\dfrac{3}{10}.');
    });

    test('promotes every top-level fraction in an expression', () {
      expect(
        promoteInlineFractions(r'P = \frac{0,3}{0,5} + \frac{1}{2}'),
        r'P = \dfrac{0,3}{0,5} + \dfrac{1}{2}',
      );
    });

    test('keeps nested fractions in text style', () {
      expect(
        promoteInlineFractions(r'\frac{1}{1+\frac{1}{x}}'),
        r'\dfrac{1}{1+\frac{1}{x}}',
      );
    });

    test('keeps fractions inside superscripts and subscripts', () {
      expect(promoteInlineFractions(r'x^{\frac{1}{2}}'), r'x^{\frac{1}{2}}');
      expect(promoteInlineFractions(r'x^\frac12'), r'x^\frac12');
      expect(promoteInlineFractions(r'a_ \frac12'), r'a_ \frac12');
    });

    test('leaves \\dfrac, \\tfrac and other commands untouched', () {
      expect(promoteInlineFractions(r'\dfrac{1}{2}'), r'\dfrac{1}{2}');
      expect(promoteInlineFractions(r'\tfrac{1}{2}'), r'\tfrac{1}{2}');
      expect(promoteInlineFractions(r'\fracture'), r'\fracture');
    });

    test('ignores escaped braces when tracking depth', () {
      expect(
        promoteInlineFractions(r'\{ \frac{1}{2} \}'),
        r'\{ \dfrac{1}{2} \}',
      );
    });

    test('promotes fractions with double-braced arguments (q21833805)', () {
      expect(
        promoteInlineFractions(
          r'\Delta :\frac{{x - 2}}{1} = \frac{{y - 3}}{1} = \frac{{z + 1}}{2}',
        ),
        r'\Delta :\dfrac{{x - 2}}{1} = \dfrac{{y - 3}}{1} = \dfrac{{z + 1}}{2}',
      );
    });

    test('promotes solution fractions after \\left...\\right groups', () {
      const tex =
          r'\sin \left( {\Delta ,(P)} \right) = '
          r'\frac{{|1.1 + 1.2 + 2.( - 1)|}}'
          r'{{\sqrt {{1^2} + {1^2} + {2^2}} .\sqrt {{1^2} + {2^2} + {{( - 1)}^2}} }}'
          r' = \frac{1}{6}.';
      final result = promoteInlineFractions(tex);
      expect(RegExp(r'\\dfrac').allMatches(result).length, 2);
      expect(result, isNot(contains(r' \frac')));
    });

    test(
      'promotes \\frac after \\lim _{...} and keeps nested ones (q21803664)',
      () {
        expect(
          promoteInlineFractions(
            r'\lim _{x \rightarrow \pm \infty} '
            r'\frac{x\left(2+\frac{1}{x}\right)}{|x| \sqrt{m+\frac{1}{x}}}',
          ),
          r'\lim _{x \rightarrow \pm \infty} '
          r'\dfrac{x\left(2+\frac{1}{x}\right)}{|x| \sqrt{m+\frac{1}{x}}}',
        );
      },
    );

    test('promotes \\frac inside \\left(...\\right) at top level', () {
      expect(
        promoteInlineFractions(
          r'D=\left(-\frac{1}{\sqrt{-m}} ; \frac{1}{\sqrt{-m}}\right)',
        ),
        r'D=\left(-\dfrac{1}{\sqrt{-m}} ; \dfrac{1}{\sqrt{-m}}\right)',
      );
    });

    test('returns input unchanged when it has no fraction', () {
      expect(promoteInlineFractions(r'P(A|B)=0,5'), r'P(A|B)=0,5');
    });
  });
}
