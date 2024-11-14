import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

/// The class containing a TreeView that highlights the selected node.
/// The custom TreeView.treeNodeBuilder makes tapping the whole row of a parent
/// toggle the node open and closed with TreeView.toggleNodeWith. The
/// scrollbars will appear as the content exceeds the bounds of the viewport.
class FileTree extends StatefulWidget {
  /// Creates a screen that demonstrates the TreeView widget.
  const FileTree({super.key});

  @override
  State<FileTree> createState() => FileTreeState();
}

/// The state of the [FileTree].
class FileTreeState extends State<FileTree> {
  /// The [TreeViewController] associated with this [TreeView].
  @visibleForTesting
  final TreeViewController treeController = TreeViewController();

  /// The [ScrollController] associated with the vertical axis.
  @visibleForTesting
  final ScrollController verticalController = ScrollController();

  TreeViewNode<String>? _selectedNode;
  final ScrollController _horizontalController = ScrollController();

  // MOCK DATA
  final List<TreeViewNode<String>> _tree = <TreeViewNode<String>>[
    TreeViewNode<String>('README.md'),
    TreeViewNode<String>('analysis_options.yaml'),
    TreeViewNode<String>(
      'lib',
      children: <TreeViewNode<String>>[
        TreeViewNode<String>(
          'src',
          children: <TreeViewNode<String>>[
            TreeViewNode<String>(
              'common',
              children: <TreeViewNode<String>>[
                TreeViewNode<String>('span.dart'),
              ],
            ),
          ],
        ),
        TreeViewNode<String>('two_dimensional_scrollables.dart'),
      ],
    ),
    TreeViewNode<String>('README.md'),
  ];

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _treeNodeBuilder(
    BuildContext context,
    TreeViewNode<String> node,
    AnimationStyle toggleAnimationStyle,
  ) {
    final bool isParentNode = node.children.isNotEmpty;
    return GestureDetector(
      onSecondaryTapDown: (details) {
        showMenu(
          context: context,
          popUpAnimationStyle:
              AnimationStyle(duration: const Duration(milliseconds: 100)),
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          items: [
            PopupMenuItem<String>(
              value: isParentNode ? 'Jump' : 'View',
              child: Text(isParentNode ? 'Jump' : 'View'),
            ),
            PopupMenuItem<String>(
              value: isParentNode ? 'Explore' : 'Ingest',
              child: Text(isParentNode ? 'Explore' : 'Ingest'),
            ),
          ],
        ).then((value) {
          if (value != null && mounted) {
            // Handle menu item selection
            switch (value) {
              case 'View':
                // Implement view logic
                break;
              case 'Ingest':
                // Navigator.of(context).pop(); // THROWS ERROR and black screen
                _showSnackBar(context, 'Ingesting: ${node.content}');
                break;
              case 'Jump':
                // Implement jump logic
                break;
              case 'Explore':
                // Implement explore logic
                break;
              default:
                throw Exception('Invalid menu item selected');
            }
          }
        });
      },
      child: Row(
        children: <Widget>[
          SizedBox(width: 20.0 * node.depth! + 4.0),
          DecoratedBox(
            decoration: BoxDecoration(),
            child: SizedBox.square(
              dimension: 12.0,
              child: Icon(
                isParentNode
                    ? Icons.folder_open
                    : Icons.file_present,
                size: 12,
              ),
            ),
          ),
          const SizedBox(width: 6.0),
          Text(node.content),
        ],
      ),
    );
  }



  Map<Type, GestureRecognizerFactory> _getTapRecognizer(
    TreeViewNode<String> node,
  ) {
    return <Type, GestureRecognizerFactory>{
      TapGestureRecognizer:
          GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(),
        (TapGestureRecognizer t) => t.onTap = () {
          setState(() {
            treeController.toggleNode(node);
            _selectedNode = node;
          });
        },
      ),
    };
  }

  Widget _getTree() {
    return Scrollbar(
      controller: _horizontalController,
      thumbVisibility: true,
      child: Scrollbar(
        controller: verticalController,
        thumbVisibility: true,
        child: TreeView<String>(
          controller: treeController,
          verticalDetails: ScrollableDetails.vertical(
            controller: verticalController,
          ),
          horizontalDetails: ScrollableDetails.horizontal(
            controller: _horizontalController,
          ),
          tree: _tree,
          onNodeToggle: (TreeViewNode<String> node) {
            setState(() {
              _selectedNode = node;
            });
          },
          treeNodeBuilder: _treeNodeBuilder,
          treeRowBuilder: (TreeViewNode<String> node) {
            // Selected node
            if (_selectedNode == node) {
              return TreeRow(
                extent: FixedTreeRowExtent(
                  20.0 + (node.children.isNotEmpty ? 10.0 : 0.0),
                ),
                recognizerFactories: _getTapRecognizer(node),
                backgroundDecoration: TreeRowDecoration(
                    ),
                foregroundDecoration: const TreeRowDecoration(
                    border: TreeRowBorder.all(BorderSide(
                  width: 1,
                ))),
              );
            }
            return TreeRow(
              extent: FixedTreeRowExtent(
                20.0 + (node.children.isNotEmpty ? 10.0 : 0.0),
              ),
              recognizerFactories: _getTapRecognizer(node),
              backgroundDecoration: TreeRowDecoration(
                  ),
            );
          },
          // No internal indentation, the custom treeNodeBuilder applies its
          // own indentation to decorate in the indented space.
          indentation: TreeViewIndentationType.none,
        ),
      ),
    );
  }

  @override
  void dispose() {
    verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> selectedChildren = <Widget>[];
    if (_selectedNode != null) {
      selectedChildren.addAll(<Widget>[
        const SizedBox(height: 10),
        Row(
          children: [
            const SizedBox(width: 10),
            Icon(
              _selectedNode!.children.isEmpty
                  ? Icons.file_present
                  : Icons.folder_outlined,
              size: 20,
            ),
            const SizedBox(width: 5.0),
            Text(_selectedNode!.content),
            Spacer(),
          ],
        ),
        const Spacer(),
      ]);
    }
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
              fontFamily: 'Courier New',
            ),
      ),
      child: Scaffold(
        body: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
            child: SizedBox(
              width: 400,
              height: double.infinity,
              child: _getTree(),
            ),
          ),
        ),
      ),
    );
  }
}
