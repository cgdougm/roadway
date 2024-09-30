import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'app_state.dart';
import 'db_helper.dart';
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ingest Dropped File'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _dragging = false;
  List<String> _droppedFilePaths = [];
  String? _message;

  String _generateId(String filePath) {
    final bytes = utf8.encode(filePath);
    return sha256.convert(bytes).toString();
  }

  Future<void> _handleFileDrop(List<String> filePaths) async {
    List<String> newFiles = [];
    List<String> existingFiles = [];

    for (String filePath in filePaths) {
      final id = _generateId(filePath);
      final exists = await DatabaseHelper.instance.itemExists(id);

      if (exists) {
        existingFiles.add(filePath);
      } else {
        newFiles.add(filePath);
      }
    }

    setState(() {
      _droppedFilePaths = filePaths;
    });

    if (newFiles.isNotEmpty || existingFiles.isNotEmpty) {
      _showDroppedFilesDialog(newFiles, existingFiles);
    }
  }

  void _showDroppedFilesDialog(List<String> newFiles, List<String> existingFiles) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(newFiles.isEmpty ? 'Files Already Exist' : 'Confirm File Addition'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (newFiles.isNotEmpty) ...[
                  Text('New files to be added:'),
                  ...newFiles.map((file) => Text('- ${path.basename(file)}')),
                  SizedBox(height: 10),
                ],
                if (existingFiles.isNotEmpty) ...[
                  Text('Files already in database ${newFiles.isEmpty ? '(no action needed)' : '(will be skipped)'}:'),
                  ...existingFiles.map((file) => Text('- ${path.basename(file)}')),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            if (newFiles.isNotEmpty) ...[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _droppedFilePaths = [];
                    _message = 'Operation cancelled. No files were added.';
                  });
                },
              ),
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _commitNewFiles(newFiles);
                },
              ),
            ] else 
              TextButton(
                child: Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _droppedFilePaths = [];
                    _message = 'All files already exist in the database. No changes made.';
                  });
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _commitNewFiles(List<String> newFiles) async {
    for (String filePath in newFiles) {
      final id = _generateId(filePath);
      await DatabaseHelper.instance.insertItemIfNotExists(
        id,
        'file',
        filePath,
        parent: path.dirname(filePath),
      );
    }
    setState(() {
      _message = '${newFiles.length} new file(s) added to database successfully.';
    });
  }

  void _checkDatabase() async {
    await DatabaseHelper.instance.printAllItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: DropTarget(
        onDragDone: (detail) {
          _handleFileDrop(detail.files.map((xFile) => xFile.path).toList());
        },
        onDragEntered: (detail) {
          setState(() {
            _dragging = true;
          });
        },
        onDragExited: (detail) {
          setState(() {
            _dragging = false;
          });
        },
        child: Center(
          child: DottedBorder(
            borderType: BorderType.RRect,
            radius: Radius.circular(12),
            padding: EdgeInsets.all(6),
            color: _dragging ? Colors.blue : Colors.black,
            strokeWidth: 2,
            dashPattern: [8, 4],
            child: Container(
              height: 200,
              width: 300,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.cloud_upload,
                    size: 40,
                    color: _dragging ? Colors.blue : Colors.black,
                  ),
                  Text(
                    _droppedFilePaths.isEmpty
                        ? 'Drop files here'
                        : '${_droppedFilePaths.length} file(s) dropped',
                    style: TextStyle(fontSize: 18),
                  ),
                  if (_message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(_message!, style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkDatabase,
        tooltip: 'DB console dump',
        child: Icon(Icons.list),
      ),
    );
  }
}
