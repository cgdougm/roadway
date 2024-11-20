import 'package:flutter/material.dart';

Widget buildTextEditor(
    String title, TextEditingController textEditingController) {
  return Builder(
    builder: (BuildContext context) {
      final colorScheme = Theme.of(context).colorScheme;

      return Column(
        children: [
          SizedBox(
            height: 20,
            child: Container(
              color: Colors.blue, // colorScheme.tertiary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.yellow// colorScheme.onTertiary,
                ),
              ),
            ),
          ),
            Container(
              padding: const EdgeInsets.all(30),
              child: TextField(
                controller: textEditingController,
                minLines: null,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 16, fontFamily: 'Courier'),
                decoration: InputDecoration(
                  hintText: 'Text content',
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
