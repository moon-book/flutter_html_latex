# flutter_html_latex

`flutter_html_latex` is a production-ready Flutter package for rendering LaTeX equations within HTML content. It provides seamless math equation support with multiple rendering backends and comprehensive customization options.

## Features

- **Dual Rendering Engines**: Primary `flutter_math_fork` (KaTeX-style, fast, clean) with fallback to `flutter_tex` (MathJax-based, complex formulas)
- **User-Friendly API**: Simple `HtmlLatex(...)` widget for HTML + LaTeX content
- **Flexible Configuration**: Extensive customization with presets for different use cases
- **Error Handling**: Graceful fallbacks and custom error widgets
- **Responsive Layout**: Automatic handling of wide equations with scrolling support
- **Global Compatibility**: Support for various LaTeX delimiters and HTML patterns

## Why This Package?

Many APIs and CMS platforms deliver equations in HTML like this:

```html
<span class="math-tex">\(x^2 + 2x + 1\)</span>
```

While `flutter_widget_from_html_core` handles HTML rendering, it doesn't render LaTeX equations. `flutter_html_latex` fills this gap with intelligent equation detection and rendering.

## Demo

### MathJax Supported: false (KaTeX-first mode)
![KaTeX Mode](https://raw.githubusercontent.com/avijitbarua/flutter_html_latex/refs/heads/main/demos/MathJax-Supported-false.png)

### MathJax Supported: true (MathJax-aware mode)
![MathJax Mode](https://raw.githubusercontent.com/avijitbarua/flutter_html_latex/refs/heads/main/demos/MathJax-Supported-true.png)

## Renderer Strategy (Important)

The package uses an intelligent strategy to choose the best renderer:

### Default Behavior (`mathJaxSupported: false`)
- **Best For**: KaTeX-compatible content
- **Strategy**: Prefers `flutter_math_fork` for optimal quality and performance
- **Fallback**: Only switches to `flutter_tex` on rendering errors
- **Ideal When**: Your data consists mostly of standard LaTeX equations

### MathJax-Aware Mode (`mathJaxSupported: true`)
- **Best For**: MathJax-generated content (with `aligned`, `equation` environments)
- **Strategy**: Uses heuristics to detect complex patterns that need MathJax
- **Benefit**: Safer handling of advanced LaTeX environments
- **Trade-off**: More frequent use of the fallback renderer
- **Ideal When**: Data includes complex aligned environments or MathJax-specific patterns

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_html_latex: ^1.0.0
```

## Project Setup (Required)

### 1) Initialize Runtime in main.dart

Before calling `runApp()`, initialize the runtime:

```dart
import 'package:flutter_html_latex/flutter_html_latex.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterHtmlLatexRuntime.ensureInitialized();
  runApp(const MyApp());
}
```

### 2) Android Configuration (Recommended)

In `example/android/app/src/main/AndroidManifest.xml`, add this to the `<application>` tag:

```xml
<application
    android:label="your_app"
    android:enableOnBackInvokedCallback="true"
    ...>
```

## Quick Usage

```dart
HtmlLatex(
  htmlData,
  style: const TextStyle(
    fontSize: 15,
    color: Colors.black87,
  ),
)
```

## HtmlLatex Widget Parameters

### Constructor Parameters

`HtmlLatex(data, ...)` supports the following parameters:

1. **`data`** (`String`, required)
   - HTML string containing LaTeX equations
   - Supports multiple delimiter formats

2. **`style`** (`TextStyle?`)
   - Default text styling applied to equation content
   - Supports: color, fontSize, fontFamily, fontWeight, fontStyle, letterSpacing, wordSpacing, decoration

3. **`config`** (`LatexHtmlWidgetFactoryConfig?`)
   - Low-level advanced configuration for fine-tuned control

4. **`customStylesBuilder`** (`Map<String, String>? Function(dynamic)?`)
   - Per-element CSS customization based on HTML attributes

5. **`customMathBuilder`** (`Widget? Function(String, LatexStyleData)?`)
   - Override specific formulas with custom widgets

6. **`onMathError`** (`Widget? Function(Object, String)?`)
   - Custom widget displayed when equation rendering fails

7. **`enableFallback`** (`bool?`)
   - Enable/disable fallback from `flutter_math_fork` to `flutter_tex`
   - Default: `true` (fallback enabled)

8. **`mathJaxSupported`** (`bool?`)
   - `false` (default): KaTeX-first mode, optimal for standard LaTeX
   - `true`: MathJax-aware mode, better for complex environments

9. **`responsiveLayout`** (`bool?`)
   - Enable horizontal scroll wrapper for wide equations
   - Default: `true`

10. **`fallbackScaleInline`** (`double?`)
    - Scale factor for inline fallback equations
    - Default: `0.86`

11. **`fallbackScaleBlock`** (`double?`)
    - Scale factor for block fallback equations
    - Default: `0.92`

12. **`fallbackVerticalPadding`** (`double?`)
    - Vertical padding adjustment for fallback equations
    - Default: `2.0`

## LatexHtmlWidgetFactoryConfig Parameters

For advanced configuration, use `LatexHtmlWidgetFactoryConfig`:

```dart
LatexHtmlWidgetFactoryConfig(
  baseFontSize: 12.0,
  defaultColor: Colors.black,
  defaultFontFamily: 'Roboto',
  customStylesBuilder: (element) => {},
  customMathBuilder: (formula, style) => null,
  onMathError: (error, formula) => null,
  enableFallback: true,
  mathJaxSupported: false,
  responsiveLayout: true,
  fallbackScaleInline: 0.86,
  fallbackScaleBlock: 0.92,
  fallbackVerticalPadding: 2.0,
  hyphenationCharacter: '\u00AD', // soft hyphen
)
```

## Recommended Configuration Presets

### Preset A: KaTeX-First (Default - Recommended)

Best for standard LaTeX content with optimal performance:

```dart
HtmlLatex(
  data,
  mathJaxSupported: false,
  enableFallback: true,
)
```

**Use When:**
- Your data primarily contains standard LaTeX equations
- You want maximum performance and visual quality
- MathJax-specific patterns are not expected

### Preset B: MathJax-Heavy Content

Better support for complex MathJax environments:

```dart
HtmlLatex(
  data,
  mathJaxSupported: true,
  enableFallback: true,
  fallbackScaleInline: 0.84,
  fallbackScaleBlock: 0.90,
  fallbackVerticalPadding: 1.5,
)
```

**Use When:**
- Data frequently includes `aligned`, `equation`, or `gather` environments
- You want safer handling of potentially problematic formulas
- Rendering quality is more important than performance

## Supported HTML Patterns

The package automatically detects and renders equations in these HTML patterns:

```html
<!-- Class-based patterns -->
<span class="math-tex">\( ... \)</span>
<span class="math-display">\[ ... \]</span>
<span class="math-inline">\( ... \)</span>

<!-- Custom math elements -->
<math>\( ... \)</math>
```

## Supported Delimiters

The package recognizes these LaTeX delimiters:

- **Inline Math**: `\(...\)` or `$...$`
- **Display Math**: `\[...\]` or `$$...$$`

## Troubleshooting

### Issue: Equations freeze or crash in debug mode

**Solution:**
```dart
HtmlLatex(
  data,
  mathJaxSupported: true,  // Switch to MathJax mode
  enableFallback: true,    // Ensure fallback is enabled
)
```

### Issue: Fallback equation size doesn't match

**Solution:** Adjust scaling parameters:
```dart
HtmlLatex(
  data,
  fallbackScaleInline: 0.84,      // Adjust inline scale
  fallbackScaleBlock: 0.90,        // Adjust block scale
  fallbackVerticalPadding: 1.5,    // Adjust vertical spacing
)
```

### Issue: Formula not rendering

**Checklist:**
- Verify delimiter syntax is correct (`\(`, `\[`, `$`, `$$`)
- Ensure LaTeX is valid (check for typos or unsupported commands)
- Check if content is inside the correct HTML class (`math-tex`, `math-display`, etc.)
- Enable `mathJaxSupported: true` if using complex environments

## Example Implementation

From the example app:

```dart
const kMathJaxSupported = true; // Switch: false / true

HtmlLatex(
  item.explanation,
  mathJaxSupported: kMathJaxSupported,
  style: const TextStyle(
    fontSize: 15,
    color: Colors.black87,
  ),
  fallbackScaleInline: 0.84,
  fallbackScaleBlock: 0.90,
  fallbackVerticalPadding: 1.5,
)
```

## License

MIT License. See [LICENSE](LICENSE) for details.
