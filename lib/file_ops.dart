import 'dart:io';
import 'package:mime/mime.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:cross_file/cross_file.dart';
import 'package:sqflite/sqflite.dart';
import 'db_helper.dart';
import 'dart:convert';
import 'text_util.dart';

class FileInfo {
  final XFile xFile;
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
  final img.Image? image;
  final int? imageWidth;
  final int? imageHeight;
  final String? imageDimensionsFormatted;
  final String? imageError;

  FileInfo({
    required this.xFile,
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
    this.image,
    this.imageWidth,
    this.imageHeight,
    this.imageDimensionsFormatted,
    this.imageError,
  });

  Map<String, dynamic> asInfoObject() {
    return {
      'xFile': xFile,
      'filePath': filePath,
      'fileName': fileName,
      'fileExt': fileExt,
      'fileFolder': fileFolder,
      'mimeType': mimeType,
      'fileLength': fileLength,
      'fileLengthFormatted': fileLengthFormatted,
      'lastModified': lastModified,
      'lastModifiedFormatted': lastModifiedFormatted,
      'lastModifiedAgo': lastModifiedAgo,
      'textContent': textContent,
      'image': image,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'imageDimensionsFormatted': imageDimensionsFormatted,
      'imageError': imageError,
    };
  }

  String asJSON() {
    return const JsonEncoder.withIndent('  ').convert(asInfoObject());
  }

  // Needed here to reject a path that is actually a URI
  static bool isUri(String text) {
    return text.startsWith('http://') || text.startsWith('https://');
  }

  static Future<FileInfo> fromPath(String filePath) async {
    // Caller's responsibility
    if (FileInfo.isUri(filePath)) {
      throw Error();
    }

    // Check cache first
    FileInfo? cachedInfo = await _getFileInfoFromCache(filePath);
    if (cachedInfo != null) {
      return cachedInfo;
    }

    // If not in cache, create new FileInfo
    Map<String, dynamic> info =
        await _getFileInfo(xFile: XFile(path.normalize(filePath)));
    FileInfo fileInfo = FileInfo(
      xFile: info['xFile'],
      filePath: info['filePath'],
      fileName: info['fileName'],
      fileExt: info['fileExt'],
      fileFolder: info['fileFolder'],
      mimeType: info['mimetype'],
      fileLength: info['fileLength'],
      fileLengthFormatted: info['fileLengthFormatted'],
      lastModified: info['lastModified'],
      lastModifiedFormatted: info['lastModifiedFormatted'],
      lastModifiedAgo: info['lastModifiedAgo'],
      textContent: info['textContent'],
      image: info['image'],
      imageWidth: info['imageWidth'],
      imageHeight: info['imageHeight'],
      imageDimensionsFormatted: info['imageDimensionsFormatted'],
      imageError: info['imageError'],
    );

    // Cache the new FileInfo
    await _storeFileInfoInCache(fileInfo);

    return fileInfo;
  }

  static Future<FileInfo?> _getFileInfoFromCache(String filePath) async {
    List<Map<String, dynamic>> results =
        await DatabaseHelper.instance.getFileItemsWithPath(filePath);

    if (results.isNotEmpty) {
      Map<String, dynamic> cachedData = results.first;
      if (results.length > 1) {
        throw StateError(
            '${results.length} cache entries with primary key: $filePath');
      }
      return FileInfo(
        xFile: XFile(cachedData['filePath']),
        filePath: cachedData['filePath'],
        fileName: cachedData['fileName'],
        fileExt: cachedData['fileExt'],
        fileFolder: cachedData['fileFolder'],
        mimeType: cachedData['mimeType'],
        fileLength: cachedData['fileLength'],
        fileLengthFormatted: cachedData['fileLengthFormatted'],
        lastModified: DateTime.parse(cachedData['lastModified']),
        lastModifiedFormatted: cachedData['lastModifiedFormatted'],
        lastModifiedAgo: cachedData['lastModifiedAgo'],
        textContent: cachedData['textContent'],
        imageWidth: cachedData['imageWidth'],
        imageHeight: cachedData['imageHeight'],
        imageDimensionsFormatted: cachedData['imageDimensionsFormatted'],
        imageError: cachedData['imageError'],
      );
    }
    return null;
  }

  static Future<void> _storeFileInfoInCache(FileInfo fileInfo) async {
    Database db = await DatabaseHelper.instance.database;
    await db.insert(
      'file_info',
      {
        'filePath': fileInfo.filePath,
        'fileName': fileInfo.fileName,
        'fileExt': fileInfo.fileExt,
        'fileFolder': fileInfo.fileFolder,
        'mimeType': fileInfo.mimeType,
        'fileLength': fileInfo.fileLength,
        'fileLengthFormatted': fileInfo.fileLengthFormatted,
        'lastModified': fileInfo.lastModified.toIso8601String(),
        'lastModifiedFormatted': fileInfo.lastModifiedFormatted,
        'lastModifiedAgo': fileInfo.lastModifiedAgo,
        'textContent': fileInfo.textContent,
        'imageWidth': fileInfo.imageWidth,
        'imageHeight': fileInfo.imageHeight,
        'imageDimensionsFormatted': fileInfo.imageDimensionsFormatted,
        'imageError': fileInfo.imageError,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>> _getFileInfo(
      {String? filePath, XFile? xFile}) async {
    XFile fileToProcess;
    Map<String, dynamic> result = {};

    if (xFile != null) {
      fileToProcess = xFile;
    } else if (filePath != null) {
      String normalizedPath = path.normalize(filePath);
      fileToProcess = XFile(normalizedPath);
    } else {
      throw ArgumentError('Either filePath or xFile must be provided');
    }

    result['xFile'] = fileToProcess;
    result['filePath'] = fileToProcess.path;
    result['fileName'] = path.basename(fileToProcess.path);
    result['fileExt'] = path.extension(fileToProcess.path);
    result['fileFolder'] = path.dirname(fileToProcess.path);

    final File file = File(fileToProcess.path);
    final String? mimeType = lookupMimeType(file.path);
    result['mimetype'] = mimeType ?? 'Unknown';

    final int fileLength = await fileToProcess.length();
    result['fileLength'] = fileLength;
    result['fileLengthFormatted'] = formatFileSize(fileLength);

    final DateTime lastModified = await file.lastModified();
    result['lastModified'] = lastModified;
    final String formattedDate = formatDateTime(lastModified, withAgo: false);
    result['lastModifiedFormatted'] = formattedDate;
    result['lastModifiedAgo'] = getTimeAgo(lastModified);

    if (mimeType?.startsWith('text/') == true) {
      final String fileContent = await fileToProcess.readAsString();
      result['textContent'] = fileContent;
    } else if (mimeType?.startsWith('image/') == true) {
      try {
        final bytes = await file.readAsBytes();
        final image = img.decodeImage(bytes);
        result['image'] = image;
        result['imageWidth'] = image!.width;
        result['imageHeight'] = image.height;
        result['imageDimensionsFormatted'] = '${image.width}x${image.height}';
      } catch (e) {
        result['imageError'] = 'Error decoding image: $e';
      }
    }

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'fileExt': fileExt,
      'fileFolder': fileFolder,
      'mimeType': mimeType,
      'fileLengthFormatted': fileLengthFormatted,
      'lastModifiedFormatted': lastModifiedFormatted,
      'lastModifiedAgo': lastModifiedAgo,
    };
  }
}
