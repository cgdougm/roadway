import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:provider/provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'app_state.dart';
import 'db_helper.dart';

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
  String? _droppedFilePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: DropTarget(
        onDragDone: (detail) {
          setState(() {
            _droppedFilePath = detail.files.first.path;
          });
          _showDroppedFilesDialog(context, detail.files);
        },
        child: Center(
          child: _droppedFilePath == null
              ? DottedBorder(
                  color: Colors.grey,
                  strokeWidth: 5,
                  dashPattern: [10, 5],
                  child: const Text('Drop a file'),
                  borderPadding: EdgeInsets.all(-10),
                )
              : Text('Dropped:   $_droppedFilePath'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkDatabase,
        tooltip: 'Check Database',
        child: const Icon(Icons.square_outlined),
      ),
    );
  }

  void _showDroppedFilesDialog(BuildContext context, List<XFile> files) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Dropped Files?'),
          content: Text('Do you want to add ${files.length} dropped file(s)?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                Provider.of<AppState>(context, listen: false)
                    .handleDroppedFiles(files);
                print("Adding ${files.length} files");
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
}
