// FILE NÀY ĐỂ LÀM GÌ: Gửi thông báo khi người dùng đạt mục tiêu bước chân.
// Người phụ trách: Người 5

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// NGƯỜI 5. Thông báo cục bộ khi đạt mục tiêu.
abstract class GoalNotifier {
  Future<void> init();
  Future<bool> requestPermission();
  Future<void> showGoalReached(int steps);
}

class LocalGoalNotifier implements GoalNotifier {
  LocalGoalNotifier({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await init();
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      return granted ?? false;
    }

    final darwinImpl = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (darwinImpl != null) {
      final granted = await darwinImpl.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  @override
  Future<void> showGoalReached(int steps) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'step_tracker_goal_channel',
      'Mục tiêu bước chân',
      channelDescription: 'Thông báo chúc mừng khi hoàn thành mục tiêu ngày',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      1001,
      'Tuyệt vời! Đã đạt mục tiêu 🎉',
      'Chúc mừng bạn đã hoàn thành $steps bước hôm nay!',
      notificationDetails,
    );
  }
}

/// Bản giả cho test và demo.
class FakeGoalNotifier implements GoalNotifier {
  int shown = 0;
  int? lastNotifiedSteps;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> showGoalReached(int steps) async {
    shown++;
    lastNotifiedSteps = steps;
  }
}
