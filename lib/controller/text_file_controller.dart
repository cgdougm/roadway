import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert' show utf8;

class TextFileController extends TextEditingController {
  String? filePath;
  
  TextFileController({this.filePath, super.text});

  Future<void> setFilePath(String? path) async {
    filePath = path;
    if (path != null) {
      try {
        final file = File(path);
        // Try to detect the encoding from the file's BOM (Byte Order Mark)
        final bytes = await file.readAsBytes();
        late String contents;
        
        if (bytes.length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
          // UTF-8 with BOM
          contents = utf8.decode(bytes.sublist(3));
        } else {
          // Default to UTF-8 without BOM
          contents = utf8.decode(bytes, allowMalformed: true);
        }
        
        text = contents;
      } catch (e) {
        // Handle file reading errors
        text = 'Error reading file: $e';
      }
    }
  }
} 