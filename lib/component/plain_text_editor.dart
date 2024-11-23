import 'package:flutter/material.dart';
import 'package:roadway/component/layout_dimensions.dart';

Widget buildTextEditor(
    String title, TextEditingController textEditingController) {
  return Builder(
    builder: (BuildContext context) {
      final dimensions = LayoutDimensions.of(context);
      final colorScheme = Theme.of(context).colorScheme;

      return Column(
        children: [
          SizedBox(
            height: 20,
            width: double.infinity,
            child: Container(
              color: colorScheme.secondaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Container(
            width: dimensions.contentWidth,
            height: dimensions.contentHeight - 51,
            padding: const EdgeInsets.all(6),
            child: TextField(
              controller: textEditingController,
              minLines: null,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 16, fontFamily: 'Courier'),
              decoration: InputDecoration(
                hintText: '...plain text...',
                hintStyle: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.inversePrimary),
                fillColor: colorScheme.surface,
                filled: true,
              ),
            ),
          ),
        ],
      );
    },
  );
}
