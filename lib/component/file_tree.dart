import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart' as tds;
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../core/file_metadata_cache.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter_simple_treeview/flutter_simple_treeview.dart';

/// The class containing a TreeView that highlights the selected node.
/// The custom TreeView.treeNodeBuilder makes tapping the whole row of a parent
/// toggle the node open and closed with TreeView.toggleNodeWith. The
/// scrollbars will appear as the content exceeds the bounds of the viewport.
class FileTree extends StatefulWidget {
  const FileTree({super.key});

  @override
  State<FileTree> createState() => _FileTreeState();
}

/// The state of the [FileTree].
class _FileTreeState extends State<FileTree> {
  late TreeController _treeController;
  String _currentCwd = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _treeController = TreeController(allNodesExpanded: false);
  }

  List<TreeNode> _buildNodes(String dirPath) {
    if (dirPath.isEmpty) {
      return [TreeNode(content: const Text('Loading...'))];
    }

    final directory = Directory(dirPath);
    if (!directory.existsSync()) {
      return [TreeNode(content: const Text('Directory not found'))];
    }

    final List<TreeNode> nodes = [];
    List<FileSystemEntity> entities = [];
    
    try {
      entities = directory.listSync();
    } catch (e) {
      // Handle access denied or other errors
      return [
        TreeNode(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_off, size: 16, color: Colors.red),
              const SizedBox(width: 8),
              Text(path.basename(dirPath)),
            ],
          ),
        ),
      ];
    }
    
    // Sort entities: directories first, then files
    entities.sort((a, b) {
      if (a is Directory && b is! Directory) return -1;
      if (a is! Directory && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });

    for (final entity in entities) {
      final name = path.basename(entity.path);
      if (!context.read<AppState>().showDotFiles && name.startsWith('.')) {
        continue;
      }

      if (entity is Directory) {
        nodes.add(TreeNode(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder, size: 16),
              const SizedBox(width: 8),
              Text(name),
            ],
          ),
          children: _buildNodes(entity.path),
        ));
      } else {
        nodes.add(TreeNode(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, size: 16),
              const SizedBox(width: 8),
              Text(name),
            ],
          ),
        ));
      }
    }

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        _currentCwd = appState.cwd;
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                  fontFamily: 'Courier',
                  fontSizeFactor: 1.2,
                ),
          ),
          child: Scaffold(
            body: Column(
              children: [
                // Path bar at the top
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.folder, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentCwd.isEmpty ? 'Loading...' : _currentCwd,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tree view with scrolling
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
                      child: SizedBox(
                        width: 400,
                        child: TreeView(
                          treeController: _treeController,
                          nodes: _buildNodes(_currentCwd),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
