// FILE NÀY ĐỂ LÀM GÌ: Bộ não màn chính: nhận bước từ cảm biến, lưu lại, báo giao diện cập nhật.
// Người phụ trách: Người 3

import 'package:flutter/foundation.dart';

import '../data/step_repository.dart';
import '../data/step_sensor_service.dart';
import '../services/notification_service.dart';
import 'step_calculator.dart';

enum StepsStatus { loading, noPermission, error, ready }

/// NGƯỜI 3. Nối sensor + repository + notifier, cung cấp trạng thái cho UI.
/// Mọi phụ thuộc truyền qua constructor để thay bằng bản giả khi test.
class StepsController extends ChangeNotifier {
  StepsController({
    required this.sensor,
    required this.repository,
    required this.notifier,
    this.calculator = const StepCalculator(),
  });

  final StepSensorService sensor;
  final StepRepository repository;
  final GoalNotifier notifier;
  final StepCalculator calculator;

  StepsStatus status = StepsStatus.loading;
  String? errorMessage;
  int todaySteps = 0;
  int goal = 8000;

  double get progress => calculator.progress(todaySteps, goal);

  /// TODO: đọc mục tiêu và bước hôm nay; kiểm tra quyền; nghe sensor.
  /// Mỗi lần có số mới: delta -> cộng vào hôm nay -> lưu -> thông báo nếu đạt
  /// mục tiêu (mỗi ngày một lần) -> notifyListeners().
  Future<void> start() => throw UnimplementedError();

  /// TODO: kiểm tra giá trị hợp lệ, lưu, cập nhật goal.
  Future<void> setGoal(int value) => throw UnimplementedError();

  @override
  void dispose() {
    // TODO: huỷ StreamSubscription của sensor.
    super.dispose();
  }
}
