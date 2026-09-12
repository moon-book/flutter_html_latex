import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html_latex/flutter_html_latex.dart';

// Toggle this to compare rendering behavior:
// false -> prefer flutter_math_fork (KaTeX-style data)
// true  -> enable MathJax-aware fallback heuristics
const kMathJaxSupported = true;

Future<void> main() async {
  await FlutterHtmlLatexRuntime.ensureInitialized();
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'flutter_html_latex example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6E6E)),
        useMaterial3: true,
      ),
      home: const QuizListPage(),
    );
  }
}

class QuizItem {
  const QuizItem({
    required this.id,
    required this.subject,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  final int id;
  final String subject;
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      id: json['ID'] as int? ?? 0,
      subject: json['subject'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => e.toString())
          .toList(growable: false),
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
    );
  }

  int? get answerIndex {
    if (!answer.startsWith('Option')) {
      return null;
    }

    final suffix = answer.substring('Option'.length).trim();
    if (suffix.isEmpty) {
      return null;
    }

    final charCode = suffix.toUpperCase().codeUnitAt(0);
    final index = charCode - 65;
    if (index < 0 || index >= options.length) {
      return null;
    }

    return index;
  }
}

Future<List<QuizItem>> loadQuizItems() async {
  final raw = await rootBundle.loadString('assets/data_example.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;
  final list = decoded['data'] as List<dynamic>? ?? const <dynamic>[];
  return list
      .whereType<Map<String, dynamic>>()
      .map(QuizItem.fromJson)
      .toList(growable: false);
}

class QuizListPage extends StatelessWidget {
  const QuizListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JSON + LaTeX Visual Test')),
      body: FutureBuilder<List<QuizItem>>(
        future: loadQuizItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load JSON: ${snapshot.error}'),
              ),
            );
          }

          final items = snapshot.data ?? const <QuizItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('No data in data_example.json'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text('${item.id} - ${item.subject}'),
                subtitle: HtmlLatex(
                  item.question,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                  mathJaxSupported: kMathJaxSupported,
                  fallbackScaleInline: 0.84, // tune 0.82–0.90
                  fallbackScaleBlock: 0.90, // tune 0.88–0.96
                  fallbackVerticalPadding: 1.5, // tune 0–4
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuizDetailPage(item: item),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class QuizDetailPage extends StatelessWidget {
  const QuizDetailPage({required this.item, super.key});

  final QuizItem item;

  @override
  Widget build(BuildContext context) {
    final answerIndex = item.answerIndex;

    return Scaffold(
      appBar: AppBar(title: Text('Question ${item.id}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Subject: ${item.subject}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          const Text('Question', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          HtmlLatex(
            item.question,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            mathJaxSupported: kMathJaxSupported,
          ),
          const SizedBox(height: 16),
          const Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (var i = 0; i < item.options.length; i++)
            Card(
              color: answerIndex == i
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${String.fromCharCode(65 + i)}. '),
                    Expanded(
                      child: HtmlLatex(
                        item.options[i],
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        mathJaxSupported: kMathJaxSupported,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Explanation',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (item.explanation.trim().isEmpty)
            const Text('No explanation provided.')
          else
            HtmlLatex(
              item.explanation,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
              mathJaxSupported: kMathJaxSupported,
              fallbackScaleInline: 0.84, // tune 0.82–0.90
              fallbackScaleBlock: 0.90, // tune 0.88–0.96
              fallbackVerticalPadding: 1.5, // tune 0–4
            ),
        ],
      ),
    );
  }
}
