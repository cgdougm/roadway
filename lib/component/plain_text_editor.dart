import 'package:flutter/material.dart';

Widget buildTextEditor(
    String title, TextEditingController textEditingController) {
  return Builder(
    builder: (BuildContext context) {
      double navRailWidth = 100;
      // Get the width of the content area by using media query less the width of the navigation rail.
      double contentWidth = MediaQuery.of(context).size.width - navRailWidth;
      double contentHeight = MediaQuery.of(context).size.height - 51;

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
              width: contentWidth,
              height: contentHeight,
              padding: const EdgeInsets.all(6),
              child: TextField(
                controller: textEditingController,
                minLines: null,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 16, fontFamily: 'Courier'),
                decoration: InputDecoration(
                  hintText: '...plain text...',
                  hintStyle: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: colorScheme.inversePrimary),
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
