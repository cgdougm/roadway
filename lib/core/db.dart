import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final String path = join(await getDatabasesPath(), 'roadway.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        uniqueId TEXT PRIMARY KEY,
        type TEXT,
        path TEXT,
        parent TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE file_info (
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

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE directory_visits (
        path TEXT PRIMARY KEY,
        visitTime TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  Future<void> insertItemIfNotExists(String uniqueId, String type, String path, {String? parent}) async {
    final db = await database;
    await db.insert(
      'items',
      {
        'uniqueId': uniqueId,
        'type': type,
        'path': path,
        'parent': parent,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> deleteItem(String uniqueId) async {
    final db = await database;
    await db.delete(
      'items',
      where: 'uniqueId = ?',
      whereArgs: [uniqueId],
    );
  }

  Future<List<Map<String, dynamic>>> getDbItems() async {
    final db = await database;
    return await db.query('items');
  }

  Future<bool> itemExists(String id) async {
    final db = await database;
    final result = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getItem(String id) async {
    final db = await database;
    final results = await db.query(
      'items',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');
    
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop platforms
      sqfliteFfiInit();
      final factory = databaseFactoryFfi;
      await factory.deleteDatabase(path);
    } else {
      // For mobile platforms
      await databaseFactory.deleteDatabase(path);
    }
    
    _database = null;
  }

  Future<List<Map<String, dynamic>>> getFileItemsWithPath(String filePath) async {
    final db = await database;
    return await db.query(
      'file_info',
      where: 'filePath = ?',
      whereArgs: [filePath],
    );
  }

  // Settings methods
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }
}

