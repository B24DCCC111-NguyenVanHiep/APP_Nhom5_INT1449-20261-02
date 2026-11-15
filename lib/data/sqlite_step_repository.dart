// FILE NÀY ĐỂ LÀM GÌ: Lưu và đọc số bước theo ngày, mục tiêu bằng SQLite.
// Người phụ trách: Người 2

import '../models/daily_steps.dart';
import 'app_database.dart';
import 'step_repository.dart';

/// NGƯỜI 2. Cài đặt StepRepository bằng SQLite. Dữ liệu chỉ lưu trên máy.
/// TODO: mọi lỗi đọc/ghi đổi thành StepRepositoryException có thông báo dễ hiểu.
/// TODO: dòng dữ liệu hỏng thì bỏ qua, không làm app dừng.
class SqliteStepRepository implements StepRepository {
  SqliteStepRepository(this._db);
  // ignore: unused_field
  final AppDatabase _db;

  @override
  Future<void> saveDay(DailySteps day) => throw UnimplementedError();

  @override
  Future<DailySteps?> getDay(DateTime date) => throw UnimplementedError();

  @override
  Future<List<DailySteps>> getRange(DateTime from, DateTime to) =>
      throw UnimplementedError();

  @override
  Future<int> getGoal() => throw UnimplementedError();

  @override
  Future<void> setGoal(int goal) => throw UnimplementedError();

  @override
  Future<int?> getLastSensorValue() => throw UnimplementedError();

  @override
  Future<void> setLastSensorValue(int value) => throw UnimplementedError();

  @override
  Future<DateTime?> getLastGoalNotifiedDay() => throw UnimplementedError();

  @override
  Future<void> setLastGoalNotifiedDay(DateTime day) =>
      throw UnimplementedError();
}
