// FILE NÀY ĐỂ LÀM GÌ: Bước giả để chạy demo trên máy ảo và để test.
// Người phụ trách: Người 1

import 'step_sensor_service.dart';

class FakeStepSensorService implements StepSensorService {
  FakeStepSensorService({
    this.interval = const Duration(seconds: 1),
    this.stepsPerTick = 5,
    int initialSteps = 0,
    this.permissionGranted = true,
  })  : assert(stepsPerTick > 0, 'stepsPerTick phải lớn hơn 0'),
        assert(initialSteps >= 0, 'initialSteps không được âm'),
        _scripted = null,
        _total = initialSteps;

  FakeStepSensorService.scripted(
    List<int> values, {
    this.permissionGranted = true,
  })  : interval = Duration.zero,
        stepsPerTick = 0,
        _scripted = List<int>.unmodifiable(values),
        _total = 0;

  final Duration interval;
  final int stepsPerTick;
  final bool permissionGranted;
  final List<int>? _scripted;

  int _total;

  int get currentSteps => _total;

  void simulateReboot() => _total = 0;

  @override
  Stream<int> get cumulativeSteps {
    final values = _scripted;
    if (values != null) return Stream<int>.fromIterable(values);
    return Stream<int>.periodic(interval, (_) => _total += stepsPerTick);
  }

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<bool> hasPermission() async => permissionGranted;
}
