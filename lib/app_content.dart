import 'dart:io';
import 'package:flutter/material.dart';
import 'package:roadway/component/data_cards.dart';
import 'package:roadway/component/md.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:roadway/drop.dart';
import 'package:roadway/layout/dimensions.dart';
import 'package:roadway/controller/text_file_controller.dart';
import 'package:roadway/component/filebrowser.dart';

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
                  case 'about':
                    // Add about action
                    break;
                }
              },
            ),
            destinations: const <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.data_array_outlined),
                selectedIcon: Icon(Icons.data_array),
                label: Text('Data Table'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.file_present_outlined),
                selectedIcon: Icon(Icons.file_present),
                label: Text('Text Editor'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                label: Text('File browser'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 0, width: 0),
          // This is the main content.
          SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: Container(
              child: switch (_selectedIndex) {
                0 => buildDroppableDataTable(context, controller),
                1 => getDroppableTextEditor(context, controller),
                2 => const FileBrowser(),
                _ => const SizedBox(),
              },
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildDroppableDataTable(BuildContext context, TextFileController controller) {
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
    child: DataCardsComponent(onDataCellTap: (data) {
      print(data);
      controller.text = File(data['value']).readAsStringSync();
    }),
  );
}

Widget getDroppableTextEditor(BuildContext context, TextFileController controller) {
  return DropTarget(
    onDragDone: (detail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // TODO: This is a temporary text editor for the app. It should be replaced with a more sophisticated editor.
      // It fails to handle anything but UTF-8 encoded plain text.
      // Here is the error thrown for, say, ANSI encoded text:
      // Error: Unsupported operation: Unsupported encoding: ANSI_X3.4-1968
      // flutter: #1      _File.readAsStringSync (dart:io/file_impl.dart:624:7)
      controller.text = File(detail.files[0].path).readAsStringSync();
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
