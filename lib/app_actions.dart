import 'package:flutter/material.dart';

final List<Widget> appBarActions = [
  PopupMenuButton<String>(
    tooltip: 'Settings',
    icon: const Icon(Icons.settings),
    onSelected: (String result) {
      if (result == 'dump') {
      } else if (result == 'browser') {
      }
    },
    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      const PopupMenuItem<String>(
        value: 'dump',
        child: Text('Dump to console'),
      ),
      const PopupMenuItem<String>(
        value: 'browser',
        child: Text('File Browser'),
      ),
    ],
  ),
];
