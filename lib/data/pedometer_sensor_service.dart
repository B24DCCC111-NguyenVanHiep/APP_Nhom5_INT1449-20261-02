// FILE NÀY ĐỂ LÀM GÌ: Đọc số bước thật từ cảm biến điện thoại, xin quyền.
// Người phụ trách: Người 1

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import 'step_sensor_service.dart';

class StepSensorException implements Exception {
  StepSensorException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PedometerSensorService implements StepSensorService {
  PedometerSensorService({
    Stream<StepCount> Function()? stepCountStream,
    Future<PermissionStatus> Function()? checkPermission,
    Future<PermissionStatus> Function()? askPermission,
    bool? isSupported,
  })  : _stepCountStream = stepCountStream ?? _defaultStepCountStream,
        _checkPermission = checkPermission ?? _defaultCheckPermission,
        _askPermission = askPermission ?? _defaultAskPermission,
        _isSupported = isSupported ?? !kIsWeb;

  final Stream<StepCount> Function() _stepCountStream;
  final Future<PermissionStatus> Function() _checkPermission;
  final Future<PermissionStatus> Function() _askPermission;
  final bool _isSupported;

  static Stream<StepCount> _defaultStepCountStream() =>
      Pedometer.stepCountStream;

  static Permission get _permission =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? Permission.sensors
          : Permission.activityRecognition;

  static Future<PermissionStatus> _defaultCheckPermission() =>
      _permission.status;

  static Future<PermissionStatus> _defaultAskPermission() =>
      _permission.request();

  /// Số bước cộng dồn từ lúc máy khởi động. Lỗi của plugin được đổi thành
  /// [StepSensorException] để tầng trên chỉ cần bắt một loại lỗi.
  @override
  Stream<int> get cumulativeSteps {
    if (!_isSupported) {
      return Stream<int>.error(
        StepSensorException(
          'Thiết bị này không có cảm biến bước chân. '
          'Hãy chạy chế độ demo hoặc dùng điện thoại Android.',
        ),
      );
    }
    return _stepCountStream().map((event) => event.steps).transform(
      StreamTransformer<int, int>.fromHandlers(
        handleError: (error, stackTrace, sink) {
          sink.addError(
            StepSensorException(
              'Không đọc được cảm biến bước chân. '
              'Máy có thể không có cảm biến hoặc chưa cấp quyền.',
            ),
            stackTrace,
          );
        },
      ),
    );
  }

  @override
  Future<bool> requestPermission() async {
    if (!_isSupported) return false;
    try {
      final status = await _askPermission();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> hasPermission() async {
    if (!_isSupported) return false;
    try {
      final status = await _checkPermission();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPermanentlyDenied() async {
    if (!_isSupported) return false;
    try {
      final status = await _checkPermission();
      return status.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openSettings() async {
    if (!_isSupported) return false;
    try {
      return await openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
