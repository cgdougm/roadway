import 'package:flutter/foundation.dart';
import 'db_helper.dart';
import 'unique_id.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class AppState extends ChangeNotifier {
  final List<XFile> _files = [];
  final List<Uri> _urls = [];

  List<XFile> get files => _files;
  List<Uri> get urls => _urls;

  void addFile(XFile file) {
    if (!_files.any((f) => f.uniqueId == file.uniqueId)) {
      _files.add(file);
      DatabaseHelper.instance.insertItem(file.uniqueId, 'file', file.path, parent: path.dirname(file.path));
      notifyListeners();
    }
  }

  void addURL(Uri url) {
    if (!_urls.any((u) => u.uniqueId == url.uniqueId)) {
      _urls.add(url);
      DatabaseHelper.instance.insertItem(url.uniqueId, 'url', url.toString(), parent: url.host);
      notifyListeners();
    }
  }

  void handleDroppedFiles(List<XFile> xfiles) {
    print('Dropped files: $xfiles');
    for (var file in xfiles) {
      addFile(file);
    }
    notifyListeners();
  }

}