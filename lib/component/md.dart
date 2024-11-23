import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:roadway/core/text.dart';
import 'package:roadway/controller/text_file_controller.dart';
import 'package:roadway/icon/markdown.dart';
import 'package:roadway/layout/dimensions.dart';

/// A widget that has a plain text field on the left, and
/// a markdown widget on the right.
/// There is a bar at the top that has on the right side three
/// grouped buttons, for "text, both and rendered"
/// The bar displays the filePath value on the textFileController
/// (an extended textEditingController)

class MarkdownEditorWidget extends StatefulWidget {
  final TextFileController controller;

  const MarkdownEditorWidget({
    super.key,
    required this.controller,
  });

  @override
  MarkdownEditorWidgetState createState() => MarkdownEditorWidgetState();
}

class MarkdownEditorWidgetState extends State<MarkdownEditorWidget> {
  ViewMode _viewMode = ViewMode.both;
  bool plainMode = false;

  void setPlainMode(bool plainMode) {
    this.plainMode = plainMode;
    _viewMode = plainMode ? ViewMode.text : ViewMode.both;
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = LayoutDimensions.of(context);
    // TODO: use a color scheme
    // final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: dimensions.contentWidth,
        height: dimensions.contentHeight - 16,
        child: Column(
          children: [
            _buildCustomTopBar(),
            Expanded(
              child: _buildEditorContent(),
            ),
          ],
        ),
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
              leftElipses(widget.controller.filePath ?? 'untitled', 30),
              style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          if (!plainMode)
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
