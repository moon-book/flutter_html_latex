import 'package:flutter/material.dart';

/// Holds style information for LaTeX rendering extracted from HTML elements.
///
/// This class encapsulates all customizable styling options that can be applied
/// to both `flutter_math_fork` and `flutter_tex` renderers.
class LatexStyleData {
  const LatexStyleData({
    this.color,
    this.fontSize,
    this.fontFamily,
    this.fontWeight,
    this.fontStyle,
    this.letterSpacing,
    this.wordSpacing,
    this.height,
    this.backgroundColor,
    this.decoration,
    this.decorationColor,
    this.decorationStyle,
    this.decorationThickness,
    this.shadows,
  });

  /// Text color for the LaTeX rendering.
  ///
  /// Applied to both `flutter_math_fork` (via Math.tex options.color)
  /// and `flutter_tex` (as color filter on SVG).
  final Color? color;

  /// Font size in logical pixels.
  ///
  /// Controls the size of rendered LaTeX. Default is 12.0.
  final double? fontSize;

  /// Font family name for the rendered text.
  ///
  /// Applied to `flutter_math_fork` text styles.
  final String? fontFamily;

  /// Font weight (100–900 or w100–w900).
  final FontWeight? fontWeight;

  /// Font style (italic or normal).
  final FontStyle? fontStyle;

  /// Letter spacing in logical pixels.
  final double? letterSpacing;

  /// Word spacing in logical pixels.
  final double? wordSpacing;

  /// Line height multiplier.
  final double? height;

  /// Background color for the LaTeX rendering area.
  final Color? backgroundColor;

  /// Text decoration (underline, overline, line-through).
  final TextDecoration? decoration;

  /// Color for text decoration.
  final Color? decorationColor;

  /// Style of text decoration (solid, dotted, dashed, double, wavy).
  final TextDecorationStyle? decorationStyle;

  /// Thickness of text decoration as a percentage (0.0–1.0).
  final double? decorationThickness;

  /// Text shadows for the rendered LaTeX.
  final List<Shadow>? shadows;

  /// Converts this [LatexStyleData] to a [TextStyle].
  ///
  /// This is useful for applying styles to fallback text widgets
  /// and error messages.
  TextStyle toTextStyle() {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontFamily: fontFamily,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      height: height,
      backgroundColor: backgroundColor,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      shadows: shadows,
    );
  }

  /// Merges this [LatexStyleData] with another, with the other taking precedence.
  LatexStyleData merge(LatexStyleData? other) {
    if (other == null) return this;

    return LatexStyleData(
      color: other.color ?? color,
      fontSize: other.fontSize ?? fontSize,
      fontFamily: other.fontFamily ?? fontFamily,
      fontWeight: other.fontWeight ?? fontWeight,
      fontStyle: other.fontStyle ?? fontStyle,
      letterSpacing: other.letterSpacing ?? letterSpacing,
      wordSpacing: other.wordSpacing ?? wordSpacing,
      height: other.height ?? height,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      decoration: other.decoration ?? decoration,
      decorationColor: other.decorationColor ?? decorationColor,
      decorationStyle: other.decorationStyle ?? decorationStyle,
      decorationThickness: other.decorationThickness ?? decorationThickness,
      shadows: other.shadows ?? shadows,
    );
  }

  @override
  String toString() => 'LatexStyleData('
      'color: $color, '
      'fontSize: $fontSize, '
      'fontFamily: $fontFamily, '
      'fontWeight: $fontWeight, '
      'fontStyle: $fontStyle'
      ')';
}
