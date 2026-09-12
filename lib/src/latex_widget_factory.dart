import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'flutter_html_latex_runtime.dart';
import 'latex_style_data.dart';
import 'latex_widget_factory_config.dart';
import 'style_parser.dart';

/// Widget factory that renders LaTeX elements with comprehensive customization support.
///
/// Supports rendering elements with the following classes:
/// - `math-tex`: General math rendering (inline or display based on delimiters)
/// - `math-display`: Display mode math (large, centered)
/// - `math-inline`: Inline mode math (small, integrated with text)
///
/// Also supports these HTML tags:
/// - `<math>`: Standard HTML5 math element
///
/// This supports common delimiters such as `\(...\)`, `\[...\]`,
/// `$...$`, and `$$...$$`.
///
/// Example usage with customization:
/// ```dart
/// final config = LatexHtmlWidgetFactoryConfig(
///   baseFontSize: 14,
///   defaultColor: Colors.blue,
///   customStylesBuilder: (element) {
///     if (element.classes.contains('important')) {
///       return {'color': 'red', 'font-size': '16px'};
///     }
///     return null;
///   },
/// );
///
/// final factory = LatexHtmlWidgetFactory(config: config);
/// HtmlWidget(html, factoryBuilder: () => factory);
/// ```
class LatexHtmlWidgetFactory extends WidgetFactory {
  /// Creates a [LatexHtmlWidgetFactory] with optional customization config.
  LatexHtmlWidgetFactory({LatexHtmlWidgetFactoryConfig? config})
      : config = config ?? const LatexHtmlWidgetFactoryConfig();

  /// The configuration for this factory instance.
  final LatexHtmlWidgetFactoryConfig config;

  @override
  void parse(BuildTree tree) {
    // Support multiple element classes
    if (tree.element.classes.contains('math-tex') ||
        tree.element.classes.contains('math-display') ||
        tree.element.classes.contains('math-inline') ||
        tree.element.localName == 'math') {
      // Determine if this should be display mode
      bool forceDisplayMode = tree.element.classes.contains('math-display');
      bool forceInlineMode = tree.element.classes.contains('math-inline');

      tree.register(
        BuildOp.inline(
          onRenderInlineBlock: (mathTree, _) => _MathWidgetBuilder(
            config: config,
            tree: mathTree,
            forceDisplayMode: forceDisplayMode,
            forceInlineMode: forceInlineMode,
          ).build(),
        ),
      );
    }

    super.parse(tree);
  }
}

/// Helper class that encapsulates the math widget building logic.
class _MathWidgetBuilder {
  _MathWidgetBuilder({
    required this.config,
    required this.tree,
    required this.forceDisplayMode,
    required this.forceInlineMode,
  });

  final LatexHtmlWidgetFactoryConfig config;
  final BuildTree tree;
  final bool forceDisplayMode;
  final bool forceInlineMode;

  Widget build() {
    final rawText = tree.element.text;
    final parsed = _parseLatex(rawText);
    if (parsed == null) {
      return Text(rawText);
    }

    // Extract styles from HTML attributes and custom builders
    final styleData = LatexStyleData(
      color: config.defaultColor,
      fontSize: config.baseFontSize,
      fontFamily: config.defaultFontFamily,
    ).merge(_extractStyles());

    final fontSize = styleData.fontSize ?? config.baseFontSize;

    // Determine display mode
    bool displayMode = parsed.displayMode;
    if (forceDisplayMode) displayMode = true;
    if (forceInlineMode) displayMode = false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final color = styleData.color ?? 
            config.defaultColor ??
            (Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black);

        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final dynamicWidth = _calculateLatexWidth(parsed.tex, fontSize, width);
        // Check for custom math builder first
        final customWidget = config.customMathBuilder?.call(parsed.tex, styleData);
        if (customWidget != null) {
          return config.responsiveLayout
              ? _wrapResponsive(child: customWidget, maxWidth: width, contentMaxWidth: dynamicWidth)
              : customWidget;
        }

        if (config.enableFallback && _shouldPreferMath2Svg(parsed.tex, isDisplayMode: displayMode)) {
          final earlyFallback = _buildMath2SvgFallback(
            tex: parsed.tex,
            rawText: rawText,
            styleData: styleData,
            dynamicWidth: dynamicWidth,
            dynamicHeight: _calculateLatexHeight(
              parsed.tex,
              styleData.fontSize ?? config.baseFontSize,
            ),
            isDisplayMode: displayMode,
          );

          return config.responsiveLayout
              ? _wrapResponsive(
                  child: earlyFallback,
                  maxWidth: width,
                  contentMaxWidth: dynamicWidth,
                )
              : earlyFallback;
        }

        final mathOptions = MathOptions(
          sizeUnderTextStyle: MathSize.large,
          style: displayMode ? MathStyle.display : MathStyle.text,
          color: color,
          fontSize: fontSize,
        );

        final widget = Math.tex(
          parsed.tex,
          mathStyle: displayMode ? MathStyle.display : MathStyle.text,
          textScaleFactor: 1,
          settings: const TexParserSettings(strict: Strict.ignore),
          options: mathOptions,
          textStyle: styleData.toTextStyle(),
          onErrorFallback: (error) => _buildMathErrorFallback(
            error: error,
            tex: parsed.tex,
            rawText: rawText,
            styleData: styleData,
            dynamicWidth: dynamicWidth,
            width: width,
          ),
        );

        return config.responsiveLayout
            ? _wrapResponsive(
                child: widget,
                maxWidth: width,
                contentMaxWidth: dynamicWidth,
              )
            : widget;
      },
    );
  }

  Widget _buildMathErrorFallback({
    required FlutterMathException error,
    required String tex,
    required String rawText,
    required LatexStyleData styleData,
    required double dynamicWidth,
    required double width,
  }) {
    if (!config.enableFallback) {
      final customError = config.onMathError?.call(error, tex);
      return customError ?? Text(rawText, style: styleData.toTextStyle());
    }

    final fallback = _buildMath2SvgFallback(
      tex: tex,
      rawText: rawText,
      styleData: styleData,
      dynamicWidth: dynamicWidth,
      dynamicHeight: _calculateLatexHeight(tex, styleData.fontSize ?? config.baseFontSize),
      isDisplayMode: _isDisplayMath(tex),
    );

    return config.responsiveLayout
        ? _wrapResponsive(
            child: fallback,
            maxWidth: width,
            contentMaxWidth: dynamicWidth,
          )
        : fallback;
  }

  bool _shouldPreferMath2Svg(String tex, {required bool isDisplayMode}) {
    if (!config.mathJaxSupported) {
      return false;
    }

    // Keep flutter_math_fork as default renderer for quality/performance.
    // Only pre-route known risky patterns that can trigger layout asserts.
    final hasAlignedEnv = RegExp(
      r'\\begin\{(?:aligned|align\*?|gather\*?|multline\*?)\}',
      caseSensitive: false,
    ).hasMatch(tex);
    final hasEquationEnv = RegExp(
      r'\\begin\{equation\*?\}',
      caseSensitive: false,
    ).hasMatch(tex);

    final hasAlignmentMarker = tex.contains('&');
    final hasLatexLineBreak = tex.contains(r'\\');
    final rightArrowCount = RegExp(r'\\Rightarrow').allMatches(tex).length;

    // Primary freeze pattern (like ID:1438): inline-delimited, multiline aligned,
    // heavy chained transformations.
    final riskyInlineAligned =
        !isDisplayMode && hasAlignedEnv && hasLatexLineBreak && hasAlignmentMarker;
    final denseChainedInline =
        !isDisplayMode && hasAlignedEnv && rightArrowCount >= 3;

    // Equation blocks embedded in inline delimiters are also risky.
    final inlineEquationEnv = !isDisplayMode && hasEquationEnv;

    return riskyInlineAligned || denseChainedInline || inlineEquationEnv;
  }

  Widget _buildMath2SvgFallback({
    required String tex,
    required String rawText,
    required LatexStyleData styleData,
    required double dynamicWidth,
    required double dynamicHeight,
    required bool isDisplayMode,
  }) {
    final scale = isDisplayMode ? config.fallbackScaleBlock : config.fallbackScaleInline;
    final verticalPadding = config.fallbackVerticalPadding;

    return FutureBuilder<void>(
      future: FlutterHtmlLatexRuntime.ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final error = snapshot.error ?? Exception('Unknown fallback error');
          final customError = config.onMathError?.call(error, tex);
          return customError ?? Text(rawText, style: styleData.toTextStyle());
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return Text(rawText, style: styleData.toTextStyle());
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: Align(
            alignment: isDisplayMode ? Alignment.centerLeft : Alignment.centerLeft,
            child: Transform.scale(
              alignment: Alignment.centerLeft,
              scale: scale,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 0,
                  maxHeight: dynamicHeight,
                  maxWidth: dynamicWidth,
                ),
                child: Math2SVG(
                  math: tex,
                  loadingWidgetBuilder: (_) => Text(rawText, style: styleData.toTextStyle()),
                  errorWidgetBuilder: (_, error) {
                    final fallbackError = error ?? Exception('Math2SVG render error');
                    final customError = config.onMathError?.call(fallbackError, tex);
                    return customError ?? Text(rawText, style: styleData.toTextStyle());
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isDisplayMath(String tex) {
    if (_shouldPreferMath2Svg(tex, isDisplayMode: true)) {
      return true;
    }

    return tex.contains(r'\\') ||
        tex.contains(r'\sum') ||
        tex.contains(r'\int') ||
        tex.contains(r'\prod');
  }

  LatexStyleData _extractStyles() {
    var styles = <String, String>{};

    // 1. Parse inline style attribute
    final inlineStyle = tree.element.attributes['style'];
    if (inlineStyle != null && inlineStyle.isNotEmpty) {
      final parsed = StyleParser.parseInlineStyle(inlineStyle);
      styles = _styleDataToMap(parsed);
    }

    // 2. Apply custom styles builder
    final customStyles = config.customStylesBuilder?.call(tree.element);
    if (customStyles != null) {
      styles.addAll(customStyles);
    }

    // 3. Build final LatexStyleData
    return StyleParser.parseStyleMap(styles);
  }

  Map<String, String> _styleDataToMap(LatexStyleData data) {
    final map = <String, String>{};

    if (data.color != null) {
      map['color'] = _colorToHex(data.color!);
    }
    if (data.fontSize != null) {
      map['font-size'] = '${data.fontSize!.toInt()}px';
    }
    if (data.fontFamily != null) {
      map['font-family'] = data.fontFamily!;
    }
    if (data.fontWeight != null) {
      map['font-weight'] = _fontWeightToString(data.fontWeight!);
    }
    if (data.fontStyle != null) {
      map['font-style'] = data.fontStyle == FontStyle.italic ? 'italic' : 'normal';
    }

    return map;
  }

  String _colorToHex(Color color) {
    // ignore: deprecated_member_use
    final value = color.value;
    return '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  String _fontWeightToString(FontWeight weight) {
    if (weight == FontWeight.w100) return '100';
    if (weight == FontWeight.w200) return '200';
    if (weight == FontWeight.w300) return '300';
    if (weight == FontWeight.w400) return '400';
    if (weight == FontWeight.w500) return '500';
    if (weight == FontWeight.w600) return '600';
    if (weight == FontWeight.w700) return '700';
    if (weight == FontWeight.w800) return '800';
    if (weight == FontWeight.w900) return '900';
    return '400'; // default
  }

  double _calculateLatexHeight(String tex, double baseFontSize) {
    double height = baseFontSize * 1.2;

    final lineBreaks = RegExp(r'\\\\').allMatches(tex).length;
    final fractions = RegExp(r'\\frac').allMatches(tex).length;
    final binomials = RegExp(r'\\binom|\\choose').allMatches(tex).length;
    final matrices =
        RegExp(r'\\begin\{(matrix|pmatrix|bmatrix|vmatrix|Vmatrix)\}')
            .allMatches(tex)
            .length;
    final arrays = RegExp(r'\\begin\{array\}').allMatches(tex).length;
    final align = RegExp(r'\\begin\{align').allMatches(tex).length;
    final cases = RegExp(r'\\begin\{cases\}').allMatches(tex).length;
    final sqrts = RegExp(r'\\sqrt').allMatches(tex).length;
    final sums = RegExp(r'\\sum|\\int|\\prod|\\iint|\\iiint').allMatches(tex).length;
    final partials = RegExp(r'\\partial|\\frac\{d|\\frac\{\\partial').allMatches(tex).length;
    final limits = RegExp(r'\\limits|_\{|\^\{').allMatches(tex).length;

    if (lineBreaks > 0) {
      height += lineBreaks * (baseFontSize * 1.35);

      if (sums > 0) {
        height += lineBreaks * sums * (baseFontSize * 0.4);
      }

      if (cases > 0 || align > 0) {
        height += lineBreaks * (baseFontSize * 0.3);
      }
    }

    if (fractions > 0) {
      height += fractions * (baseFontSize * 0.8);
    }

    if (binomials > 0) {
      height += binomials * (baseFontSize * 0.6);
    }

    final nestedFracs = _countNestedStructures(tex, r'\frac');
    if (nestedFracs > fractions) {
      height += (nestedFracs - fractions) * (baseFontSize * 0.6);
    }

    if (matrices > 0 || arrays > 0) {
      final matrixCount = matrices + arrays;
      final estimatedRows = lineBreaks > 0 ? lineBreaks + 1 : 2;
      height += matrixCount * estimatedRows * (baseFontSize * 0.88);
    }

    if (sqrts > 0) {
      height += sqrts * (baseFontSize * 0.32);
    }

    if (partials > 0) {
      height += partials * (baseFontSize * 0.4);
    }

    if (sums > 0) {
      height += sums * (baseFontSize * 0.8);

      if (limits > 0) {
        height += baseFontSize * 0.32 * limits;
      }
    }

    if (lineBreaks >= 2 && (fractions > 1 || sums > 1)) {
      height *= 1.15;
    }

    final length = tex.length;
    if (length > 50 && lineBreaks == 0) {
      height += (length - 50) * 0.096;
    }

    return height.clamp(baseFontSize * 1.2, 125.0);
  }

  double _calculateLatexWidth(String tex, double baseFontSize, double availableWidth) {
    final lineBreaks = RegExp(r'\\\\').allMatches(tex).length;
    final fractions = RegExp(r'\\frac').allMatches(tex).length;
    final binomials = RegExp(r'\\binom|\\choose').allMatches(tex).length;
    final matrices =
        RegExp(r'\\begin\{(matrix|pmatrix|bmatrix|vmatrix|Vmatrix)\}')
            .allMatches(tex)
            .length;
    final arrays = RegExp(r'\\begin\{array\}').allMatches(tex).length;
    final sums = RegExp(r'\\sum|\\int|\\prod|\\iint|\\iiint').allMatches(tex).length;
    final partials = RegExp(r'\\partial|\\frac\{d|\\frac\{\\partial').allMatches(tex).length;
    final limits = RegExp(r'\\limits|_\{|\^\{').allMatches(tex).length;

    double width = tex.length * (baseFontSize * 0.58);
    width += fractions * (baseFontSize * 2.4);
    width += binomials * (baseFontSize * 1.5);
    width += (matrices + arrays) * (baseFontSize * 10);
    width += sums * (baseFontSize * 5);
    width += partials * (baseFontSize * 3.5);
    width += limits * (baseFontSize * 1.8);

    final nestedFracs = _countNestedStructures(tex, r'\frac');
    if (nestedFracs > 1) {
      width += (nestedFracs - 1) * (baseFontSize * 3);
    }

    // Multi-line formulas generally need less width.
    if (lineBreaks > 0) {
      width *= 0.78;
    }

    final minWidth = availableWidth * 0.35;
    final maxWidth = availableWidth * 2.2;
    return width.clamp(minWidth, maxWidth);
  }

  int _countNestedStructures(String tex, String command) {
    var depth = 0;
    var maxDepth = 0;

    var i = 0;
    while (i < tex.length) {
      if (i <= tex.length - command.length && tex.substring(i, i + command.length) == command) {
        depth++;
        maxDepth = maxDepth > depth ? maxDepth : depth;
        i += command.length;
      } else if (tex[i] == '}') {
        if (depth > 0) {
          depth--;
        }
        i++;
      } else {
        i++;
      }
    }

    return maxDepth;
  }
}

Widget _wrapResponsive({
  required Widget child,
  required double maxWidth,
  required double contentMaxWidth,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: child,
  );
}

class _LatexPayload {
  const _LatexPayload({required this.tex, required this.displayMode});

  final String tex;
  final bool displayMode;
}

_LatexPayload? _parseLatex(String rawText) {
  final raw = rawText.trim();
  if (raw.isEmpty) {
    return null;
  }

  final wrappers = <({String open, String close, bool displayMode})>[
    (open: r'\[', close: r'\]', displayMode: true),
    (open: r'\(', close: r'\)', displayMode: false),
    (open: r'$$', close: r'$$', displayMode: true),
    (open: r'$', close: r'$', displayMode: false),
  ];

  for (final wrapper in wrappers) {
    if (raw.startsWith(wrapper.open) && raw.endsWith(wrapper.close)) {
      final start = wrapper.open.length;
      final end = raw.length - wrapper.close.length;
      final inner = raw.substring(start, end).trim();
      if (inner.isEmpty) {
        return null;
      }

      return _LatexPayload(tex: inner, displayMode: wrapper.displayMode);
    }
  }

  return _LatexPayload(tex: raw, displayMode: false);
}