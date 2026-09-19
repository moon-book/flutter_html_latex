import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class HtmlSelectionContainer extends StatefulWidget {
  const HtmlSelectionContainer({super.key, required this.child});

  final Widget child;

  @override
  State<HtmlSelectionContainer> createState() => _HtmlSelectionContainerState();
}

class _HtmlSelectionContainerState extends State<HtmlSelectionContainer> {
  late final _HtmlSelectionDelegate _delegate = _HtmlSelectionDelegate();

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionContainer(delegate: _delegate, child: widget.child);
  }
}

class _HtmlSelectionDelegate extends StaticSelectionContainerDelegate {
  @override
  Comparator<Selectable> get compareOrder {
    return _compareSelectable;
  }

  int _compareSelectable(Selectable a, Selectable b) {
    if (identical(a, b)) {
      return 0;
    }

    final Rect? rectA = _getVisualRect(a);
    final Rect? rectB = _getVisualRect(b);

    if (rectA == null && rectB == null) {
      return 0;
    }

    if (rectA == null) {
      return 1;
    }

    if (rectB == null) {
      return -1;
    }

    return _compareRects(rectA, rectB);
  }

  Rect? _getVisualRect(Selectable selectable) {
    final List<Rect> boxes = selectable.boundingBoxes;

    if (boxes.isEmpty) {
      return null;
    }

    final Matrix4 transform = selectable.getTransformTo(null);

    Rect? first;

    for (final Rect localRect in boxes) {
      final Rect globalRect = MatrixUtils.transformRect(transform, localRect);

      if (!globalRect.isFinite || globalRect.isEmpty) {
        continue;
      }

      if (first == null) {
        first = globalRect;
        continue;
      }

      //
      // Lấy box xuất hiện sớm nhất theo visual flow.
      //
      if (globalRect.top < first.top - 1) {
        first = globalRect;
        continue;
      }

      //
      // Cùng dòng -> lấy box bên trái hơn.
      //
      if ((globalRect.top - first.top).abs() <= 1 && globalRect.left < first.left) {
        first = globalRect;
      }
    }

    return first;
  }

  int _compareRects(Rect a, Rect b) {
    //
    // Kiểm tra xem có nằm cùng một line không.
    //
    final double overlap = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);

    if (overlap > 0) {
      //
      // cùng dòng:
      // left -> right
      //
      final int horizontal = a.left.compareTo(b.left);

      if (horizontal != 0) {
        return horizontal;
      }

      return a.top.compareTo(b.top);
    }

    //
    // khác dòng:
    // top -> bottom
    //
    return a.top.compareTo(b.top);
  }
}
