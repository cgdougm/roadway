import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:roadway/core/text.dart';
import 'package:roadway/icon/markdown.dart';

/// A widget that has a plain text field on the left, and a markdown widget on the right.
/// There is a bar at the top that has on the right side three grouped buttons, for "text, both and rendered"
/// The bar displayes the title argument given, typically  the source file for the markdown.
///

class MarkdownEditorWidget extends StatefulWidget {
  final String title;
  final TextEditingController controller;

  const MarkdownEditorWidget({
    super.key,
    required this.title,
    required this.controller,
  });

  @override
  MarkdownEditorWidgetState createState() => MarkdownEditorWidgetState();
}

class MarkdownEditorWidgetState extends State<MarkdownEditorWidget> {
  ViewMode _viewMode = ViewMode.both;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _buildCustomTopBar(),
          Expanded(
            child: _buildEditorContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          const Icon(MarkdownIcon.markdown),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              leftElipses(widget.title, 30),
              style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          ToggleButtons(
            onPressed: (int index) {
              setState(() {
                _viewMode = ViewMode.values[index];
              });
            },
            isSelected: [
              _viewMode == ViewMode.text,
              _viewMode == ViewMode.both,
              _viewMode == ViewMode.rendered,
            ],
            children: const [
              Icon(Icons.text_fields),
              Icon(Icons.view_agenda),
              Icon(Icons.preview),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditorContent() {
    switch (_viewMode) {
      case ViewMode.text:
        return _buildTextField();
      case ViewMode.both:
        return Row(
          children: [
            Expanded(child: _buildTextField()),
            Expanded(child: _buildMarkdownPreview()),
          ],
        );
      case ViewMode.rendered:
        return _buildMarkdownPreview();
    }
  }

  Widget _buildTextField() {
    return TextField(
      controller: widget.controller,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontFamily: 'Courier'),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(18),
        alignLabelWithHint: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildMarkdownPreview() {
    return Container(
      color: ThemeData.dark().focusColor,
      padding: const EdgeInsets.all(10),
      child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // Adds rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(5, 5), // changes position of shadow
              ),
            ],
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Markdown(data: widget.controller.text)),
    );
  }
}

enum ViewMode { text, both, rendered }
