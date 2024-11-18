import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'package:roadway/core/db.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/component/snack.dart';
import 'package:roadway/core/text.dart';

Future<void> handleFileDrop(List<String> filePaths, BuildContext context) async {
  List<String> newFiles = [];
  List<String> existingFiles = [];

  for (String filePath in filePaths) {
    final id = generateId(filePath);
    final exists = await DatabaseHelper.instance.itemExists(id);

    if (exists) {
      existingFiles.add(filePath);
    } else {
      newFiles.add(filePath);
    }
  }

  if (newFiles.isNotEmpty || existingFiles.isNotEmpty) {
    showDroppedFilesDialog(newFiles, existingFiles, context);
  }
}

void showDroppedFilesDialog(
    List<String> newFiles, List<String> existingFiles, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(newFiles.isEmpty
            ? 'Files Already Exist'
            : 'Confirm File Addition'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              if (newFiles.isNotEmpty) ...[
                const Text('New files to be added:'),
                ...newFiles.map((file) => Text('- ${path.basename(file)}')),
                const SizedBox(height: 10),
              ],
              if (existingFiles.isNotEmpty) ...[
                Text(
                    'Files already in database ${newFiles.isEmpty ? '(no action needed)' : '(will be skipped)'}:'),
                ...existingFiles
                    .map((file) => Text('- ${path.basename(file)}')),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          if (newFiles.isNotEmpty) ...[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                showSnackBar('Operation cancelled. No files were added.', context);
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                ingestNewFiles(newFiles, context);
              },
            ),
          ] else
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
                showSnackBar(
                    'All files already exist in the database. No changes made.', context);
              },
            ),
        ],
      );
    },
  );
}

Future<void> ingestNewFiles(List<String> newFiles, BuildContext context) async {
  AppState state = Provider.of<AppState>(context, listen: false);
  List<XFile> xFiles = newFiles.map((path) => XFile(path)).toList();
  state.addFiles(xFiles);
  showSnackBar(
      '${newFiles.length} new file(s) added to database successfully.', context);
}


void showDraggingSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Drop file(s) to ingest'),
      duration: Duration(days: 1), // Long duration, we'll dismiss it manually
      backgroundColor: Colors.blue,
    ),
  );
}

