
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:pasteboard/pasteboard.dart';
import 'package:roadway/core/db.dart';
import 'package:roadway/core/text.dart';
import 'package:roadway/component/snack.dart';


// Future<void> _checkClipboard() async {
//   final clipboardContent = await Pasteboard.text; // TODO: replace with super_clipboard
//   setState(() {
//     print('clipboardHasContent = ${clipboardContent != null && clipboardContent.isNotEmpty}');
//   });
// }

Future<void> handleClipboardContent(BuildContext context) async {
  final clipboardContent = await Pasteboard.text;
  if (clipboardContent == null || clipboardContent.isEmpty) return;

  final List<String> urls = [];
  final List<String> filePaths = [];

  final lines = clipboardContent.split('\n');
  for (final line in lines) {
    // skip empty lines
    if (line.trim().isEmpty) continue;
    // remove leading/trailing quotes
    final trimmedLine = removeEnclosingQuotes(line.trim());
    // check for urls
    if (trimmedLine.startsWith('http://') || trimmedLine.startsWith('https://')) {
      // plain bare URL
      urls.add(trimmedLine);
    } else {
      // check for markdown-formatted urls, eg. [title](url)
      final mdMatch =
          RegExp(r'(?:[*-]\s)?\[(?<title>.*)\]\((?<url>https?:\/\/[^\s]+)\)')
              .firstMatch(trimmedLine); // TODO: handle title
      if (mdMatch != null) {
        urls.add(mdMatch.namedGroup('url')!);
      } else {
        // check for file paths
        if (await File(trimmedLine).exists()) {
          filePaths.add(trimmedLine);
        }
      }
    }
  }

  if (urls.isEmpty && filePaths.isEmpty) {
    showSnackBar('No valid URLs or file paths found in clipboard.', context);
    return;
  }

  showClipboardContentDialog(urls, filePaths, context);
}

void showClipboardContentDialog(List<String> urls, List<String> filePaths, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Content Addition'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              if (urls.isNotEmpty) ...[
                const Text('URLs to be added:'),
                ...urls.map((url) => Text('- $url')),
                const SizedBox(height: 10),
              ],
              if (filePaths.isNotEmpty) ...[
                const Text('File paths to be added:'),
                ...filePaths.map((file) => Text('- ${path.basename(file)}')),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
              showSnackBar('Operation cancelled. No content was added.', context);
            },
          ),
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
              commitClipboardContent(urls, filePaths, context);
            },
          ),
        ],
      );
    },
  );
}

Future<void> commitClipboardContent(
    List<String> urls, List<String> filePaths, BuildContext context) async {
  int addedCount = 0;

  for (String url in urls) {
    final id = generateId(url);
    final exists = await DatabaseHelper.instance.itemExists(id);
    if (!exists) {
      await DatabaseHelper.instance.insertItemIfNotExists(id, 'url', url);
      addedCount++;
    }
  }

  for (String filePath in filePaths) {
    // XFile xFile = XFile(filePath);
    final id = generateId(filePath);
    final exists = await DatabaseHelper.instance.itemExists(id);
    if (!exists) {
      await DatabaseHelper.instance.insertItemIfNotExists(
        id,
        'file', //xFile.isFolder() ? 'folder' : 'file',
        filePath,
        parent: path.dirname(filePath),
      );
      addedCount++;
    }
  }

  String snackMessage = addedCount > 0
      ? '$addedCount new item(s) added to database successfully.'
      : 'URL(s) or file(s) already in DB, no new items added.';
  showSnackBar(snackMessage, context);
  // _checkClipboard();
}

