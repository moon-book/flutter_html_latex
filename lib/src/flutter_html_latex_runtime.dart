import 'package:flutter/widgets.dart';
import 'package:flutter_tex/flutter_tex.dart';

/// Runtime bootstrap helpers for `flutter_html_latex`.
class FlutterHtmlLatexRuntime {
  static Future<void>? _startupFuture;

  /// Initializes Flutter and the TeX rendering server.
  ///
  /// Call this once before `runApp` for best fallback behavior.
  static Future<void> ensureInitialized() {
    WidgetsFlutterBinding.ensureInitialized();
    return _startupFuture ??= TeXRenderingServer.start();
  }
}