import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:roadway/component/data_cards.dart';
import 'package:roadway/component/md.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:roadway/drop.dart';
import 'package:roadway/icon/markdown.dart';
import 'package:roadway/layout/dimensions.dart';
import 'package:roadway/controller/text_file_controller.dart';
// import 'package:roadway/component/filebrowser.dart';
import 'dart:convert';
import 'package:roadway/component/file_tree.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const rowInsetWidth = 100.0; // Navigation rail width
    final contentWidth = MediaQuery.of(context).size.width - rowInsetWidth;
    final contentHeight = MediaQuery.of(context).size.height - 51;

    return LayoutDimensions(
      contentWidth: contentWidth,
      contentHeight: contentHeight,
      rowInsetWidth: rowInsetWidth,
      child: const NavigatableContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class NavigatableContent extends StatefulWidget {
  const NavigatableContent({super.key});

  @override
  State<NavigatableContent> createState() => _NavigatableContentState();
}

class _NavigatableContentState extends State<NavigatableContent> {
  int _selectedIndex = 0;
  final controller = TextFileController();

  void switchToTextEditor() {
    setState(() {
      _selectedIndex = 1; // Index 1 corresponds to the Text Editor tab
    });
  }

  @override
  Widget build(BuildContext context) {
    final dimensions = LayoutDimensions.of(context);
    // Get the width of the content area by using media query less the width of the navigation rail.
    double contentWidth = dimensions.contentWidth;
    double contentHeight = dimensions.contentHeight;

    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          NavigationRail(
            selectedIndex: _selectedIndex,
            groupAlignment: -1,
            elevation: 12,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            trailing: PopupMenuButton(
              icon: const Icon(Icons.more_horiz_rounded),
              position: PopupMenuPosition.under,
              offset: const Offset(8, 0),
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'files',
                  child: Row(
                    children: [
                      Icon(Icons.insert_drive_file),
                      SizedBox(width: 8),
                      Text('Dev:Files'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'about',
                  child: Row(
                    children: [
                      Icon(Icons.info),
                      SizedBox(width: 8),
                      Text('About'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                // Handle menu item selection
                switch (value) {
                  case 'settings':
                    // Add settings action
                    break;
                  case 'files':
                    // Add settings action
                    break;
                  case 'about':
                    // Add about action
                    break;
                }
              },
            ),
            destinations: const <NavigationRailDestination>[
              // NavigationRailDestination(
              //   icon: Icon(Icons.insert_drive_file_outlined),
              //   selectedIcon: Icon(Icons.insert_drive_file),
              //   label: Text('Files'),

              // ),
              NavigationRailDestination(
                icon: Icon(Icons.account_tree_outlined),
                selectedIcon: Icon(Icons.account_tree),
                label: Text('Tree'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.dataset_outlined),
                selectedIcon: Icon(Icons.dataset_rounded),
                label: Text('Assets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.file_present_outlined),
                selectedIcon: Icon(Icons.file_present),
                label: Text('Editor'),
              ),
              NavigationRailDestination(
                icon: Icon(MarkdownIcon.markdown),
                selectedIcon: Icon(MarkdownIcon.markdown),
                label: Text('Notes'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 0, width: 0),
          const SizedBox(width: 10),
          // This is the main content.
          SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: Container(
              child: switch (_selectedIndex) {
                // 0 => const FileBrowser(),
                0 => const FileTree(),
                1 => buildDroppableDataTable(context, controller,
                    switchToTextEditor, contentWidth, contentHeight),
                2 => getDroppableTextEditor(context, controller),
                _ => const SizedBox(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildDroppableDataTable(
    BuildContext context,
    TextFileController controller,
    VoidCallback onSwitchToEditor,
    double contentWidth,
    double contentHeight,
    {int widthUnits = 8,
    int heightUnits = 2}) {
  return DropTarget(
    onDragDone: (detail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      handleFileDrop(detail.files.map((xFile) => xFile.path).toList(), context);
    },
    onDragEntered: (detail) {
      showDraggingSnackBar(context, 'Drop file(s) to ingest');
    },
    onDragExited: (detail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    },
    child: Row(
      children: [
        DataCardsComponent(
            contentWidth: widthUnits * 48,
            contentHeight: contentHeight,
            widthUnits: widthUnits,
            heightUnits: heightUnits,
            onDataCellTap: (data) {
              final mimeType = lookupMimeType(data['value']);
              if (mimeType?.startsWith('text/') ?? false) {
                final file = File(data['value']);
                try {
                  controller.text = file.readAsStringSync(encoding: utf8);
                } catch (e) {
                  controller.text = file.readAsStringSync(encoding: latin1);
                }
                onSwitchToEditor();
              } else if (mimeType?.startsWith('image/') ?? false) {
                // TODO: handle image
              } else if (mimeType == null) {
                // TODO: handle directory
              }
            }),
        SizedBox(width: contentWidth - widthUnits * 48),
      ],
    ),
  );
}

Widget getDroppableTextEditor(
    BuildContext context, TextFileController controller) {
  return DropTarget(
    onDragDone: (detail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      final file = File(detail.files[0].path);
      try {
        controller.text = file.readAsStringSync(encoding: utf8);
      } catch (e) {
        controller.text = file.readAsStringSync(encoding: latin1);
      }
    },
    onDragEntered: (detail) {
      showDraggingSnackBar(context, 'Drop file to view');
    },
    onDragExited: (detail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    },
    child: MarkdownEditorWidget(controller: controller),
  );
}
