// FILE NÀY ĐỂ LÀM GÌ: Tạo cơ sở dữ liệu SQLite trên máy.
// Người phụ trách: Người 2

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// NGƯỜI 2. Mở và khởi tạo SQLite.
/// Bảng daily_steps(date TEXT PRIMARY KEY, steps INTEGER),
/// bảng settings(key TEXT PRIMARY KEY, value TEXT).
class AppDatabase {
  AppDatabase(this.database);

  final Database database;

  static const String tableDailySteps = 'daily_steps';
  static const String columnDate = 'date';
  static const String columnSteps = 'steps';

  static const String tableSettings = 'settings';
  static const String columnKey = 'key';
  static const String columnValue = 'value';

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
      version: 1,
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
      },
    );
    return AppDatabase(db);
  }

  Future<void> close() async {
    await database.close();
  }
}
