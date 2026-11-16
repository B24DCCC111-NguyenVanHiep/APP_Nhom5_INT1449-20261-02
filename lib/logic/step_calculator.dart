// FILE NÀY ĐỂ LÀM GÌ: Tính số bước tăng thêm, xét đạt mục tiêu, tính phần trăm tiến độ.
// Người phụ trách: Người 1

/// NGƯỜI 1. Logic thuần, không phụ thuộc Flutter, để unit test.

class StepCalculator {
  const StepCalculator();

  int delta(int? last, int current) {
    if (last == null) return 0;
    if (current <= 0) return 0;
    if (current < last) return current;
    return current - last;
  }

  bool reachedGoal(int steps, int goal) {
    if (goal <= 0) return false;
    return steps >= goal;
  }

  double progress(int steps, int goal) {
    if (goal <= 0 || steps <= 0) return 0.0;
    final ratio = steps / goal;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  int percent(int steps, int goal) => (progress(steps, goal) * 100).floor();
}
