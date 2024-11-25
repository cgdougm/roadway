import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:roadway/layout/dimensions.dart';
import 'package:roadway/core/mime.dart';

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

  void _updateContents() {
    if (currentDirectory != null) {
      setState(() {
        contents = currentDirectory!.listSync();
      });
    }
  }

  void _navigateToDirectory(Directory newDir) {
    setState(() {
      currentDirectory = newDir;
      _updateContents();
    });
  }

  Widget _buildFilePreview(String filePath) {
    final dimensions = LayoutDimensions.of(context);
    debugPrint('buildFilePreview filePath: $filePath');
    return SizedBox(
      width: 2 * dimensions.contentWidth / 3 - 8,
      height: dimensions.contentHeight - 8,
      // child: Center(child: Text('Preview $filePath')),
      child: Center(
          child: SizedBox(
              width: 2 * dimensions.contentWidth / 3 - 8,
              height: dimensions.contentHeight - 8,
              child: Image.file(File(filePath), fit: BoxFit.scaleDown, alignment: Alignment.center))),
    );
  }

  Widget _buildCurrentDirectoryCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final filesInCurrentDirectory = contents.whereType<File>().toList();
    final directoriesInCurrentDirectory =
        contents.whereType<Directory>().toList();

    return Card(
      color: colorScheme.primaryContainer,
      child: ListTile(
        title: Text(path.basename(currentDirectory!.path),
            style: TextStyle(
                fontWeight: FontWeight.bold, color: colorScheme.secondary)),
        subtitle: RichText(
          text: TextSpan(children: [
            TextSpan(
                text: '${path.dirname(currentDirectory!.path)}\n',
                style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w700,
                    color: colorScheme.tertiary)),
            if (filesInCurrentDirectory.length > 0)
              TextSpan(
                  text: '${filesInCurrentDirectory.length} files, ',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.tertiary)),
            if (directoriesInCurrentDirectory.length > 0)
              TextSpan(
                  text: '${directoriesInCurrentDirectory.length} directories',
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
        return Card(
          surfaceTintColor: Colors.green,
          child: ListTile(
            title: Text(path.basename(dir.path),
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
            title: Text(path.basename(file.path),
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
