import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:mime/mime.dart';
import 'dart:io';

/// Unique identifier for an XFile
extension UniqueXFile on XFile {
  String get uniqueId => sha256.convert(utf8.encode(path)).toString();
  ValueKey get key => ValueKey(uniqueId);
  bool isMarkdown() => lookupMimeType(path) == 'text/markdown';
  bool isPlainText() => lookupMimeType(path) == 'text/plain';
  bool isImage() => lookupMimeType(path)?.startsWith('image/') ?? false;
  bool isFolder() {
    return FileSystemEntity.typeSync(path) == FileSystemEntityType.directory;
  }
  bool exists() {
    return File(path).existsSync();
  }
}

/// Unique identifier for a URI
extension UniqueURL on Uri {
  String get uniqueId => sha256.convert(utf8.encode(toString())).toString();
  ValueKey get key => ValueKey(uniqueId);
}
