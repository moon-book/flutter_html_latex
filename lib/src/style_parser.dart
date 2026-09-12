import 'package:flutter/material.dart';

import 'latex_style_data.dart';

/// Parses HTML/CSS style attributes and converts them to [LatexStyleData].
class StyleParser {
  /// Parses a CSS style string and returns [LatexStyleData].
  ///
  /// Example:
  /// ```
  /// "color: red; font-size: 16px; font-family: Arial"
  /// ```
  static LatexStyleData parseInlineStyle(String styleString) {
    final styles = <String, String>{};

    for (final property in styleString.split(';')) {
      final trimmed = property.trim();
      if (trimmed.isEmpty) continue;

      final parts = trimmed.split(':');
      if (parts.length != 2) continue;

      final name = parts[0].trim().toLowerCase();
      final value = parts[1].trim();

      styles[name] = value;
    }

    return _buildLatexStyleData(styles);
  }

  /// Parses a map of CSS style properties and returns [LatexStyleData].
  static LatexStyleData parseStyleMap(Map<String, String> styleMap) {
    return _buildLatexStyleData(styleMap);
  }

  /// Converts a CSS color value to a Flutter [Color].
  ///
  /// Supports:
  /// - Hex colors: #RGB, #RRGGBB, #RRGGBBAA
  /// - Named colors: red, blue, green, etc.
  /// - rgb(): rgb(255, 0, 0), rgb(255, 0, 0, 0.5)
  /// - rgba(): rgba(255, 0, 0, 0.5)
  static Color? parseColor(String colorValue) {
    colorValue = colorValue.trim().toLowerCase();

    // Hex color
    if (colorValue.startsWith('#')) {
      colorValue = colorValue.substring(1);
      try {
        if (colorValue.length == 6) {
          // ignore: deprecated_member_use
          return Color(int.parse('FF$colorValue', radix: 16));
        } else if (colorValue.length == 8) {
          // ignore: deprecated_member_use
          return Color(int.parse(colorValue, radix: 16));
        } else if (colorValue.length == 3) {
          // Expand #RGB to #RRGGBB
          final expanded =
              colorValue.split('').map((c) => '$c$c').join();
          // ignore: deprecated_member_use
          return Color(int.parse('FF$expanded', radix: 16));
        }
      } catch (_) {
        return null;
      }
    }

    // rgb() or rgba()
    if (colorValue.startsWith('rgb')) {
      final match = RegExp(r'rgba?\s*\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*(?:,\s*([\d.]+))?\s*\)')
          .firstMatch(colorValue);
      if (match != null) {
        final r = int.parse(match.group(1)!);
        final g = int.parse(match.group(2)!);
        final b = int.parse(match.group(3)!);
        final a = match.group(4) != null ? (double.parse(match.group(4)!) * 255).toInt() : 255;
        return Color.fromARGB(a, r, g, b);
      }
    }

    // Named colors
    return _parseNamedColor(colorValue);
  }

  /// Converts a CSS font-size value to points.
  ///
  /// Supports: px, pt, em, rem, %
  static double? parseFontSize(String sizeValue, {double baseFontSize = 12}) {
    sizeValue = sizeValue.trim().toLowerCase();

    if (sizeValue.endsWith('px')) {
      return double.tryParse(sizeValue.replaceAll('px', ''));
    } else if (sizeValue.endsWith('pt')) {
      return double.tryParse(sizeValue.replaceAll('pt', ''));
    } else if (sizeValue.endsWith('em')) {
      final value = double.tryParse(sizeValue.replaceAll('em', ''));
      return value != null ? value * baseFontSize : null;
    } else if (sizeValue.endsWith('rem')) {
      final value = double.tryParse(sizeValue.replaceAll('rem', ''));
      return value != null ? value * baseFontSize : null;
    } else if (sizeValue.endsWith('%')) {
      final value = double.tryParse(sizeValue.replaceAll('%', ''));
      return value != null ? (value / 100) * baseFontSize : null;
    } else {
      return double.tryParse(sizeValue);
    }
  }

  /// Parses CSS font-weight to Flutter [FontWeight].
  static FontWeight? parseFontWeight(String weightValue) {
    weightValue = weightValue.trim().toLowerCase();

    return switch (weightValue) {
      'normal' || '400' => FontWeight.normal,
      'bold' || '700' => FontWeight.bold,
      '100' => FontWeight.w100,
      '200' => FontWeight.w200,
      '300' => FontWeight.w300,
      '500' => FontWeight.w500,
      '600' => FontWeight.w600,
      '800' => FontWeight.w800,
      '900' => FontWeight.w900,
      'lighter' => FontWeight.w300,
      'bolder' => FontWeight.w700,
      _ => null,
    };
  }

  /// Parses CSS font-style to Flutter [FontStyle].
  static FontStyle? parseFontStyle(String styleValue) {
    styleValue = styleValue.trim().toLowerCase();
    return switch (styleValue) {
      'italic' => FontStyle.italic,
      'normal' => FontStyle.normal,
      _ => null,
    };
  }

  /// Parses CSS text-decoration to Flutter [TextDecoration].
  static TextDecoration? parseTextDecoration(String decorationValue) {
    decorationValue = decorationValue.trim().toLowerCase();

    if (decorationValue.contains('underline')) {
      return TextDecoration.underline;
    } else if (decorationValue.contains('overline')) {
      return TextDecoration.overline;
    } else if (decorationValue.contains('line-through')) {
      return TextDecoration.lineThrough;
    } else if (decorationValue == 'none') {
      return TextDecoration.none;
    }

    return null;
  }

  /// Parses CSS text-decoration-style to Flutter [TextDecorationStyle].
  static TextDecorationStyle? parseTextDecorationStyle(String styleValue) {
    styleValue = styleValue.trim().toLowerCase();
    return switch (styleValue) {
      'solid' => TextDecorationStyle.solid,
      'double' => TextDecorationStyle.double,
      'dotted' => TextDecorationStyle.dotted,
      'dashed' => TextDecorationStyle.dashed,
      'wavy' => TextDecorationStyle.wavy,
      _ => null,
    };
  }

  // Private helper to build LatexStyleData from style properties
  static LatexStyleData _buildLatexStyleData(Map<String, String> styles) {
    Color? color;
    double? fontSize;
    FontWeight? fontWeight;
    FontStyle? fontStyle;
    TextDecoration? decoration;
    TextDecorationStyle? decorationStyle;
    Color? decorationColor;
    double? letterSpacing;
    double? wordSpacing;

    for (final MapEntry(:key, :value) in styles.entries) {
      switch (key) {
        case 'color':
          color = parseColor(value) ?? color;
          break;
        case 'font-size':
          fontSize = parseFontSize(value) ?? fontSize;
          break;
        case 'font-weight':
          fontWeight = parseFontWeight(value) ?? fontWeight;
          break;
        case 'font-style':
          fontStyle = parseFontStyle(value) ?? fontStyle;
          break;
        case 'text-decoration' || 'text-decoration-line':
          decoration = parseTextDecoration(value) ?? decoration;
          break;
        case 'text-decoration-style':
          decorationStyle = parseTextDecorationStyle(value) ?? decorationStyle;
          break;
        case 'text-decoration-color':
          decorationColor = parseColor(value) ?? decorationColor;
          break;
        case 'letter-spacing':
          letterSpacing = parseFontSize(value) ?? letterSpacing;
          break;
        case 'word-spacing':
          wordSpacing = parseFontSize(value) ?? wordSpacing;
          break;
      }
    }

    return LatexStyleData(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      decoration: decoration,
      decorationStyle: decorationStyle,
      decorationColor: decorationColor,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
    );
  }

  // Private helper to parse CSS named colors
  static Color? _parseNamedColor(String colorName) {
    return switch (colorName) {
      'red' => Colors.red,
      'green' => Colors.green,
      'blue' => Colors.blue,
      'yellow' => Colors.yellow,
      'orange' => Colors.orange,
      'purple' || 'violet' => Colors.purple,
      'pink' => Colors.pink,
      'cyan' => Colors.cyan,
      'black' => Colors.black,
      'white' => Colors.white,
      'gray' || 'grey' => Colors.grey,
      'brown' => Colors.brown,
      'transparent' => Colors.transparent,
      'amber' => Colors.amber,
      'indigo' => Colors.indigo,
      'teal' => Colors.teal,
      'lime' => Colors.lime,
      'deep-orange' || 'deeporange' => Colors.deepOrange,
      'deep-purple' || 'deeppurple' => Colors.deepPurple,
      'light-blue' || 'lightblue' => Colors.lightBlue,
      'light-green' || 'lightgreen' => Colors.lightGreen,
      _ => null,
    };
  }
}
