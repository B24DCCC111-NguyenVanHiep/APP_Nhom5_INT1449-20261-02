// FILE NÀY ĐỂ LÀM GÌ: Bộ não màn chính: nhận bước từ cảm biến, lưu lại, báo giao diện cập nhật.
// Người phụ trách: Người 3

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/step_repository.dart';
import '../data/step_sensor_service.dart';
import '../models/daily_steps.dart';
import '../services/notification_service.dart';
import '../ui/strings.dart';
import 'step_calculator.dart';

enum StepsStatus { loading, noPermission, error, ready }

/// Ném ra khi mục tiêu ngoài khoảng cho phép. [message] là tiếng Việt, đưa thẳng lên UI.
class InvalidGoalException implements Exception {
  InvalidGoalException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// NGƯỜI 3. Nối sensor + repository + notifier, cung cấp trạng thái cho UI.
/// Mọi phụ thuộc truyền qua constructor để thay bằng bản giả khi test.
///
/// Thiết kế chính:
/// - Mỗi giá trị cảm biến đi qua một HÀNG ĐỢI (chuỗi Future) nên các lần đọc-sửa-ghi
///   trên repository chạy lần lượt, không đè nhau khi bước đến dồn dập.
/// - "Hôm nay" được tính lại MỖI lần nhận giá trị (qua [_clock]) vì app có thể mở qua nửa đêm.
/// - Controller không import widget; lỗi đổi thành chuỗi tiếng Việt, không lộ stack trace.
class StepsController extends ChangeNotifier {
  StepsController({
    required this.sensor,
    required this.repository,
    required this.notifier,
    this.calculator = const StepCalculator(),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final StepSensorService sensor;
  final StepRepository repository;
  final GoalNotifier notifier;
  final StepCalculator calculator;
  final DateTime Function() _clock; // thay được trong test để giả lập qua nửa đêm

  static const int minGoal = 1;
  static const int maxGoal = 100000;

  // Hằng số ƯỚC TÍNH (không phải số đo thật): bước trung bình người lớn.
  static const double kmPerStep = 0.0007;
  static const double kcalPerStep = 0.04;
  static const int stepsPerMinute = 100;

  StepsStatus status = StepsStatus.loading;
  String? errorMessage;
  int todaySteps = 0;
  int goal = 8000;

  StreamSubscription<int>? _sub;
  Future<void> _queue = Future<void>.value();
  bool _disposed = false;

  // ---- Getter cho UI ----
  double get progress => calculator.progress(todaySteps, goal);
  int get percent => (progress * 100).round();
  int get remainingSteps => goal > todaySteps ? goal - todaySteps : 0;
  bool get isEmptyToday => todaySteps == 0;
  double get estimatedKm => todaySteps * kmPerStep;
  double get estimatedKcal => todaySteps * kcalPerStep;
  int get estimatedMinutes => (todaySteps / stepsPerMinute).round();

  /// Trả về thông báo lỗi tiếng Việt nếu [value] không hợp lệ, ngược lại null.
  /// UI dùng chung hàm này để báo lỗi ngay khi gõ, controller dùng để chặn khi lưu.
  static String? validateGoal(int value) =>
      (value < minGoal || value > maxGoal) ? AppStrings.goalOutOfRange : null;

  // ---- Vòng đời ----

  /// Đọc mục tiêu + bước hôm nay, kiểm tra quyền, rồi nghe cảm biến.
  /// Gọi lại được (retry): huỷ lần nghe cũ trước. Lệnh `await` đầu tiên bảo đảm
  /// notifyListeners đầu tiên không chạy đồng bộ trong lúc đang build.
  Future<void> start() async {
    if (_disposed) return;
    await _stopListening();
    if (_disposed) return;
    status = StepsStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final loadedGoal = await repository.getGoal();
      final today = await repository.getDay(_today());
      final granted = await sensor.hasPermission();
      if (_disposed) return;
      goal = loadedGoal;
      todaySteps = today?.steps ?? 0;
      if (!granted) {
        status = StepsStatus.noPermission;
        notifyListeners();
        return;
      }
      _listen();
      status = StepsStatus.ready;
      notifyListeners();
    } on StepRepositoryException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail(AppStrings.errorLoad);
    }
  }

  /// Nút "Cấp quyền" trên UI. Được cấp thì chạy [start]; từ chối thì ở lại noPermission.
  Future<void> requestPermissionAndStart() async {
    if (_disposed) return;
    bool granted;
    try {
      granted = await sensor.requestPermission();
    } catch (_) {
      _fail(AppStrings.errorSensor);
      return;
    }
    if (_disposed) return;
    if (!granted) {
      status = StepsStatus.noPermission;
      errorMessage = AppStrings.permissionDenied;
      notifyListeners();
      return;
    }
    await start();
  }

  Future<void> retry() => start();

  /// Đặt mục tiêu. Giá trị sai -> [InvalidGoalException]; lỗi lưu -> [StepRepositoryException]
  /// (để màn Mục tiêu báo lỗi tại chỗ, KHÔNG làm cả màn chính chuyển sang trạng thái lỗi).
  Future<void> setGoal(int value) async {
    final problem = validateGoal(value);
    if (problem != null) throw InvalidGoalException(problem);
    await repository.setGoal(value);
    goal = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    // Sự kiện đang bay dở có thể về sau dispose: bỏ qua thay vì ném lỗi.
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    final s = _sub;
    _sub = null;
    if (s != null) unawaited(s.cancel());
    super.dispose();
  }

  // ---- Nội bộ ----

  DateTime _today() => DailySteps.dayOf(_clock());

  void _listen() {
    _sub = sensor.cumulativeSteps.listen(
      (value) {
        // Nối vào hàng đợi: sự kiện sau chỉ chạy khi sự kiện trước xong.
        _queue = _queue.then((_) => _onSensorValue(value));
      },
      onError: (Object _) {
        _queue = _queue.then((_) => _fail(AppStrings.errorSensor));
      },
    );
  }

  Future<void> _stopListening() async {
    final s = _sub;
    _sub = null;
    await s?.cancel();
  }

  /// Không bao giờ ném ra ngoài (hàng đợi sẽ hỏng nếu ném): mọi lỗi đổi thành status=error.
  Future<void> _onSensorValue(int value) async {
    if (_disposed || _sub == null) return;
    try {
      final last = await repository.getLastSensorValue();
      final d = calculator.delta(last, value);
      // Ghi mốc cảm biến TRƯỚC khi cộng bước: nếu bước sau lỗi thì tệ nhất là mất vài bước,
      // còn hơn đếm trùng làm số bước bị phồng lên.
      await repository.setLastSensorValue(value);

      final today = _today(); // xác định ngày MỖI lần nhận (có thể đã qua nửa đêm)
      final saved = await repository.getDay(today);
      var total = saved?.steps ?? 0;
      if (d > 0) {
        total += d;
        await repository.saveDay(DailySteps(today, total));
      }
      todaySteps = total; // sang ngày mới thì tự về số của ngày mới

      await _notifyIfGoalReached(today, total);

      if (_disposed) return;
      notifyListeners();
    } on StepRepositoryException catch (e) {
      _fail(e.message);
    } catch (_) {
      _fail(AppStrings.errorSave);
    }
  }

  Future<void> _notifyIfGoalReached(DateTime today, int total) async {
    if (!calculator.reachedGoal(total, goal)) return;
    final notified = await repository.getLastGoalNotifiedDay();
    if (notified != null && DailySteps.dayOf(notified) == today) return;
    try {
      await notifier.showGoalReached(total);
    } catch (_) {
      // Thông báo hỏng (vd chưa cấp quyền) không được làm dừng việc đếm bước.
      // Không đánh dấu "đã báo" để lần sau còn thử lại.
      return;
    }
    await repository.setLastGoalNotifiedDay(today);
  }

  void _fail(String message) {
    final s = _sub;
    _sub = null;
    if (s != null) unawaited(s.cancel());
    if (_disposed) return;
    status = StepsStatus.error;
    errorMessage = message;
    notifyListeners();
  }
}
