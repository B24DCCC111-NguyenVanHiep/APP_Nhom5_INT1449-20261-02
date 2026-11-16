// FILE NÀY ĐỂ LÀM GÌ: Bản lưu tạm trong bộ nhớ để người khác dùng khi SQLite chưa xong.
// Người phụ trách: Người 2

import '../models/daily_steps.dart';
import 'step_repository.dart';

/// NGƯỜI 2. Bản giả trong bộ nhớ, để người 3, 4 làm giao diện khi SQLite chưa xong.
/// Cài đặt bằng Map<String, DailySteps> (key = DailySteps.key).
class InMemoryStepRepository implements StepRepository {
  final Map<String, DailySteps> _days = {};
  int _goal = 8000;
  int? _lastSensorValue;
  DateTime? _lastGoalNotifiedDay;

  @override
  Future<void> saveDay(DailySteps day) async {
    _days[day.key] = day;
  }

  @override
  Future<DailySteps?> getDay(DateTime date) async {
    final key = DailySteps(date, 0).key;
    return _days[key];
  }

  @override
  Future<List<DailySteps>> getRange(DateTime from, DateTime to) async {
    final fromDay = DailySteps.dayOf(from);
    final toDay = DailySteps.dayOf(to);

    final result = _days.values.where((d) {
      return (d.date.isAtSameMomentAs(fromDay) || d.date.isAfter(fromDay)) &&
          (d.date.isAtSameMomentAs(toDay) || d.date.isBefore(toDay));
    }).toList();

    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  @override
  Future<int> getGoal() async => _goal;

  @override
  Future<void> setGoal(int goal) async {
    if (goal <= 0) {
      throw StepRepositoryException(
        'Mục tiêu số bước phải lớn hơn 0 (nhận $goal)',
      );
    }
    _goal = goal;
  }

  @override
  Future<int?> getLastSensorValue() async => _lastSensorValue;

  @override
  Future<void> setLastSensorValue(int value) async {
    _lastSensorValue = value;
  }

  @override
  Future<DateTime?> getLastGoalNotifiedDay() async => _lastGoalNotifiedDay;

  @override
  Future<void> setLastGoalNotifiedDay(DateTime day) async {
    _lastGoalNotifiedDay = DailySteps.dayOf(day);
  }
}
