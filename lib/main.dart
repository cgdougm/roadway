import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Ingest Dropped File'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
        await DatabaseHelper.instance.insertItemIfNotExists(
          id,
          'file',
          filePath,
          parent: path.dirname(filePath),
        );
      }
    }

    setState(() {
      _droppedFilePaths = filePaths;
      if (existingFiles.isNotEmpty) {
        _message = '${existingFiles.length} file(s) already exist and will be skipped.';
      } else {
        _message = 'All files added to database successfully.';
      }
    });

    _showDroppedFilesDialog(newFiles, existingFiles);
  }

  void _showDroppedFilesDialog(List<String> newFiles, List<String> existingFiles) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Dropped Files'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (newFiles.isNotEmpty) ...[
                  Text('New files added:'),
                  ...newFiles.map((file) => Text('- ${path.basename(file)}')),
                  SizedBox(height: 10),
                ],
                if (existingFiles.isNotEmpty) ...[
                  Text('Files already in database (skipped):'),
                  ...existingFiles.map((file) => Text('- ${path.basename(file)}')),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                    size: 80,
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
        tooltip: 'Check Database',
        child: Icon(Icons.question_answer),
      ),
    );
  }
}
