import 'package:flutter/material.dart';
import 'dart:io';

class RenameDialog extends StatefulWidget {
  final String initialPath;

  RenameDialog({required this.initialPath});

  @override
  _RenameDialogState createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  final _oldPathController = TextEditingController();
  final _newPathController = TextEditingController();
  String _oldPath = '';
  String _newPath = '';
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    _oldPath = widget.initialPath;
    _newPath = widget.initialPath;
    _oldPathController.text = _oldPath;
    _newPathController.text = _newPath;
  }

  bool _checkEnabled() {
    return _oldPath.isNotEmpty && _newPath.isNotEmpty && _oldPath != _newPath;
  }

  void _renameFiles() {
    File file = File(_oldPath);
    file.rename(_newPath);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rename File'),
      content: Container(
        height: 100,
        child: Column(
          children: [
            TextField(
              controller: _oldPathController,
              onChanged: (value) {
                setState(() {
                  _oldPath = value;
                  _isEnabled = _checkEnabled();
                });
              },
              decoration: InputDecoration(
                hintText: 'Old file path',
              ),
            ),
            TextField(
              controller: _newPathController,
              onChanged: (value) {
                setState(() {
                  _newPath = value;
                  _isEnabled = _checkEnabled();
                });
              },
              decoration: InputDecoration(
                hintText: 'New file path',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        Opacity(
          opacity: _isEnabled ? 1.0 : 0.75,
          child: TextButton(
            child: Text('Rename'),
            onPressed: _isEnabled ? _renameFiles : null,
          ),
        ),
      ],
    );
  }
}

void showRenameDialog(BuildContext context, String initialPath) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return RenameDialog(initialPath: initialPath);
    },
  );
}
