import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';
import 'package:roadway/app_state.dart';
import 'package:roadway/core/db.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:pasteboard/pasteboard.dart';
import 'package:roadway/core/theme.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:mime/mime.dart';
import 'package:roadway/component/palette.dart';
import 'package:roadway/component/data_table.dart';
import 'package:roadway/core/text.dart';
import 'package:cross_file/cross_file.dart';
import 'package:roadway/core/unique_id.dart';
import 'package:roadway/core/file.dart';
import 'package:roadway/component/md.dart';
import 'package:roadway/component/filebrowser.dart';
import 'package:roadway/component/rename.dart';
import 'package:roadway/component/file_tree.dart';

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
  bool _clipboardHasContent = false;
  late TabController tabController;
  late TextEditingController _textEditingController;
  late TextEditingController _markdownController;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
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

  Future<void> _checkClipboard() async {
    final clipboardContent = await Pasteboard.text;
    setState(() {
      _clipboardHasContent =
          clipboardContent != null && clipboardContent.isNotEmpty;
    });
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleFileDrop(List<String> filePaths) async {
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
      _showDroppedFilesDialog(newFiles, existingFiles);
    }
  }

  void _showDroppedFilesDialog(
      List<String> newFiles, List<String> existingFiles) {
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
                  showSnackBar('Operation cancelled. No files were added.');
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  ingestNewFiles(newFiles);
                },
              ),
            ] else
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                  showSnackBar(
                      'All files already exist in the database. No changes made.');
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> ingestNewFiles(List<String> newFiles) async {
    AppState state = Provider.of<AppState>(context, listen: false);
    List<XFile> xFiles = newFiles.map((path) => XFile(path)).toList();
    state.addFiles(xFiles);
    showSnackBar(
        '${newFiles.length} new file(s) added to database successfully.');
  }

  Future<String> dumpedDbItemsAsString() async {
    final List<Map<String, Object?>> items =
        await context.read<AppState>().getAllItems();
    List<String> dumpLines = [];
    dumpLines.add('# Items');
    for (var item in items) {
      String filePath = item['value'] as String;
      if (FileInfo.isUri(filePath)) {
        dumpLines.add('### $filePath');
      } else {
        FileInfo fileInfo = await FileInfo.fromPath(filePath);
        // Convert FileInfo to a Map and filter out null values
        Map<String, dynamic> mappedFileInfo = fileInfo.toMap()
          ..removeWhere((key, value) =>
              value == null); // Not sure why this filder is needed
        dumpLines.add('### ${mappedFileInfo["fileName"]}');
        dumpLines.add('* ${mappedFileInfo["fileFolder"]}');
        dumpLines.add(
            '* ${mappedFileInfo["mimeType"]} / ${mappedFileInfo["fileLengthFormatted"]}');
        dumpLines.add(
            '* ${mappedFileInfo["lastModifiedFormatted"]} (${mappedFileInfo["lastModifiedAgo"]})');
      }
      dumpLines.add('\n'); // Separator between items
    }
    return dumpLines.join('\n');
  }

  Future<void> _handleClipboardContent() async {
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
      showSnackBar('No valid URLs or file paths found in clipboard.');
      return;
    }

    _showClipboardContentDialog(urls, filePaths);
  }

  void _showClipboardContentDialog(List<String> urls, List<String> filePaths) {
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
                showSnackBar('Operation cancelled. No content was added.');
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                _commitClipboardContent(urls, filePaths);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _commitClipboardContent(
      List<String> urls, List<String> filePaths) async {
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
      XFile xFile = XFile(filePath);
      final id = generateId(filePath);
      final exists = await DatabaseHelper.instance.itemExists(id);
      if (!exists) {
        await DatabaseHelper.instance.insertItemIfNotExists(
          id,
          xFile.isFolder() ? 'folder' : 'file',
          filePath,
          parent: path.dirname(filePath),
        );
        addedCount++;
      }
    }

    String snackMessage = addedCount > 0
        ? '$addedCount new item(s) added to database successfully.'
        : 'URL(s) or file(s) already in DB, no new items added.';
    showSnackBar(snackMessage);
    _checkClipboard();
  }

  void _showDraggingSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Drop file(s) to ingest'),
        duration: Duration(days: 1), // Long duration, we'll dismiss it manually
        backgroundColor: Colors.blue,
      ),
    );
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
      showSnackBar('Error launching $url: $e');
    }
  }

  Widget buildMarkdownEditor(String title, String text) {
    return Builder(builder: (BuildContext context) {
      return MarkdownEditorWidget(
          controller: _markdownController, title: title);
    });
  }

  Widget buildTextEditor(String title) {
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
                  controller: _textEditingController,
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

  Widget? secondTabContent;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.title,
            style: const TextStyle(
                fontFamily: 'HeptaSlab',
                fontWeight: FontWeight.bold,
                fontSize: 30,
                letterSpacing: -2)),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onSelected: (String result) {
              if (result == 'dump') {
                showFutureTextInSecondTab(dumpedDbItemsAsString(), 'DB Dump');
              } else if (result == 'browser') {
                showFileBrowserInSecondTab();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'dump',
                child: Text('Dump to console'),
              ),
              const PopupMenuItem<String>(
                value: 'browser',
                child: Text('File Browser'),
              ),
            ],
          ),
          Tooltip(
            message: 'Ingest from clipboard',
            child: IconButton(
              icon: const Icon(Icons.content_paste),
              onPressed: _clipboardHasContent ? _handleClipboardContent : null,
            ),
          ),
          Tooltip(
            message: 'Toggle theme',
            child: IconButton(
              icon: Icon(themeProvider.isDarkMode
                  ? Icons.wb_sunny
                  : Icons.nightlight_round),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),
        ],
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tooltip(
              message: 'File tree',
              child: Tab(icon: Icon(Icons.folder_open))),
            Tooltip(
              message: 'Table of items',
              child: Tab(icon: Icon(Icons.table_chart))),
            Tooltip(message: 'Item editor', 
              child: Tab(icon: Icon(Icons.edit))),
            Tooltip(message: 'Theme', 
              child: Tab(icon: Icon(Icons.palette))),
          ],
        ),
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
          _handleFileDrop(detail.files.map((xFile) => xFile.path).toList());
        },
        onDragEntered: (detail) {
          setState(() {
            isDragging = true;
          });
          _showDraggingSnackBar();
        },
        onDragExited: (detail) {
          setState(() {
            isDragging = false;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        child: Container(
          color: isDragging ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          child: TabBarView(
            controller: tabController,
            children: [
              FileTree(),
              DataTableComponent(onDataCellTap: handleDataCellTap),
              secondTabContent ??
                  const Center(child: Text("Select an item to view")),
              ThemeColorPalette(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (() =>
            showRenameDialog(context, "C:\\Users\\micro\\Documents\\test.txt")),
        tooltip: 'Rename files',
        child: const Icon(Icons.add),
      ),
    );
  }
}
