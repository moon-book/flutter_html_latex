import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';

import 'latex_style_data.dart';

/// Configuration for [LatexHtmlWidgetFactory] customization.
///
/// This class provides callbacks and settings similar to [WidgetFactory],
/// allowing customization of LaTeX rendering behavior, styling, and fallbacks.
///
/// Example:
/// ```dart
/// final config = LatexHtmlWidgetFactoryConfig(
///   customStylesBuilder: (element) {
///     if (element.classes.contains('important')) {
///       return {'color': 'red', 'font-size': '16px'};
///     }
///     return null;
///   },
///   customMathBuilder: (latex, style) {
///     // Return custom widget or null to use default renderer
///     return null;
///   },
/// );
///
/// final factory = LatexHtmlWidgetFactory(config: config);
/// ```
class LatexHtmlWidgetFactoryConfig {
  const LatexHtmlWidgetFactoryConfig({
    this.baseFontSize = 12.0,
    this.defaultColor,
    this.defaultFontFamily,
    this.customStylesBuilder,
    this.customMathBuilder,
    this.onMathError,
    this.enableFallback = true,
    this.mathJaxSupported = false,
    this.responsiveLayout = true,
    this.fallbackScaleInline = 0.86,
    this.fallbackScaleBlock = 0.92,
    this.fallbackVerticalPadding = 2.0,
    this.hyphenationCharacter = '\\u00AD',
  });

  /// Base font size for LaTeX rendering in logical pixels.
  ///
  /// Default: 12.0
  /// Used as the base for height/width calculations if not overridden by inline styles.
  final double baseFontSize;

  /// Default text color for all LaTeX renderings.
  ///
  /// Can be overridden by inline styles or [customStylesBuilder].
  /// If null, uses theme's onSurface color.
  final Color? defaultColor;

  /// Default font family for LaTeX renderings.
  ///
  /// Can be overridden by inline styles or [customStylesBuilder].
  final String? defaultFontFamily;

  /// Builder function to customize styles for specific HTML elements.
  ///
  /// Similar to `flutter_widget_from_html`'s `customStylesBuilder`.
  /// Return a map of CSS property names to values (e.g., `{'color': 'red', 'font-size': '16px'}`).
  /// Return null to use default styles.
  ///
  /// The element will be the parsed HTML DOM element. You can access:
  /// - `element.attributes`: Map of attributes
  /// - `element.classes`: CSS classes
  /// - `element.id`: Element ID
  ///
  /// Example:
  /// ```dart
  /// customStylesBuilder: (element) {
  ///   if (element.id == 'my-equation') {
  ///     return {'color': 'blue', 'font-weight': 'bold'};
  ///   }
  ///   return null;
  /// }
  /// ```
  final Map<String, String>? Function(dynamic)? customStylesBuilder;

  /// Builder function to customize math rendering.
  ///
  /// Called before rendering with Math.tex. Return a custom widget
  /// to override default rendering, or null to use default.
  ///
  /// This allows complete control over how LaTeX is rendered for specific cases.
  ///
  /// Example:
  /// ```dart
  /// customMathBuilder: (latex, style) {
  ///   if (latex.contains('\\\\matrix')) {
  ///     // Use custom matrix renderer
  ///     return MyCustomMatrixWidget(latex);
  ///   }
  ///   return null; // Use default
  /// }
  /// ```
  final Widget? Function(String latex, LatexStyleData style)? customMathBuilder;

  /// Error handler for failed LaTeX renderings.
  ///
  /// Called when both primary (Math.tex) and fallback (Math2SVG) renderers fail.
  /// Return a custom error widget, or null to use default Text fallback.
  ///
  /// Example:
  /// ```dart
  /// onMathError: (error, latex) {
  ///   debugPrint('Failed to render: $latex');
  ///   return Container(
  ///     color: Colors.red.withAlpha(50),
  ///     child: Text('Error: $error'),
  ///   );
  /// }
  /// ```
  final Widget? Function(Object error, String latex)? onMathError;

  /// Enable fallback to Math2SVG (flutter_tex) when Math.tex fails.
  ///
  /// Default: true
  /// If false, Math.tex errors will immediately show error/fallback widget.
  final bool enableFallback;

  /// Enables MathJax-aware fallback heuristics.
  ///
  /// Default: false
  /// - true: uses current detection rules to pre-route risky MathJax patterns
  ///   (e.g. inline `aligned`, `equation`) to `flutter_tex`.
  /// - false: prefers `flutter_math_fork` first and only falls back on real errors.
  final bool mathJaxSupported;

  /// Enable responsive layout with horizontal scrolling.
  ///
  /// Default: true
  /// When true, oversized formulas are wrapped in SingleChildScrollView(Axis.horizontal)
  /// to prevent RenderLine overflow exceptions on narrow screens.
  final bool responsiveLayout;

  /// Scale applied to inline fallback formulas rendered by `flutter_tex`.
  ///
  /// Default: 0.86
  /// Helps match `Math2SVG` visual size with `flutter_math_fork` inline sizing.
  final double fallbackScaleInline;

  /// Scale applied to display/block fallback formulas rendered by `flutter_tex`.
  ///
  /// Default: 0.92
  /// Helps match `Math2SVG` visual size with `flutter_math_fork` display sizing.
  final double fallbackScaleBlock;

  /// Vertical padding around fallback formulas.
  ///
  /// Default: 2.0
  /// Improves baseline and paragraph rhythm when fallback formulas are mixed with
  /// normal text and primary-rendered formulas.
  final double fallbackVerticalPadding;

  /// Soft hyphenation character used in width calculations.
  ///
  /// Default: '\u00AD' (soft hyphen)
  /// Set to empty string to disable hyphenation.
  final String hyphenationCharacter;

  /// Creates a copy of this config with some properties changed.
  LatexHtmlWidgetFactoryConfig copyWith({
    double? baseFontSize,
    Color? defaultColor,
    String? defaultFontFamily,
    Map<String, String>? Function(dynamic)? customStylesBuilder,
    Widget? Function(String, LatexStyleData)? customMathBuilder,
    Widget? Function(Object, String)? onMathError,
    bool? enableFallback,
    bool? mathJaxSupported,
    bool? responsiveLayout,
    double? fallbackScaleInline,
    double? fallbackScaleBlock,
    double? fallbackVerticalPadding,
    String? hyphenationCharacter,
  }) {
    return LatexHtmlWidgetFactoryConfig(
      baseFontSize: baseFontSize ?? this.baseFontSize,
      defaultColor: defaultColor ?? this.defaultColor,
      defaultFontFamily: defaultFontFamily ?? this.defaultFontFamily,
      customStylesBuilder: customStylesBuilder ?? this.customStylesBuilder,
      customMathBuilder: customMathBuilder ?? this.customMathBuilder,
      onMathError: onMathError ?? this.onMathError,
      enableFallback: enableFallback ?? this.enableFallback,
      mathJaxSupported: mathJaxSupported ?? this.mathJaxSupported,
      responsiveLayout: responsiveLayout ?? this.responsiveLayout,
      fallbackScaleInline: fallbackScaleInline ?? this.fallbackScaleInline,
      fallbackScaleBlock: fallbackScaleBlock ?? this.fallbackScaleBlock,
      fallbackVerticalPadding: fallbackVerticalPadding ?? this.fallbackVerticalPadding,
      hyphenationCharacter: hyphenationCharacter ?? this.hyphenationCharacter,
    );
  }

  @override
  String toString() => 'LatexHtmlWidgetFactoryConfig('
      'baseFontSize: $baseFontSize, '
      'defaultColor: $defaultColor, '
      'enableFallback: $enableFallback, '
      'mathJaxSupported: $mathJaxSupported, '
      'responsiveLayout: $responsiveLayout, '
      'fallbackScaleInline: $fallbackScaleInline, '
      'fallbackScaleBlock: $fallbackScaleBlock'
      ')';
}
