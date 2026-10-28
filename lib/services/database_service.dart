
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance =
  DatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    // Web memakai SQLite WASM + IndexedDB.
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final db = await openDatabase(
      kIsWeb ? 'learning_tasks_web.db' : 'learning_tasks.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE learning_tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL DEFAULT '',
            due_date TEXT,
            is_completed INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );

    _database = db;
    return db;
  }

  Future<int> createTask({
    required String title,
    required String description,
    String? dueDate,
  }) async {
    final db = await database;

    return db.insert('learning_tasks', {
      'title': title,
      'description': description,
      'due_date': dueDate,
      'is_completed': 0,
    });
  }

  Future<List<Map<String, Object?>>> getTasks() async {
    final db = await database;

    return db.query(
      'learning_tasks',
      orderBy: 'id DESC',
    );
  }

  Future<int> updateTask({
    required int id,
    required String title,
    required String description,
    String? dueDate,
    required bool isCompleted,
  }) async {
    final db = await database;

    return db.update(
      'learning_tasks',
      {
        'title': title,
        'description': description,
        'due_date': dueDate,
        'is_completed': isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTask(int id) async {
    final db = await database;

    return db.delete(
      'learning_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
