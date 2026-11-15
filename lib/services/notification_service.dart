// FILE NÀY ĐỂ LÀM GÌ: Gửi thông báo khi người dùng đạt mục tiêu bước chân.
// Người phụ trách: Người 5

/// NGƯỜI 5. Thông báo cục bộ khi đạt mục tiêu.
/// TODO: thêm gói `flutter_local_notifications`; xin quyền POST_NOTIFICATIONS
/// (Android 13+) đúng lúc người dùng bật nhắc.
abstract class GoalNotifier {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> showGoalReached(int steps);
}

class LocalGoalNotifier implements GoalNotifier {
  @override
  Future<void> init() => throw UnimplementedError();

  @override
  Future<bool> requestPermission() => throw UnimplementedError();

  @override
  Future<void> showGoalReached(int steps) => throw UnimplementedError();
}

/// Bản giả cho test và demo.
class FakeGoalNotifier implements GoalNotifier {
  int shown = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showGoalReached(int steps) async => shown++;
}

// TODO: đếm bước khi app ở nền (foreground service hoặc workmanager).
