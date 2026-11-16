// FILE NÀY ĐỂ LÀM GÌ: Điểm khởi động của app. Chọn cảm biến thật hay giả (chế độ demo).
// Người phụ trách: Người 5

import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_database.dart';
import 'data/fake_step_sensor_service.dart';
import 'data/friends_repository.dart';
import 'data/in_memory_step_repository.dart';
import 'data/pedometer_sensor_service.dart';
import 'data/sqlite_step_repository.dart';
import 'data/step_repository.dart';
import 'data/step_sensor_service.dart';
import 'services/notification_service.dart';

/// NGƯỜI 5. Bật chế độ demo (bước giả, dữ liệu trong bộ nhớ):
///   flutter run --dart-define=DEMO=true
const bool _useDemo = bool.fromEnvironment('DEMO');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  StepSensorService sensor;
  StepRepository repository;
  GoalNotifier notifier;
  final friendsRepository = FakeFriendsRepository();

  if (_useDemo) {
    sensor = FakeStepSensorService();
    repository = InMemoryStepRepository();
    notifier = FakeGoalNotifier();
  } else {
    try {
      final db = await AppDatabase.open();
      repository = SqliteStepRepository(db);
    } catch (_) {
      // Fallback về InMemoryStepRepository nếu SQLite chưa hoàn thiện
      repository = InMemoryStepRepository();
    }

    try {
      sensor = PedometerSensorService();
    } catch (_) {
      sensor = FakeStepSensorService();
    }

    notifier = LocalGoalNotifier();
  }

  runApp(
    StepTrackerApp(
      sensor: sensor,
      repository: repository,
      notifier: notifier,
      friendsRepository: friendsRepository,
    ),
  );
}
