import 'dart:io';
import 'package:flutter/material.dart';
import 'package:roadway/component/data_table.dart';
import 'package:roadway/component/plain_text_editor.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:roadway/drop.dart';

Widget getDroppableTextEditor(BuildContext context, TextEditingController controller) {
  return DropTarget(
    onDragDone: (detail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      controller.text = File(detail.files[0].path).readAsStringSync();
    },
    onDragEntered: (detail) {
      showDraggingSnackBar(context, 'Drop file to view');
    },
    onDragExited: (detail) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    },
    child: buildTextEditor('untitled', controller),
  );
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NavigatableContent(),
    );
  }
}

class NavigatableContent extends StatefulWidget {
  NavigatableContent({super.key});

  @override
  State<NavigatableContent> createState() => _NavigatableContentState();
}

class _NavigatableContentState extends State<NavigatableContent> {
  int _selectedIndex = 0;
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double navRailWidth = 100;
    // Get the width of the content area by using media query less the width of the navigation rail.
    double contentWidth = MediaQuery.of(context).size.width - navRailWidth;
    double contentHeight = MediaQuery.of(context).size.height;

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
            labelType: NavigationRailLabelType.selected,
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
                label: Text('Data'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.file_present_outlined),
                selectedIcon: Icon(Icons.file_present),
                label: Text('Edit'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.star_border),
                selectedIcon: Icon(Icons.star),
                label: Text('Third'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 0, width: 0),
          // This is the main content.
          SizedBox(
            width: contentWidth,
            height: contentHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                switch (_selectedIndex) {
                  0 => buildDroppableDataTable(context),
                  1 => getDroppableTextEditor(context, controller),
                  2 => const Placeholder(
                      key: Key('2'),
                      color: Colors.blue,
                      strokeWidth: 1,
                    ),
                  _ => const SizedBox(),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildDroppableDataTable(BuildContext context) {
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
    child: DataTableComponent(onDataCellTap: (data) {
      print(data);
    }),
  );
}

