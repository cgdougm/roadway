import 'package:flutter/material.dart';

/// An InheritedWidget that provides the dimensions of the content area.
/// This is used to layout the components in the app.
///
/// Example usage:
///    builder: (BuildContext context) {
///      final dimensions = LayoutDimensions.of(context);
///      final colorScheme = Theme.of(context).colorScheme;
///      return Column(
///        children: [
///          Container(
///            width: dimensions.contentWidth,
///            height: dimensions.contentHeight,
///          ),
///        ],
///      );
///    }

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
