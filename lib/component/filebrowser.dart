import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path_module;
import 'package:roadway/layout/dimensions.dart';
import 'package:roadway/core/mime.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_markdown/flutter_markdown.dart';

enum DirectoryAccessibilityType {
  accessible,
  notExists,
  statError,
  virtual,
}

extension DirectoryExtension on Directory {
  DirectoryAccessibilityType get accessibilityType {
    // First check if the directory exists
    if (!existsSync()) {
      return DirectoryAccessibilityType.notExists;
    }

    if (isVirtualFolder) {
      return DirectoryAccessibilityType.virtual;
    }

    try {
      statSync();
      return DirectoryAccessibilityType.accessible;
    } on FileSystemException catch (e) {
      debugPrint('Directory access error: $path - ${e.message}');
      return DirectoryAccessibilityType.statError;
    }
  }

  Future<Directory> getHomeDirectory() async {
    if (Platform.isWindows) {
      // On Windows, USERPROFILE environment variable contains the home directory
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return Directory(userProfile);
      }
    } else {
      // On Unix-like systems (Linux, macOS), HOME environment variable contains the home directory
      final home = Platform.environment['HOME'];
      if (home != null) {
        return Directory(home);
      }
    }

    throw Exception('Home directory not found');
  }

  bool get isVirtualFolder {
    // Common Windows virtual folder names
    const virtualFolders = {
      'My Documents',
      'My Music',
      'My Pictures',
      'My Videos',
      'Desktop',
      'Downloads',
      'Documents',
      'Music',
      'Pictures',
      'Videos'
    };

    return Platform.isWindows &&
        virtualFolders.contains(path_module.basename(path));
  }

  Future<Directory> resolveVirtualPath() async {
    if (!Platform.isWindows) return this;
    // Get the user's home directory
    final homeDir = await getHomeDirectory();
    try {
      // Use Windows known folder redirection
      switch (path_module.basename(path)) {
        case 'My Documents':
        case 'Documents':
          final dir = await getApplicationDocumentsDirectory();
          return Directory(dir.path);
        case 'My Music':
          return Directory('${homeDir.path}\\Music');
        case 'My Pictures':
          return Directory('${homeDir.path}\\Pictures');
        case 'My Videos':
          return Directory('${homeDir.path}\\Videos');
        default:
          return this;
      }
    } catch (e) {
      debugPrint('Error resolving virtual path: $path - $e');
      return this;
    }
  }
}

class FileBrowser extends StatefulWidget {
  final Function(File)? onFileView;

  const FileBrowser({super.key, this.onFileView});

  @override
  FileBrowserState createState() => FileBrowserState();
}

class FileBrowserState extends State<FileBrowser> {
  Directory? currentDirectory;
  List<FileSystemEntity> contents = [];
  Widget? filePreviewWidget;
  final ScrollController _fileListController = ScrollController();
  final ScrollController _dirListController = ScrollController();
  Map<String, Map<String, dynamic>> fileMetadata = {};

  Future<void> _openFile(String filePath) async {
    final uri = Uri.file(filePath);
    if (!await url_launcher.launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open $filePath')),
        );
      }
    }
  }

  Future<void> _openInExplorer(String filePath) async {
    if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,', filePath]);
    }
  }

  Widget _buildMetadataTable(String filePath) {
    final file = File(filePath);
    final stat = file.statSync();
    final metadata = {
      'Name': path_module.basename(filePath),
      'Size': '${(stat.size / 1024).toStringAsFixed(2)} KB',
      'Modified': stat.modified.toString(),
      'Created': stat.changed.toString(),
      'Type': lookupMimeType(filePath) ?? 'Unknown',
    };

    return Table(
      border: TableBorder.all(),
      children: metadata.entries
          .map((entry) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(entry.value),
                  ),
                ],
              ))
          .toList(),
    );
  }

  String _tryReadTextFile(String filePath) {
    try {
      return File(filePath).readAsStringSync(encoding: utf8);
    } catch (e) {
      try {
        // Try Latin-1 encoding if UTF-8 fails
        return File(filePath).readAsStringSync(encoding: latin1);
      } catch (e) {
        return '[Unable to read file content: encoding error]';
      }
    }
  }

  Widget _buildContentPreview(String filePath, {bool fullWidth = false}) {
    final mimeType = lookupMimeType(filePath);
    final dimensions = LayoutDimensions.of(context);
    final width =
        fullWidth ? dimensions.contentWidth : dimensions.contentWidth / 2;

    if (mimeType?.startsWith('image/') ?? false) {
      try {
        return Image.file(
          File(filePath),
          fit: BoxFit.contain,
          width: width,
          errorBuilder: (context, error, stackTrace) {
            return const Center(child: Text('Unable to load image'));
          },
        );
      } catch (e) {
        return const Center(child: Text('Unable to load image'));
      }
    } else if (mimeType == 'text/markdown') {
      final content = _tryReadTextFile(filePath);
      return SizedBox(
        width: width,
        child: Markdown(
          data: content,
        ),
      );
    } else if (mimeType?.startsWith('text/') ?? false) {
      final content = _tryReadTextFile(filePath);
      return SizedBox(
        width: width,
        child: TextField(
          maxLines: null,
          controller: TextEditingController(text: content),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildCurrentDirectoryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final filesInCurrentDirectory = contents.whereType<File>().toList();
    final directoriesInCurrentDirectory =
        contents.whereType<Directory>().toList();

    return Card(
      color: colorScheme.primaryContainer,
      child: ListTile(
        title: Text(path_module.basename(currentDirectory!.path),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: colorScheme.secondary)),
        subtitle: RichText(
          text: TextSpan(
              style: TextStyle(color: colorScheme.tertiary),
              children: [
                TextSpan(
                    text: '${path_module.dirname(currentDirectory!.path)}\n',
                    style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.w700,
                        color: colorScheme.tertiary)),
                if (filesInCurrentDirectory.isNotEmpty)
                  TextSpan(
                      text: '${filesInCurrentDirectory.length} files',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.tertiary)),
                if (filesInCurrentDirectory.isNotEmpty &&
                    directoriesInCurrentDirectory.isNotEmpty)
                  const TextSpan(text: ', '),
                if (directoriesInCurrentDirectory.isNotEmpty)
                  TextSpan(
                      text:
                          '${directoriesInCurrentDirectory.length} director${directoriesInCurrentDirectory.length > 1 ? 'ies' : 'y'}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.tertiary)),
              ]),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_upward, color: colorScheme.tertiary),
          onPressed: () {
            if (currentDirectory!.parent.path != currentDirectory!.path) {
              _navigateToDirectory(currentDirectory!.parent);
            } else {
              // TODO: Implement disk selection for Windows
            }
          },
        ),
      ),
    );
  }

  Widget _buildDirectoryPreview(Directory dir) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: Metadata
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            child: _buildMetadataTable(dir.path),
          ),
        ),
        // Right column: File listing
        Expanded(
          flex: 1,
          child: FutureBuilder<List<FileSystemEntity>>(
            future: Future(() => dir.listSync()),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Empty folder'));
              }

              final items = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isDirectory = item is Directory;
                  final name = path_module.basename(item.path);

                  return ListTile(
                    leading: Icon(
                      isDirectory
                          ? Icons.folder
                          : getIconForFilePath(item.path).icon,
                      size: 16,
                    ),
                    title: Text(name,
                        style: const TextStyle(
                            fontSize: 12, fontFamily: 'Courier')),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubdirectoryList() {
    final subdirectories = contents.whereType<Directory>().toList();
    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          _dirListController
              .jumpTo(_dirListController.offset + pointerSignal.scrollDelta.dy);
        }
      },
      child: ListView.builder(
        controller: _dirListController,
        shrinkWrap: true,
        itemCount: subdirectories.length,
        itemBuilder: (context, index) {
          final dir = subdirectories[index];
          final dirIsAccessible =
              dir.accessibilityType == DirectoryAccessibilityType.accessible;
          return Card(
            color: dirIsAccessible ? null : Colors.pink[50],
            child: ListTile(
              leading: const Icon(Icons.folder),
              title: InkWell(
                onTap: () => _navigateToDirectory(dir),
                child: Text(path_module.basename(dir.path),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.info_outline, size: 16),
                onPressed: () {
                  setState(() {
                    _setFilePreviewWidget(_buildDirectoryPreview(dir));
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileList() {
    final colorScheme = Theme.of(context).colorScheme;
    final files = contents.whereType<File>().toList();
    final dimensions = LayoutDimensions.of(context);

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          _fileListController.jumpTo(
              _fileListController.offset + pointerSignal.scrollDelta.dy);
        }
      },
      child: ListView.builder(
        controller: _fileListController,
        shrinkWrap: true,
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return Card(
            surfaceTintColor: Colors.yellow,
            child: GestureDetector(
              onSecondaryTapDown: (details) {
                final RenderBox overlay =
                    Overlay.of(context).context.findRenderObject() as RenderBox;
                showMenu(
                  context: context,
                  position: RelativeRect.fromRect(
                    details.globalPosition & const Size(48, 48),
                    Offset.zero & overlay.size,
                  ),
                  items: [
                    PopupMenuItem(
                      child: const Text('Locate in explorer'),
                      onTap: () => _openInExplorer(file.path),
                    ),
                  ],
                );
              },
              onDoubleTap: () {
                final mimeType = lookupMimeType(file.path);
                if (mimeType?.startsWith('text/') ?? false) {
                  setState(() {
                    _setFilePreviewWidget(
                      Row(
                        children: [
                          Expanded(
                              child: _buildContentPreview(file.path,
                                  fullWidth: true)),
                          if (mimeType == 'text/markdown' &&
                              dimensions.contentWidth > 1200)
                            Expanded(
                              child: Markdown(
                                data: File(file.path).readAsStringSync(),
                              ),
                            ),
                        ],
                      ),
                    );
                  });
                } else {
                  _openFile(file.path);
                }
              },
              child: ListTile(
                title: Text(path_module.basename(file.path),
                    style: const TextStyle(
                        fontFamily: 'Courier', fontWeight: FontWeight.bold)),
                leading: IconButton(
                  icon: getIconForFilePath(file.path),
                  color: colorScheme.tertiary,
                  onPressed: () {},
                ),
                onTap: () {
                  print('Clicked asset: ${file.path}');
                  setState(() {
                    _setFilePreviewWidget(
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: SingleChildScrollView(
                              child: _buildMetadataTable(file.path),
                            ),
                          ),
                          if (dimensions.contentWidth > 800)
                            Expanded(
                              flex: 1,
                              child: _buildContentPreview(file.path),
                            ),
                        ],
                      ),
                    );
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeDirectory();
  }

  void _setFilePreviewWidget(Widget? previewWidget) {
    setState(() {
      filePreviewWidget = previewWidget;
    });
  }

  Future<void> _initializeDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      currentDirectory = directory;
      _updateContents();
    });
  }

  void _updateContents() async {
    if (currentDirectory != null) {
      switch (currentDirectory!.accessibilityType) {
        case DirectoryAccessibilityType.accessible:
          setState(() {
            contents = currentDirectory!.listSync();
          });
          break;
        case DirectoryAccessibilityType.virtual:
          final resolvedDir = await currentDirectory!.resolveVirtualPath();
          setState(() {
            contents = resolvedDir.listSync();
          });
          break;
        default:
          debugPrint('statError: ${currentDirectory!.path}');
          // TODO: Mark the Card as inaccessible
          break;
      }
    }
  }

  void _navigateToDirectory(Directory dir) async {
    if (dir.isVirtualFolder) {
      final resolvedDir = await dir.resolveVirtualPath();
      setState(() {
        currentDirectory = resolvedDir;
        _updateContents();
      });
    } else {
      setState(() {
        currentDirectory = dir;
        _updateContents();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentDirectory == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final dimensions = LayoutDimensions.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: dimensions.contentWidth / 3,
            height: dimensions.contentHeight,
            child: Wrap(
              children: [
                _buildCurrentDirectoryCard(),
                _buildFileList(),
                _buildSubdirectoryList(),
              ],
            ),
          ),
          if (filePreviewWidget != null)
            SizedBox(
              width: 2 * dimensions.contentWidth / 3 - 16,
              height: dimensions.contentHeight,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: filePreviewWidget!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
