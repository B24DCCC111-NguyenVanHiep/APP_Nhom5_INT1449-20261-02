// FILE NÀY ĐỂ LÀM GÌ: Tính trung bình, số ngày đạt mục tiêu, điền ngày thiếu cho biểu đồ.
// Người phụ trách: Người 4

import '../models/daily_steps.dart';

/// NGƯỜI 4. Thống kê thuần, để unit test.
class StatsCalculator {
  const StatsCalculator();

  /// TODO: điền 0 cho ngày thiếu dữ liệu, trả về đúng [days] phần tử,
  /// kết thúc ở ngày [end].
  List<DailySteps> fillDays(List<DailySteps> data, DateTime end, int days) =>
      throw UnimplementedError();

  /// TODO: trung bình bước mỗi ngày (danh sách rỗng thì 0).
  double average(List<DailySteps> data) => throw UnimplementedError();

  /// TODO: số ngày có steps >= goal.
  int daysReachedGoal(List<DailySteps> data, int goal) =>
      throw UnimplementedError();
}
