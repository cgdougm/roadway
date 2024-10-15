import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDB('app_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Initialize FFI for desktop platforms
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {

    await db.execute('''
      CREATE TABLE IF NOT EXISTS items (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        parent TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS file_info(
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

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }

  Future<void> insertItem(String id, String type, String value, {String? parent}) async {
    final db = await database;
    await db.insert('items', {
      'id': id,
      'type': type,
      'value': value,
      'parent': parent,
    });
  }

  Future<void> deleteItem(String id) async {
    final db = await database;
    await db.delete(
      'items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getDbItems() async {
    final db = await database;
    return db.query('items');
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

  Future<void> insertItemIfNotExists(String id, String type, String value, {String? parent}) async {
    final db = await database;
    final exists = await itemExists(id);
    if (!exists) {
      await db.insert('items', {
        'id': id,
        'type': type,
        'value': value,
        'parent': parent,
      });
    }
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
}

