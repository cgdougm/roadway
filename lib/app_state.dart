import 'package:flutter/foundation.dart';
import 'core/db.dart';
import 'core/unique_id.dart';
import 'package:cross_file/cross_file.dart';
import 'package:path/path.dart' as path;
import 'core/text.dart';
import 'dart:io';
import 'package:sqflite/sqflite.dart';

class DirectoryVisit {
  final String path;
  final DateTime visitTime;

  DirectoryVisit({required this.path, required this.visitTime});

  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'visitTime': visitTime.toIso8601String(),
    };
  }

  factory DirectoryVisit.fromMap(Map<String, dynamic> map) {
    return DirectoryVisit(
      path: map['path'],
      visitTime: DateTime.parse(map['visitTime']),
    );
  }
}

class AppState extends ChangeNotifier {
  final List<XFile> _files = [];
  final List<Uri> _urls = [];
  String _cwd = '';
  final List<DirectoryVisit> _directoryVisits = [];
  bool _showDotFiles = false;
  final _db = DatabaseHelper.instance;

  List<XFile> get files => _files;
  List<Uri> get urls => _urls;
  String get cwd => _cwd;
  List<DirectoryVisit> get directoryVisits => _directoryVisits;
  bool get showDotFiles => _showDotFiles;

  AppState() {
    _loadCwd();
    _loadDirectoryVisits();
    _loadSettings();
  }

  Future<void> _loadCwd() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query('app_settings', where: 'key = ?', whereArgs: ['cwd']);
    
    if (results.isNotEmpty) {
      _cwd = results.first['value'] as String;
      notifyListeners();
    } else {
      // Set default CWD to user's home directory
      final homeDir = await _getHomeDirectory();
      await setCwd(homeDir.path);
    }
  }

  Future<Directory> _getHomeDirectory() async {
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        return Directory(userProfile);
      }
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) {
        return Directory(home);
      }
    }
    throw Exception('Home directory not found');
  }

  Future<void> _saveCwd() async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'app_settings',
      {'key': 'cwd', 'value': _cwd},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _loadDirectoryVisits() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query('directory_visits', orderBy: 'visitTime DESC');
    _directoryVisits.clear();
    _directoryVisits.addAll(results.map((row) => DirectoryVisit.fromMap(row)));
    notifyListeners();
  }

  Future<void> _saveDirectoryVisits() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('directory_visits');
    for (var visit in _directoryVisits) {
      await db.insert('directory_visits', visit.toMap());
    }
  }

  Future<void> setCwd(String newCwd) async {
    if (_cwd != newCwd) {
      _cwd = newCwd;
      await _saveCwd();
      await addDirectoryVisit(newCwd);
      notifyListeners();
    }
  }

  Future<void> addDirectoryVisit(String dirPath) async {
    // Remove any existing visit for this directory
    _directoryVisits.removeWhere((visit) => visit.path == dirPath);
    
    // Add new visit at the beginning
    _directoryVisits.insert(0, DirectoryVisit(
      path: dirPath,
      visitTime: DateTime.now(),
    ));

    // Keep only visits from last 3 days or max 12 items
    final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
    while (_directoryVisits.length > 12 || 
           (_directoryVisits.isNotEmpty && _directoryVisits.last.visitTime.isBefore(threeDaysAgo))) {
      _directoryVisits.removeLast();
    }

    await _saveDirectoryVisits();
    notifyListeners();
  }

  void addFile(XFile file) {
    if (!_files.any((f) => f.uniqueId == file.uniqueId)) {
      _files.add(file);
      DatabaseHelper.instance.insertItemIfNotExists(
          file.uniqueId, 'file', file.path,
          parent: path.dirname(file.path));
      notifyListeners();
    }
  }

  void addFiles(List<XFile> xfiles) {
    bool changed = false;
    for (XFile file in xfiles) {
      if (!_files.any((f) => f.uniqueId == file.uniqueId)) {
        _files.add(file);
        DatabaseHelper.instance.insertItemIfNotExists(
            file.uniqueId, 'file', file.path,
            parent: path.dirname(file.path));
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
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

  Future<void> setShowDotFiles(bool value) async {
    _showDotFiles = value;
    await _db.setSetting('showDotFiles', value.toString());
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final showDotFilesStr = await _db.getSetting('showDotFiles');
    _showDotFiles = showDotFilesStr == 'true';
    notifyListeners();
  }
}
