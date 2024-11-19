import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

void createNewFileBrowser(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const FileBrowser(showCloseButton: true)));
}

class FileBrowser extends StatefulWidget {
  final Function(File)? onFileView;
  final bool showCloseButton;

  const FileBrowser(
      {super.key, this.onFileView, this.showCloseButton = true});

  @override
  FileBrowserState createState() => FileBrowserState();
}

class FileBrowserState extends State<FileBrowser> {
  Directory? currentDirectory;
  List<FileSystemEntity> contents = [];

  @override
  void initState() {
    super.initState();
    _initializeDirectory();
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

  Widget _buildCurrentDirectoryCard() {
    return Card(
      child: ListTile(
        title: Text(path.basename(currentDirectory!.path),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: RichText(
          text: TextSpan(children: [
            TextSpan(
                text: '${path.dirname(currentDirectory!.path)}\n',
              style: const TextStyle(fontSize: 10, fontFamily: 'Courier')),
            TextSpan(
                text: '(${contents.whereType<File>().length} files, ',
                style: const TextStyle(fontSize: 10, fontFamily: 'Courier')),
            TextSpan(
                text: '${contents.whereType<Directory>().length} directories)',
                style: const TextStyle(fontSize: 9, fontFamily: 'Courier')),
          ]),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_upward),
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
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
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
    final files = contents.whereType<File>().toList();
    return ListView.builder(
      shrinkWrap: true,
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
            surfaceTintColor: Colors.yellow,
            child: ListTile(
              title: Text(path.basename(file.path)),
              trailing: IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: () {
                  if (widget.onFileView != null) {
                    widget.onFileView!(file);
                  }
                },
              ),
              onTap: () {
                // TODO: Expand to show metadata
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

    double windowWidth = MediaQuery.of(context).size.width;
    double previewWidth = windowWidth / 2;

    return Padding(
      padding: EdgeInsets.fromLTRB(8.0, 8.0, previewWidth, 0),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(widget.showCloseButton ? 40 : 0, 0, 0, 0),
            child: Column(
              children: [
                _buildCurrentDirectoryCard(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSubdirectoryList(),
                        _buildFileList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          widget.showCloseButton
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
