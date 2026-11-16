// FILE NÀY ĐỂ LÀM GÌ: Lưu và đọc số bước theo ngày, mục tiêu bằng SQLite.
// Người phụ trách: Người 2

import 'package:sqflite/sqflite.dart';

import '../models/daily_steps.dart';
import 'app_database.dart';
import 'step_repository.dart';

/// NGƯỜI 2. Cài đặt StepRepository bằng SQLite. Dữ liệu chỉ lưu trên máy.
/// Mọi lỗi đọc/ghi đổi thành StepRepositoryException có thông báo dễ hiểu.
/// Dòng dữ liệu hỏng thì bỏ qua, không làm app dừng.
class SqliteStepRepository implements StepRepository {
  SqliteStepRepository(this._db);

  final AppDatabase _db;
  AppDatabase get db => _db;

  static const String _tableDailySteps = AppDatabase.tableDailySteps;
  static const String _tableSettings = AppDatabase.tableSettings;

  DailySteps? _parseDailySteps(Map<String, Object?> row) {
    try {
      final dateVal = row['date'];
      final stepsVal = row['steps'];
      if (dateVal is! String || stepsVal is! int) return null;
      if (stepsVal < 0) return null;
      final parsedDate = DateTime.tryParse(dateVal);
      if (parsedDate == null) return null;
      return DailySteps(parsedDate, stepsVal);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveDay(DailySteps day) async {
    try {
      await _db.database.insert(
        _tableDailySteps,
        {
          'date': day.key,
          'steps': day.steps,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi lưu ngày ${day.key}: $e');
    }
  }

  @override
  Future<DailySteps?> getDay(DateTime date) async {
    try {
      final key = DailySteps(date, 0).key;
      final rows = await _db.database.query(
        _tableDailySteps,
        where: 'date = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      return _parseDailySteps(rows.first);
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi đọc ngày $date: $e');
    }
  }

  @override
  Future<List<DailySteps>> getRange(DateTime from, DateTime to) async {
    try {
      final fromKey = DailySteps(from, 0).key;
      final toKey = DailySteps(to, 0).key;

      final rows = await _db.database.query(
        _tableDailySteps,
        where: 'date >= ? AND date <= ?',
        whereArgs: [fromKey, toKey],
        orderBy: 'date ASC',
      );

      final results = <DailySteps>[];
      for (final row in rows) {
        final parsed = _parseDailySteps(row);
        if (parsed != null) {
          results.add(parsed);
        }
      }
      return results;
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi lấy khoảng ngày từ $from đến $to: $e');
    }
  }

  @override
  Future<int> getGoal() async {
    try {
      final rows = await _db.database.query(
        _tableSettings,
        where: 'key = ?',
        whereArgs: ['goal'],
        limit: 1,
      );
      if (rows.isEmpty) return 8000;
      final val = rows.first['value'];
      if (val is! String) return 8000;
      final parsed = int.tryParse(val);
      if (parsed == null || parsed <= 0) return 8000;
      return parsed;
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi đọc mục tiêu: $e');
    }
  }

  @override
  Future<void> setGoal(int goal) async {
    if (goal <= 0) {
      throw StepRepositoryException(
        'Mục tiêu số bước phải lớn hơn 0 (nhận $goal)',
      );
    }
    try {
      await _db.database.insert(
        _tableSettings,
        {
          'key': 'goal',
          'value': goal.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi lưu mục tiêu: $e');
    }
  }

  @override
  Future<int?> getLastSensorValue() async {
    try {
      final rows = await _db.database.query(
        _tableSettings,
        where: 'key = ?',
        whereArgs: ['last_sensor_value'],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final val = rows.first['value'];
      if (val is! String) return null;
      return int.tryParse(val);
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi đọc số bước cảm biến cuối: $e');
    }
  }

  @override
  Future<void> setLastSensorValue(int value) async {
    try {
      await _db.database.insert(
        _tableSettings,
        {
          'key': 'last_sensor_value',
          'value': value.toString(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi lưu số bước cảm biến cuối: $e');
    }
  }

  @override
  Future<DateTime?> getLastGoalNotifiedDay() async {
    try {
      final rows = await _db.database.query(
        _tableSettings,
        where: 'key = ?',
        whereArgs: ['last_goal_notified_day'],
        limit: 1,
      );
      if (rows.isEmpty) return null;
      final val = rows.first['value'];
      if (val is! String) return null;
      final parsed = DateTime.tryParse(val);
      return parsed != null ? DailySteps.dayOf(parsed) : null;
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi đọc ngày đã gửi thông báo: $e');
    }
  }

  @override
  Future<void> setLastGoalNotifiedDay(DateTime day) async {
    try {
      final key = DailySteps(day, 0).key;
      await _db.database.insert(
        _tableSettings,
        {
          'key': 'last_goal_notified_day',
          'value': key,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      if (e is StepRepositoryException) rethrow;
      throw StepRepositoryException('Lỗi khi lưu ngày đã gửi thông báo: $e');
    }
  }
}
