import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'text_util.dart';

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
          SvgPicture.asset(
            'assets/icons/markdown_icon.svg',
            width: 32,
            height: 32,
            colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurface, BlendMode.srcIn),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              leftElipses(widget.title, 30),
              style: const TextStyle(fontFamily: 'Courier', fontSize: 16),
            ),
          ),
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.more_vert),
          //   onSelected: _handleMenuSelection,
          //   itemBuilder: (BuildContext context) => [
          //     const PopupMenuItem<String>(
          //       value: 'bold',
          //       child: Text('Bold'),
          //     ),
          //     const PopupMenuItem<String>(
          //       value: 'italic',
          //       child: Text('Italic'),
          //     ),
          //     const PopupMenuItem<String>(
          //       value: 'link',
          //       child: Text('Insert Link'),
          //     ),
          //     // Add more markdown-specific menu items as needed
          //   ],
          // ),
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

  // void _handleMenuSelection(String value) {
  //   switch (value) {
  //     case 'bold':
  //       _insertMarkdown('**', '**');
  //       break;
  //     case 'italic':
  //       _insertMarkdown('*', '*');
  //       break;
  //     case 'link':
  //       _insertMarkdown('[', '](url)');
  //       break;
  //     // Add more cases for additional markdown formatting options
  //   }
  // }

  // void _insertMarkdown(String prefix, String suffix) {
  //   final TextEditingValue value = widget.controller.value;
  //   final int start = value.selection.start;
  //   final int end = value.selection.end;
  //   final String selectedText = value.text.substring(start, end);
  //   final String newText =
  //       '${value.text.substring(0, start)}$prefix$selectedText$suffix${value.text.substring(end)}';
  //   widget.controller.value = TextEditingValue(
  //     text: newText,
  //     selection: TextSelection.collapsed(
  //         offset: start + prefix.length + selectedText.length + suffix.length),
  //   );
  // }

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
