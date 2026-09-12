# flutter_html_latex example

Visual test app for `flutter_html_latex` using a real JSON dataset.

## What this example demonstrates

- Loads `assets/data_example.json`
- Parses the `data` array into quiz items
- Renders HTML question/options/explanation using `HtmlWidget`
- Renders LaTeX from `<span class="math-tex">...</span>` using
	`LatexHtmlWidgetFactory`

## Run

From this `example` directory:

```bash
flutter pub get
flutter run
```

Open any question from the list to see full details, options, and explanation.
