// FILE NÀY ĐỂ LÀM GÌ: Điểm khởi động của app. Chọn cảm biến thật hay giả (chế độ demo).
// Người phụ trách: Người 5

import 'package:flutter/material.dart';

import 'app.dart';

/// NGƯỜI 5. Bật chế độ demo (bước giả, dữ liệu trong bộ nhớ):
///   flutter run --dart-define=DEMO=true
// ignore: unused_element
const bool _useDemo = bool.fromEnvironment('DEMO');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: nếu _useDemo dùng FakeStepSensorService + InMemoryStepRepository,
  // ngược lại PedometerSensorService + SqliteStepRepository(await AppDatabase.open()).
  runApp(const StepTrackerApp());
}
