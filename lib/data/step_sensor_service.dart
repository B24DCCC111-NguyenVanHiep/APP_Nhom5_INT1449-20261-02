// FILE NÀY ĐỂ LÀM GÌ: Quy ước chung: cách lấy số bước từ cảm biến. Muốn đổi phải báo cả nhóm.
// Người phụ trách: Cả nhóm

/// HỢP ĐỒNG (nhóm trưởng sở hữu). Chỉ đổi khi cả nhóm đồng ý.
///
/// Nguồn bước chân. Bản thật: PedometerSensorService (người 1).
/// Bản giả: FakeStepSensorService (demo + test).
abstract class StepSensorService {
  /// Số bước CỘNG DỒN từ lúc máy khởi động (giống cảm biến Android).
  /// Có thể bị reset về nhỏ hơn khi máy khởi động lại.
  Stream<int> get cumulativeSteps;

  /// Xin quyền ACTIVITY_RECOGNITION. Trả về true nếu được cấp.
  Future<bool> requestPermission();

  /// Quyền đã được cấp chưa (không bật hộp thoại).
  Future<bool> hasPermission();
}
