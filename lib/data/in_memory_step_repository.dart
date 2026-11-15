// FILE NÀY ĐỂ LÀM GÌ: Bản lưu tạm trong bộ nhớ để người khác dùng khi SQLite chưa xong.
// Người phụ trách: Người 2

import '../models/daily_steps.dart';
import 'step_repository.dart';

/// NGƯỜI 2. Bản giả trong bộ nhớ, để người 3, 4 làm giao diện khi SQLite chưa xong.
/// TODO: cài đặt bằng Map<String, DailySteps> (key = DailySteps.key).
class InMemoryStepRepository implements StepRepository {
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
