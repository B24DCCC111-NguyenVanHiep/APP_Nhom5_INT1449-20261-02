// FILE NÀY ĐỂ LÀM GÌ: Cửa ngõ lấy câu gợi ý/khích lệ cho thẻ trên màn chính (chừa chỗ cho AI sau này).
// Người phụ trách: Người 3

import '../ui/formatters.dart';
import '../ui/strings.dart';

/// Dữ liệu đưa vào bộ tạo gợi ý. Chỉ chứa số, không có thông tin cá nhân.
class InsightInput {
  const InsightInput({
    required this.steps,
    required this.goal,
    required this.progress,
  });
  final int steps;
  final int goal;

  /// 0.0 - 1.0, lấy từ StepCalculator.
  final double progress;
}

/// Giao diện gợi ý. HomeScreen chỉ biết giao diện này, nên sau này thay bản AI
/// (gọi máy chủ riêng, KHÔNG để API key trong app) mà không sửa UI.
/// Hàm đồng bộ để dùng được trong build(); bản AI nên lưu sẵn kết quả gần nhất
/// và trả về bản tĩnh khi chưa có/không có mạng.
abstract class InsightProvider {
  const InsightProvider();
  String insightFor(InsightInput input);
}

/// Bản mặc định: câu khích lệ cố định theo % tiến độ.
class StaticInsightProvider extends InsightProvider {
  const StaticInsightProvider();

  @override
  String insightFor(InsightInput input) {
    final remaining = input.goal > input.steps ? input.goal - input.steps : 0;
    if (input.steps <= 0) return AppStrings.insightStart;
    if (remaining == 0 || input.progress >= 1.0) return AppStrings.insightDone;
    if (input.progress >= 0.5) {
      return AppStrings.insightHalfway(formatSteps(remaining));
    }
    return AppStrings.insightRemaining(formatSteps(remaining));
  }
}
