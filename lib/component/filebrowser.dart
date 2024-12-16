import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path_module;
import 'package:roadway/layout/dimensions.dart';
import 'package:roadway/core/mime.dart';

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

  Widget _buildFilePreview(String filePath) {
    final dimensions = LayoutDimensions.of(context);
    debugPrint('buildFilePreview filePath: $filePath');

    // TODO: handle other files besides images

    final mimeType = lookupMimeType(filePath);
    debugPrint('mimeType: $mimeType');
    return Center(
        child: SizedBox(
            width: 2 * dimensions.contentWidth / 3 - 8,
            height: dimensions.contentHeight - 8,
            child: (mimeType?.startsWith('image/') ?? false)
                ? Image.file(File(filePath),
                    fit: BoxFit.scaleDown, alignment: Alignment.center)
                : const SizedBox(child: Text('other'))));
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

  Widget _buildSubdirectoryList() {
    final subdirectories = contents.whereType<Directory>().toList();
    return ListView.builder(
      shrinkWrap: true,
      itemCount: subdirectories.length,
      itemBuilder: (context, index) {
        final dir = subdirectories[index];
        final dirIsAccessible =
            dir.accessibilityType == DirectoryAccessibilityType.accessible;
        return Card(
          color: dirIsAccessible ? null : Colors.pink[50],
          child: ListTile(
            title: Text(path_module.basename(dir.path),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_forward, size: 16),
              onPressed: () => _navigateToDirectory(dir),
            ),
            onTap: () {
              // TODO: Expand to show metadata
            },
          ),
        );
      },
    );
  }

  Widget _buildFileList() {
    final colorScheme = Theme.of(context).colorScheme;
    final files = contents.whereType<File>().toList();
    return ListView.builder(
      shrinkWrap: true,
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          surfaceTintColor: Colors.yellow,
          child: ListTile(
            title: Text(path_module.basename(file.path),
                style: const TextStyle(
                    fontFamily: 'Courier', fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: getIconForFilePath(file.path),
              color: colorScheme.tertiary,
              onPressed: () {
                // TODO: Expand to show metadata
                // if (widget.onFileView != null) {
                //   widget.onFileView!(file);
                // }
              },
            ),
            onTap: () {
              debugPrint('onTap: $file');
              _setFilePreviewWidget(_buildFilePreview(file.path));
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentDirectory == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final dimensions = LayoutDimensions.of(context);
    // final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Row(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
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
          ),
          filePreviewWidget ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
