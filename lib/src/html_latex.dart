import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'latex_style_data.dart';
import 'latex_widget_factory.dart';
import 'latex_widget_factory_config.dart';

/// A convenience widget to render HTML with LaTeX support.
///
/// This widget provides a TextStyle-like API for package consumers while
/// internally using [LatexHtmlWidgetFactory].
class HtmlLatex extends StatelessWidget {
  const HtmlLatex(
    this.data, {
    super.key,
    this.style,
    this.config,
    this.customStylesBuilder,
    this.customMathBuilder,
    this.onMathError,
    this.enableFallback,
    this.mathJaxSupported,
    this.responsiveLayout,
    this.fallbackScaleInline,
    this.fallbackScaleBlock,
    this.fallbackVerticalPadding,
  });

  /// The HTML content to render.
  final String data;

  /// Default style applied to LaTeX widgets.
  ///
  /// Inline HTML styles and custom style builders still take precedence.
  final TextStyle? style;

  /// Optional base config for the factory.
  final LatexHtmlWidgetFactoryConfig? config;

  /// Optional style builder for per-element customization.
  final Map<String, String>? Function(dynamic element)? customStylesBuilder;

  /// Optional custom math widget builder.
  final Widget? Function(String latex, LatexStyleData style)? customMathBuilder;

  /// Optional error builder for formula rendering failures.
  final Widget? Function(Object error, String latex)? onMathError;

  /// Overrides config's fallback behavior when provided.
  final bool? enableFallback;

  /// Overrides config's MathJax-aware fallback heuristics when provided.
  final bool? mathJaxSupported;

  /// Overrides config's responsive behavior when provided.
  final bool? responsiveLayout;

  /// Overrides config's inline fallback scale when provided.
  final double? fallbackScaleInline;

  /// Overrides config's block fallback scale when provided.
  final double? fallbackScaleBlock;

  /// Overrides config's fallback vertical padding when provided.
  final double? fallbackVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final base = config ?? const LatexHtmlWidgetFactoryConfig();

    final mergedConfig = base.copyWith(
      baseFontSize: style?.fontSize ?? base.baseFontSize,
      defaultColor: style?.color ?? base.defaultColor,
      defaultFontFamily: style?.fontFamily ?? base.defaultFontFamily,
      customMathBuilder: customMathBuilder ?? base.customMathBuilder,
      onMathError: onMathError ?? base.onMathError,
      enableFallback: enableFallback ?? base.enableFallback,
      mathJaxSupported: mathJaxSupported ?? base.mathJaxSupported,
      responsiveLayout: responsiveLayout ?? base.responsiveLayout,
      fallbackScaleInline: fallbackScaleInline ?? base.fallbackScaleInline,
      fallbackScaleBlock: fallbackScaleBlock ?? base.fallbackScaleBlock,
      fallbackVerticalPadding: fallbackVerticalPadding ?? base.fallbackVerticalPadding,
      customStylesBuilder: (element) {
        final fromConfig = base.customStylesBuilder?.call(element);
        final fromWidget = customStylesBuilder?.call(element);
        final fromTextStyle = _textStyleToCss(style);

        if (fromConfig == null && fromWidget == null && fromTextStyle.isEmpty) {
          return null;
        }

        return <String, String>{
          ...?fromConfig,
          ...fromTextStyle,
          ...?fromWidget,
        };
      },
    );

    return HtmlWidget(
      data,
      factoryBuilder: () => LatexHtmlWidgetFactory(config: mergedConfig),
    );
  }

  static Map<String, String> _textStyleToCss(TextStyle? style) {
    if (style == null) {
      return const <String, String>{};
    }

    final css = <String, String>{};

    if (style.color != null) {
      final hex = style.color!.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
      css['color'] = '#$hex';
    }

    if (style.fontSize != null) {
      css['font-size'] = '${style.fontSize}px';
    }

    if (style.fontFamily != null && style.fontFamily!.isNotEmpty) {
      css['font-family'] = style.fontFamily!;
    }

    if (style.fontWeight != null) {
      css['font-weight'] = _fontWeightToCss(style.fontWeight!);
    }

    if (style.fontStyle != null) {
      css['font-style'] = style.fontStyle == FontStyle.italic ? 'italic' : 'normal';
    }

    if (style.letterSpacing != null) {
      css['letter-spacing'] = '${style.letterSpacing}px';
    }

    if (style.wordSpacing != null) {
      css['word-spacing'] = '${style.wordSpacing}px';
    }

    if (style.decoration != null) {
      if (style.decoration == TextDecoration.none) {
        css['text-decoration'] = 'none';
      } else if (style.decoration == TextDecoration.underline) {
        css['text-decoration'] = 'underline';
      } else if (style.decoration == TextDecoration.overline) {
        css['text-decoration'] = 'overline';
      } else if (style.decoration == TextDecoration.lineThrough) {
        css['text-decoration'] = 'line-through';
      }
    }

    if (style.decorationColor != null) {
      final hex = style.decorationColor!
          .toARGB32()
          .toRadixString(16)
          .padLeft(8, '0')
          .toUpperCase();
      css['text-decoration-color'] = '#$hex';
    }

    if (style.decorationStyle != null) {
      css['text-decoration-style'] = switch (style.decorationStyle!) {
        TextDecorationStyle.solid => 'solid',
        TextDecorationStyle.double => 'double',
        TextDecorationStyle.dotted => 'dotted',
        TextDecorationStyle.dashed => 'dashed',
        TextDecorationStyle.wavy => 'wavy',
      };
    }

    return css;
  }

  static String _fontWeightToCss(FontWeight weight) {
    if (weight == FontWeight.w100) return '100';
    if (weight == FontWeight.w200) return '200';
    if (weight == FontWeight.w300) return '300';
    if (weight == FontWeight.w400) return '400';
    if (weight == FontWeight.w500) return '500';
    if (weight == FontWeight.w600) return '600';
    if (weight == FontWeight.w700) return '700';
    if (weight == FontWeight.w800) return '800';
    if (weight == FontWeight.w900) return '900';
    return '400';
  }
}
