// FILE NÀY ĐỂ LÀM GÌ: Đọc số bước thật từ cảm biến điện thoại, xin quyền.
// Người phụ trách: Người 1

import 'step_sensor_service.dart';

/// NGƯỜI 1. Bản thật đọc cảm biến bước chân Android.
/// TODO: thêm gói `pedometer` và `permission_handler` rồi cài đặt các hàm.
/// TODO: khai báo quyền ACTIVITY_RECOGNITION trong AndroidManifest.xml.
class PedometerSensorService implements StepSensorService {
  @override
  Stream<int> get cumulativeSteps => throw UnimplementedError();

  @override
  Future<bool> requestPermission() => throw UnimplementedError();

  @override
  Future<bool> hasPermission() => throw UnimplementedError();
}
