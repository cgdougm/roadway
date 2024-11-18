import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/core/db.dart';
import 'dart:io';
import 'package:roadway/core/theme.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:mime/mime.dart';
import 'package:roadway/app_actions.dart';
import 'package:roadway/component/md.dart';
import 'package:roadway/component/filebrowser.dart';
import 'package:roadway/component/snack.dart';
import 'package:roadway/drop.dart';

// toggle diagnostic view
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database; // warm up DB, cache

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => ThemeProvider(isDarkMode: true)),
      ],
      child: const MyApp(),
    ),
  );

  doWhenWindowReady(() {
  // BitsDojo Window Settings
    const initialSize = Size(1280, 720);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Roadway',
          theme: themeProvider.themeData,
          home: const MyHomePage(title: 'roadway'),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  bool isDragging = false;
  late TabController tabController;
  late TextEditingController _textEditingController;
  late TextEditingController _markdownController;

  @override
  void initState() {
    super.initState();
    // _checkClipboard();
    tabController = TabController(length: 4, vsync: this);
    _textEditingController = TextEditingController();
    _markdownController = TextEditingController();
  }

  @override
  void dispose() {
    tabController.dispose();
    _textEditingController.dispose();
    _markdownController.dispose();
    super.dispose();
  }


  Future<void> handleDataCellTap(Map<String, dynamic> item) async {
    if (item['type'] == 'file') {
      final mimeType = lookupMimeType(item['value']);
      if (mimeType?.startsWith('image/') == true) {
        showImageInSecondTab(item['value']);
      } else if (mimeType?.startsWith('text/') == true) {
        String content = await File(item['value'])
            .readAsString(); // WILLFAIL: file moved/renamed/deleted
        showTextInSecondTab(content, item['value']);
      }
    } else if (item['type'] == 'url') {
      _launchUrl(item['value']);
    } else if (item['type'] == 'folder') {
      // TODO: Implement folder view
      showFileBrowserInSecondTab();
    }
    tabController.animateTo(2); // Switch to the second tab
  }

  void showImageInSecondTab(String imagePath) {
    setState(() {
      secondTabContent = Image.file(File(imagePath));
    });
  }

  Future<void> showFutureTextInSecondTab(
      Future<String> futureText, String title) async {
    String content = await futureText;
    showTextInSecondTab(content, title);
  }

  void showFileContentsInSecondTab(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    showTextInSecondTab(content, filePath);
  }

  void showFileBrowserInSecondTab() {
    setState(() {
      secondTabContent = const FileBrowser();
    });
  }

  void showTextInSecondTab(String content, [String title = 'untitled']) {
    _markdownController.text = content;
    setState(() {
      secondTabContent = MarkdownEditorWidget(
        title: title,
        controller: _markdownController,
      );
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await url_launcher.launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      showSnackBar('Error launching $url: $e', context);
    }
  }

  Widget buildMarkdownEditor(String title, String text) {
    return Builder(builder: (BuildContext context) {
      return MarkdownEditorWidget(
          controller: _markdownController, title: title);
    });
  }


  Widget? secondTabContent;


  @override
  Widget build(BuildContext context) {
    // final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.title,
            style: const TextStyle(
                fontFamily: 'HeptaSlab',
                fontWeight: FontWeight.bold,
                fontSize: 30,
                letterSpacing: -2)),
        actions: appBarActions,
      ),
      drawer: const Drawer(
        width: 600,
        shadowColor: Colors.black,
        elevation: 10,
        child: FileBrowser(),
      ),
      body: DropTarget(
        onDragDone: (detail) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          handleFileDrop(detail.files.map((xFile) => xFile.path).toList(), context);
        },
        onDragEntered: (detail) {
          setState(() {
            isDragging = true;
          });
          showDraggingSnackBar(context);
        },
        onDragExited: (detail) {
          setState(() {
            isDragging = false;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        child: Container(
          color: isDragging ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          child: const Center(
            child: Text("Hello.",
                style: TextStyle(
                  fontFamily: 'HeptaSlab',
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                  letterSpacing: -2)))),
      ),
    );
  }
}
