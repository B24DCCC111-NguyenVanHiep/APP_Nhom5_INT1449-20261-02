// FILE NÀY ĐỂ LÀM GÌ: Bước giả để chạy demo trên máy ảo và để test.
// Người phụ trách: Người 1

import 'step_sensor_service.dart';

/// NGƯỜI 1. Bản giả cho chế độ demo (máy ảo không có cảm biến) và test.
/// TODO: phát số bước cộng dồn tăng dần theo thời gian (Stream.periodic).
class FakeStepSensorService implements StepSensorService {
  @override
  Stream<int> get cumulativeSteps => throw UnimplementedError();

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> hasPermission() async => true;
}
