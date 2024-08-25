import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'my_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY,
        number INTEGER,
        date TEXT,
        message TEXT,
        imagePath TEXT
      )
    ''');
  }

  Future<int> insertItem(Map<String, dynamic> item) async {
    Database? db = await database;
    return await db!.insert('items', item);
  }

  Future<List<Map<String, dynamic>>> getItems() async {
    Database? db = await database;
    return await db!.query('items');
  }
}
