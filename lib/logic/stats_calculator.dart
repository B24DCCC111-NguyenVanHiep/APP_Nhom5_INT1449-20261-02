// FILE NÀY ĐỂ LÀM GÌ: Tính trung bình, số ngày đạt mục tiêu, điền ngày thiếu cho biểu đồ.
// Người phụ trách: Người 4
import '../models/daily_steps.dart';

/// Phân loại mức hoàn thành mục tiêu một ngày.
/// - Đạt: từ 100% mục tiêu trở lên.
/// - Gần đạt: từ 80% đến dưới 100%.
/// - Thấp: dưới 80% (bao gồm ngày 0 bước).
enum StepGoalLevel { achieved, near, low }

/// Kết quả thống kê trong một khoảng gồm [numberOfDays] ngày, tính cả hôm nay.
/// Mỗi phần tử trong [days] là tổng số bước của một ngày.
class StepStatistics {
  const StepStatistics({
    required this.days,
    required this.totalSteps,
    required this.averageSteps,
    required this.daysReachedGoal,
    required this.bestDaySteps,
    required this.bestDayDate,
    required this.dailyGoal,
  });

  /// Danh sách đủ ngày (cũ -> mới), ngày không có dữ liệu sẽ có 0 bước.
  final List<DailySteps> days;
  final int totalSteps;
  final double averageSteps;
  final int daysReachedGoal;
  final int bestDaySteps;

  /// null khi toàn bộ khoảng không có bước chân (> 0).
  final DateTime? bestDayDate;
  final int dailyGoal;

  int get numberOfDays => days.length;
  DateTime get startDate => days.first.date;
  DateTime get endDate => days.last.date;
}

/// Người 4: chỉ xử lý nghiệp vụ thống kê; không truy cập cảm biến hoặc SQLite.
/// Dùng model DailySteps CHUNG của nhóm từ lib/models/daily_steps.dart.
class StatsCalculator {
  const StatsCalculator._();

  /// Phân loại theo mục tiêu được lưu bởi StepRepository.getGoal().
  /// Không thay đổi dữ liệu bước chân hoặc số ngày đạt mục tiêu.
  static StepGoalLevel classifyGoalLevel({
    required int steps,
    required int dailyGoal,
  }) {
    if (steps < 0) {
      throw ArgumentError.value(steps, 'steps', 'Không được âm');
    }
    if (dailyGoal <= 0) {
      throw ArgumentError.value(dailyGoal, 'dailyGoal', 'Phải > 0');
    }
    if (steps >= dailyGoal) return StepGoalLevel.achieved;
    if (steps / dailyGoal >= 0.8) return StepGoalLevel.near;
    return StepGoalLevel.low;
  }

  static DateTime dateOnly(DateTime value) => DailySteps.dayOf(value);

  /// Tính ngày đầu khoảng, bao gồm cả [endDate].
  /// Ví dụ: 16/11 và 7 ngày -> 10/11.
  static DateTime startDateFor(DateTime endDate, int numberOfDays) {
    if (numberOfDays <= 0) {
      throw ArgumentError.value(numberOfDays, 'numberOfDays', 'Phải > 0');
    }
    final end = dateOnly(endDate);
    return DateTime(end.year, end.month, end.day - numberOfDays + 1);
  }

  /// [records]: danh sách DailySteps (tổng bước mỗi ngày) từ repository.getRange().
  /// - Tự điền 0 cho ngày thiếu trong khoảng.
  /// - Nếu trùng ngày thì lấy tổng bước LỚN NHẤT, không cộng dồn.
  /// - Trung bình chia đủ số ngày chọn, kể cả ngày 0 bước.
  /// - Áp dụng mục tiêu hiện tại cho cả khoảng (repo chỉ lưu một goal).
  static StepStatistics calculate({
    required Iterable<DailySteps> records,
    required int numberOfDays,
    required int dailyGoal,
    DateTime? referenceDate,
  }) {
    if (numberOfDays <= 0) {
      throw ArgumentError.value(numberOfDays, 'numberOfDays', 'Phải > 0');
    }
    if (dailyGoal <= 0) {
      throw ArgumentError.value(dailyGoal, 'dailyGoal', 'Phải > 0');
    }

    final end = dateOnly(referenceDate ?? DateTime.now());
    final start = startDateFor(end, numberOfDays);
    final byDate = <DateTime, int>{};

    for (final record in records) {
      if (record.steps < 0) {
        throw ArgumentError.value(record.steps, 'steps', 'Không được âm');
      }
      final day = dateOnly(record.date);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      final previous = byDate[day];
      if (previous == null || record.steps > previous) {
        byDate[day] = record.steps;
      }
    }

    final days = List<DailySteps>.unmodifiable(
      List<DailySteps>.generate(numberOfDays, (index) {
        final day = DateTime(start.year, start.month, start.day + index);
        return DailySteps(day, byDate[day] ?? 0);
      }),
    );

    var sum = 0;
    var reached = 0;
    var best = 0;
    DateTime? bestDate;

    for (final day in days) {
      sum += day.steps;
      if (day.steps >= dailyGoal) reached++;
      if (day.steps > best) {
        best = day.steps;
        bestDate = day.date;
      }
    }

    return StepStatistics(
      days: days,
      totalSteps: sum,
      averageSteps: sum / numberOfDays,
      daysReachedGoal: reached,
      bestDaySteps: best,
      bestDayDate: bestDate,
      dailyGoal: dailyGoal,
    );
  }
}
