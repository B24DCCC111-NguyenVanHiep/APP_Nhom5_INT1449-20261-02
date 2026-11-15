// FILE NÀY ĐỂ LÀM GÌ: Quy ước chung: cách lưu và đọc số bước. Muốn đổi phải báo cả nhóm.
// Người phụ trách: Cả nhóm

import '../models/daily_steps.dart';

/// HỢP ĐỒNG (nhóm trưởng sở hữu).
/// Bản thật: SqliteStepRepository (người 2). Bản giả: InMemoryStepRepository.
abstract class StepRepository {
  Future<void> saveDay(DailySteps day);
  Future<DailySteps?> getDay(DateTime date);

  /// Gồm cả hai đầu [from] và [to], sắp xếp theo ngày tăng dần.
  Future<List<DailySteps>> getRange(DateTime from, DateTime to);

  Future<int> getGoal();
  Future<void> setGoal(int goal);

  /// Số bước cảm biến ở lần đọc cuối (để tính hiệu số sau khi mở lại app).
  Future<int?> getLastSensorValue();
  Future<void> setLastSensorValue(int value);

  /// Ngày đã gửi thông báo đạt mục tiêu (mỗi ngày chỉ gửi một lần).
  Future<DateTime?> getLastGoalNotifiedDay();
  Future<void> setLastGoalNotifiedDay(DateTime day);
}

class StepRepositoryException implements Exception {
  StepRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}
