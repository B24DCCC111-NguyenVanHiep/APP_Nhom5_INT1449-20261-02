// FILE NÀY ĐỂ LÀM GÌ: Tính số bước tăng thêm, xét đạt mục tiêu, tính phần trăm tiến độ.
// Người phụ trách: Người 1

/// NGƯỜI 1. Logic thuần, không phụ thuộc Flutter, để unit test.
class StepCalculator {
  const StepCalculator();

  /// TODO: số bước tăng thêm giữa hai lần đọc cảm biến cộng dồn.
  /// Lưu ý: last == null (lần đầu) và current < last (máy khởi động lại).
  int delta(int? last, int current) => throw UnimplementedError();

  /// TODO: đạt mục tiêu khi steps >= goal (goal <= 0 thì không bao giờ đạt).
  bool reachedGoal(int steps, int goal) => throw UnimplementedError();

  /// TODO: tiến độ 0.0 - 1.0 để vẽ vòng tròn.
  double progress(int steps, int goal) => throw UnimplementedError();
}
