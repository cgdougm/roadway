import 'dart:io';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:roadway/core/db.dart';
import 'package:roadway/core/unique_id.dart';

class FileMetadata {
  final String filePath;
  final String fileName;
  final String fileExt;
  final String fileFolder;
  final String mimeType;
  final int fileLength;
  final String fileLengthFormatted;
  final DateTime lastModified;
  final String lastModifiedFormatted;
  final String lastModifiedAgo;
  final String? textContent;
  final int? imageWidth;
  final int? imageHeight;
  final String? imageDimensionsFormatted;
  final String? imageError;

  FileMetadata({
    required this.filePath,
    required this.fileName,
    required this.fileExt,
    required this.fileFolder,
    required this.mimeType,
    required this.fileLength,
    required this.fileLengthFormatted,
    required this.lastModified,
    required this.lastModifiedFormatted,
    required this.lastModifiedAgo,
    this.textContent,
    this.imageWidth,
    this.imageHeight,
    this.imageDimensionsFormatted,
    this.imageError,
  });

  Map<String, dynamic> toMap() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'fileExt': fileExt,
      'fileFolder': fileFolder,
      'mimeType': mimeType,
      'fileLength': fileLength,
      'fileLengthFormatted': fileLengthFormatted,
      'lastModified': lastModified.toIso8601String(),
      'lastModifiedFormatted': lastModifiedFormatted,
      'lastModifiedAgo': lastModifiedAgo,
      'textContent': textContent,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'imageDimensionsFormatted': imageDimensionsFormatted,
      'imageError': imageError,
    };
  }

  factory FileMetadata.fromMap(Map<String, dynamic> map) {
    return FileMetadata(
      filePath: map['filePath'],
      fileName: map['fileName'],
      fileExt: map['fileExt'],
      fileFolder: map['fileFolder'],
      mimeType: map['mimeType'],
      fileLength: map['fileLength'],
      fileLengthFormatted: map['fileLengthFormatted'],
      lastModified: DateTime.parse(map['lastModified']),
      lastModifiedFormatted: map['lastModifiedFormatted'],
      lastModifiedAgo: map['lastModifiedAgo'],
      textContent: map['textContent'],
      imageWidth: map['imageWidth'],
      imageHeight: map['imageHeight'],
      imageDimensionsFormatted: map['imageDimensionsFormatted'],
      imageError: map['imageError'],
    );
  }
}

class FileMetadataCache {
  static final FileMetadataCache instance = FileMetadataCache._();
  FileMetadataCache._();

  Future<void> initialize() async {
    final db = await DatabaseHelper.instance.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS file_metadata (
        filePath TEXT PRIMARY KEY,
        fileName TEXT,
        fileExt TEXT,
        fileFolder TEXT,
        mimeType TEXT,
        fileLength INTEGER,
        fileLengthFormatted TEXT,
        lastModified TEXT,
        lastModifiedFormatted TEXT,
        lastModifiedAgo TEXT,
        textContent TEXT,
        imageWidth INTEGER,
        imageHeight INTEGER,
        imageDimensionsFormatted TEXT,
        imageError TEXT
      )
    ''');
  }

  Future<FileMetadata?> getMetadata(String filePath) async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> results = await db.query(
      'file_metadata',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );

    if (results.isEmpty) return null;
    return FileMetadata.fromMap(results.first);
  }

  Future<void> setMetadata(FileMetadata metadata) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'file_metadata',
      metadata.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteMetadata(String filePath) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete(
      'file_metadata',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
  }

  Future<FileMetadata> gatherMetadata(String filePath) async {
    final file = File(filePath);
    final stat = await file.stat();
    final mimeType = lookupMimeType(filePath);
    final fileName = path.basename(filePath);
    final fileExt = path.extension(filePath);
    final fileFolder = path.dirname(filePath);
    final fileLength = await file.length();
    final fileLengthFormatted = _formatFileSize(fileLength);
    final lastModified = stat.modified;
    final lastModifiedFormatted = _formatDateTime(lastModified);
    final lastModifiedAgo = _getTimeAgo(lastModified);

    String? textContent;
    int? imageWidth;
    int? imageHeight;
    String? imageDimensionsFormatted;
    String? imageError;

    if (mimeType?.startsWith('text/') == true) {
      try {
        textContent = await file.readAsString();
      } catch (e) {
        // Ignore text content errors
      }
    } else if (mimeType?.startsWith('image/') == true) {
      try {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          imageWidth = image.width;
          imageHeight = image.height;
          imageDimensionsFormatted = '${image.width}x${image.height}';
        }
      } catch (e) {
        imageError = 'Error decoding image: $e';
      }
    }

    return FileMetadata(
      filePath: filePath,
      fileName: fileName,
      fileExt: fileExt,
      fileFolder: fileFolder,
      mimeType: mimeType ?? 'Unknown',
      fileLength: fileLength,
      fileLengthFormatted: fileLengthFormatted,
      lastModified: lastModified,
      lastModifiedFormatted: lastModifiedFormatted,
      lastModifiedAgo: lastModifiedAgo,
      textContent: textContent,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      imageDimensionsFormatted: imageDimensionsFormatted,
      imageError: imageError,
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else if (difference.inSeconds > 0) {
      return '${difference.inSeconds} second${difference.inSeconds == 1 ? '' : 's'} ago';
    } else {
      return 'just now';
    }
  }
} 