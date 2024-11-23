import 'package:flutter/material.dart';

class LayoutDimensions extends InheritedWidget {
  final double contentWidth;
  final double contentHeight;
  final double rowInsetWidth;

  const LayoutDimensions({
    super.key,
    required super.child,
    required this.contentWidth,
    required this.contentHeight,
    required this.rowInsetWidth,
  });

  static LayoutDimensions of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LayoutDimensions>()!;
  }

  @override
  bool updateShouldNotify(LayoutDimensions oldWidget) {
    return contentWidth != oldWidget.contentWidth ||
        contentHeight != oldWidget.contentHeight ||
        rowInsetWidth != oldWidget.rowInsetWidth;
  }
}
