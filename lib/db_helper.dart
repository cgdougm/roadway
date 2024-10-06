import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
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

    print('Database path: $path'); // Add this line

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        value TEXT NOT NULL,
        parent TEXT
      )
    ''');
  }

  Future<void> insertItem(String id, String type, String value,
      {String? parent}) async {
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

  Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return db.query('items');
  }

  Future<List<Map<String, Object?>>> getAllItems() async {
    final db = await database;
    final List<Map<String, Object?>> items = await db.query('items');
    return items;
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

  Future<void> insertItemIfNotExists(String id, String type, String value,
      {String? parent}) async {
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
}
