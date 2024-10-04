import 'package:flutter/material.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'db_helper.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:pasteboard/pasteboard.dart';
import 'theme_provider.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:mime/mime.dart';
import 'theme_colors.dart';
import 'data_table_component.dart';
import 'text_util.dart';

const bool isDev = false;
// toggle diagnostic view
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AppState()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
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
  bool _dragging = false;
  bool _clipboardHasContent = false;
  late TabController _tabController;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    final clipboardContent = await Pasteboard.text;
    setState(() {
      _clipboardHasContent =
          clipboardContent != null && clipboardContent.isNotEmpty;
    });
  }

  void _showSnackBar(String message) {
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
                  Text('New files to be added:'),
                  ...newFiles.map((file) => Text('- ${path.basename(file)}')),
                  SizedBox(height: 10),
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
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSnackBar('Operation cancelled. No files were added.');
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
                  _showSnackBar(
                      'All files already exist in the database. No changes made.');
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _commitNewFiles(List<String> newFiles) async {
    for (String filePath in newFiles) {
      final id = generateId(filePath);
      await DatabaseHelper.instance.insertItemIfNotExists(
        id,
        'file',
        filePath,
        parent: path.dirname(filePath),
      );
    }
    _showSnackBar(
        '${newFiles.length} new file(s) added to database successfully.');
  }

  void _checkDatabase() async {
    await DatabaseHelper.instance.printAllItems();
  }

  Future<void> _handleClipboardContent() async {
    final clipboardContent = await Pasteboard.text;
    if (clipboardContent == null || clipboardContent.isEmpty) return;

    final List<String> urls = [];
    final List<String> filePaths = [];

    final lines = clipboardContent.split('\n');
    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      if (line.startsWith('http://') || line.startsWith('https://')) {
        urls.add(line.trim());
      } else {
        final mdMatch =
            RegExp(r'(?:[*-]\s)?\[(?<title>.*)\]\((?<url>https?:\/\/[^\s]+)\)')
                .firstMatch(line);
        if (mdMatch != null) {
          urls.add(mdMatch.namedGroup('url')!);
        } else if (await File(line.trim()).exists()) {
          filePaths.add(line.trim());
        }
      }
    }

    if (urls.isEmpty && filePaths.isEmpty) {
      _showSnackBar('No valid URLs or file paths found in clipboard.');
      return;
    }

    _showClipboardContentDialog(urls, filePaths);
  }

  void _showClipboardContentDialog(List<String> urls, List<String> filePaths) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Content Addition'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                if (urls.isNotEmpty) ...[
                  Text('URLs to be added:'),
                  ...urls.map((url) => Text('- $url')),
                  SizedBox(height: 10),
                ],
                if (filePaths.isNotEmpty) ...[
                  Text('File paths to be added:'),
                  ...filePaths.map((file) => Text('- ${path.basename(file)}')),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                _showSnackBar('Operation cancelled. No content was added.');
              },
            ),
            TextButton(
              child: Text('OK'),
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
      final id = generateId(filePath);
      final exists = await DatabaseHelper.instance.itemExists(id);
      if (!exists) {
        await DatabaseHelper.instance.insertItemIfNotExists(
          id,
          'file',
          filePath,
          parent: path.dirname(filePath),
        );
        addedCount++;
      }
    }

    String snackMessage = addedCount > 0
        ? '$addedCount new item(s) added to database successfully.'
        : 'URL(s) or file(s) already in DB, no new items added.';
    _showSnackBar(snackMessage);
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

  void _handleDataCellTap(Map<String, dynamic> item) {
    if (item['type'] == 'file') {
      final mimeType = lookupMimeType(item['value']);
      if (mimeType?.startsWith('image/') == true) {
        _showImageInSecondTab(item['value']);
      } else if (mimeType?.startsWith('text/') == true) {
        _showTextInSecondTab(item['value']);
      }
    } else if (item['type'] == 'url') {
      _launchUrl(item['value']);
    }
    _tabController.animateTo(1); // Switch to the second tab
  }

  void _showImageInSecondTab(String imagePath) {
    setState(() {
      _secondTabContent = Image.file(File(imagePath));
    });
  }

  void _showTextInSecondTab(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    _textEditingController = TextEditingController(text: content);
    setState(() {
      _secondTabContent = _buildTextEditor(filePath);
    });
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await url_launcher.launchUrl(url)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      _showSnackBar('Error launching $url: $e');
    }
  }

  Widget _buildTextEditor(String filePath) {
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
                filePath,
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
            isDev
                ? Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(30),
                      child: ThemeColorPalette(),
                    ),
                  )
                : Container(),
          ],
        );
      },
    );
  }

  Widget? _secondTabContent;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // Add the Data menu
          PopupMenuButton<String>(
            tooltip: 'Settings',
            icon: Icon(Icons.settings),
            onSelected: (String result) {
              if (result == 'dump') {
                _checkDatabase();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'dump',
                child: Text('Dump to console'),
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
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.table_chart)),
            Tab(icon: Icon(Icons.edit)),
          ],
        ),
      ),
      body: DropTarget(
        onDragDone: (detail) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          _handleFileDrop(detail.files.map((xFile) => xFile.path).toList());
        },
        onDragEntered: (detail) {
          setState(() {
            _dragging = true;
          });
          _showDraggingSnackBar();
        },
        onDragExited: (detail) {
          setState(() {
            _dragging = false;
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
        child: Container(
          color: _dragging ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          child: TabBarView(
            controller: _tabController,
            children: [
              DataTableComponent(onDataCellTap: _handleDataCellTap),
              _secondTabContent ??
                  const Center(child: Text("Select an item to view")),
            ],
          ),
        ),
      ),
    );
  }
}