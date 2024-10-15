import 'package:flutter/foundation.dart';
import 'db_helper.dart';
import 'unique_id.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'text_util.dart';

class AppState extends ChangeNotifier {
  final List<XFile> _files = [];
  final List<Uri> _urls = [];

  List<XFile> get files => _files;
  List<Uri> get urls => _urls;

  void addFile(XFile file) {
    if (!_files.any((f) => f.uniqueId == file.uniqueId)) {
      _files.add(file);
      DatabaseHelper.instance.insertItemIfNotExists(
          file.uniqueId, 'file', file.path,
          parent: path.dirname(file.path));
      notifyListeners();
    }
  }

  void addURL(Uri url) {
    if (!_urls.any((u) => u.uniqueId == url.uniqueId)) {
      _urls.add(url);
      DatabaseHelper.instance
          .insertItem(url.uniqueId, 'url', url.toString(), parent: url.host);
      notifyListeners();
    }
  }

  void addFiles(List<XFile> xfiles) {
    for (XFile file in xfiles) {
      addFile(file);
    }
    notifyListeners();
  }

  Future<void> deleteItem(String uniqueId) async {
    await DatabaseHelper.instance.deleteItem(uniqueId);
    XFile value = _files.firstWhere((u) => u.uniqueId == uniqueId);
    _files.remove(value);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    return await DatabaseHelper.instance.getDbItems();
  }

  /// Return XFile of the given string file path, or null if it is not
  /// already ingested/known.
  XFile? isFilePathIngested(String filePath) {
    XFile myXFile = XFile(filePath);
    for (XFile xFile in _files) {
      if (xFile.uniqueId == myXFile.uniqueId) return xFile;
    }
    return null;
  }

  Uri? isUriIngested(String uriText) {
    Uri? myUri = Uri.tryParse(removeEnclosingQuotes(uriText));
    for (Uri uri in _urls) {
      if (uri.uniqueId == myUri?.uniqueId) return uri;
    }
    return null;
  }
}
