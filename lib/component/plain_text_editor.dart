import 'package:flutter/material.dart';

  Widget buildTextEditor(String title, TextEditingController textEditingController) {
    return Builder(
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;

        return Column(
          children: [
            Container(
              color: colorScheme.tertiary,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              child: Text(
                title,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: colorScheme.onTertiary,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(30),
                child: TextField(
                  controller: textEditingController,
                  expands: true,
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
            ),
          ],
        );
      },
    );
  }
