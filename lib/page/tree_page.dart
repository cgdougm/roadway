import 'package:flutter/material.dart';
import '../component/cwd_bar.dart';
import '../component/file_tree.dart';

class TreePage extends StatelessWidget {
  const TreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CwdBar(),
        const Expanded(
          child: FileTree(),
        ),
      ],
    );
  }
} 