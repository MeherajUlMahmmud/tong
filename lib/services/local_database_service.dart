import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tong_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Daily data table
    await db.execute('''
      CREATE TABLE daily_data (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        date TEXT NOT NULL,
        categoryId TEXT NOT NULL,
        count INTEGER NOT NULL,
        synced INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        UNIQUE(userId, date, categoryId)
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation TEXT NOT NULL,
        tableName TEXT NOT NULL,
        data TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Category operations
  static Future<void> insertCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.insert(
      'categories',
      {
        'id': category['id'],
        'title': category['title'],
        'price': category['price'],
        'userId': category['userId'],
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getCategories(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps;
  }

  static Future<void> updateCategory(Map<String, dynamic> category) async {
    final db = await database;
    await db.update(
      'categories',
      {
        'title': category['title'],
        'price': category['price'],
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [category['id']],
    );
  }

  static Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  }

  // Daily data operations
  static Future<void> insertDailyData(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'daily_data',
      {
        'userId': data['userId'],
        'date': data['date'],
        'categoryId': data['categoryId'],
        'count': data['count'],
        'synced': data['synced'] ?? 0,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getDailyData(
      String userId, String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_data',
      where: 'userId = ? AND date = ?',
      whereArgs: [userId, date],
    );
    return maps;
  }

  static Future<void> updateDailyData(Map<String, dynamic> data) async {
    final db = await database;
    await db.update(
      'daily_data',
      {
        'count': data['count'],
        'synced': data['synced'] ?? 0,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'userId = ? AND date = ? AND categoryId = ?',
      whereArgs: [data['userId'], data['date'], data['categoryId']],
    );
  }

  static Future<List<Map<String, dynamic>>> getUnsyncedData() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'daily_data',
      where: 'synced = ?',
      whereArgs: [0],
    );
    return maps;
  }

  static Future<void> markAsSynced(int id) async {
    final db = await database;
    await db.update(
      'daily_data',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync queue operations
  static Future<void> addToSyncQueue(
      String operation, String tableName, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert(
      'sync_queue',
      {
        'operation': operation,
        'tableName': tableName,
        'data': data.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getSyncQueue() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sync_queue',
      orderBy: 'createdAt ASC',
    );
    return maps;
  }

  static Future<void> removeFromSyncQueue(int id) async {
    final db = await database;
    await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Utility methods
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete('categories');
    await db.delete('daily_data');
    await db.delete('sync_queue');
  }

  static Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
