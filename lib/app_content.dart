import 'package:flutter/material.dart';
import 'package:roadway/component/filebrowser.dart';

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  @override
  Widget build(BuildContext context) {
    // return const Center(child: Text('hello', style: TextStyle(fontSize: 36, fontFamily: 'HeptaSlab')));
    return const FileBrowser(showCloseButton: false);
  }
}
