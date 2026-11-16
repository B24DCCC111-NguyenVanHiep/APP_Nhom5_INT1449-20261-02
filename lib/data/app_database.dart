// FILE NÀY ĐỂ LÀM GÌ: Tạo cơ sở dữ liệu SQLite trên máy.
// Người phụ trách: Người 2

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// NGƯỜI 2. Mở và khởi tạo SQLite.
/// Bảng daily_steps(date TEXT PRIMARY KEY, steps INTEGER),
/// bảng settings(key TEXT PRIMARY KEY, value TEXT),
/// bảng users(id TEXT PRIMARY KEY, name TEXT, email TEXT UNIQUE, password TEXT, created_at TEXT).
class AppDatabase {
  AppDatabase(this.database);

  final Database database;

  static const String tableDailySteps = 'daily_steps';
  static const String columnDate = 'date';
  static const String columnSteps = 'steps';

  static const String tableSettings = 'settings';
  static const String columnKey = 'key';
  static const String columnValue = 'value';

  static const String tableUsers = 'users';
  static const String columnUserId = 'id';
  static const String columnUserName = 'name';
  static const String columnUserEmail = 'email';
  static const String columnUserPassword = 'password';
  static const String columnUserCreatedAt = 'created_at';

  static Future<AppDatabase> open({String? path}) async {
    final String dbPath;
    final bool singleInstance;

    if (path != null) {
      dbPath = path;
      singleInstance = path != inMemoryDatabasePath;
    } else {
      final databasesPath = await getDatabasesPath();
      dbPath = p.join(databasesPath, 'step_tracker.db');
      singleInstance = true;
    }

    final db = await openDatabase(
      dbPath,
      singleInstance: singleInstance,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableDailySteps (
            $columnDate TEXT PRIMARY KEY,
            $columnSteps INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableSettings (
            $columnKey TEXT PRIMARY KEY,
            $columnValue TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE $tableUsers (
            $columnUserId TEXT PRIMARY KEY,
            $columnUserName TEXT NOT NULL,
            $columnUserEmail TEXT NOT NULL UNIQUE,
            $columnUserPassword TEXT NOT NULL,
            $columnUserCreatedAt TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $tableUsers (
              $columnUserId TEXT PRIMARY KEY,
              $columnUserName TEXT NOT NULL,
              $columnUserEmail TEXT NOT NULL UNIQUE,
              $columnUserPassword TEXT NOT NULL,
              $columnUserCreatedAt TEXT NOT NULL
            )
          ''');
        }
      },
    );
    return AppDatabase(db);
  }

  Future<void> close() async {
    await database.close();
  }
}
