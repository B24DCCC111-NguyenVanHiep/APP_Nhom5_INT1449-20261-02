// FILE NÀY ĐỂ LÀM GÌ: Gốc ứng dụng: tạo các đối tượng chung và chuyển cho các màn hình dùng.
// Người phụ trách: Người 5

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/fake_step_sensor_service.dart';
import 'data/friends_repository.dart';
import 'data/in_memory_step_repository.dart';
import 'data/step_repository.dart';
import 'data/step_sensor_service.dart';
import 'logic/steps_controller.dart';
import 'services/notification_service.dart';
import 'ui/auth_screen.dart';

/// NGƯỜI 5. Gốc ứng dụng và nơi DUY NHẤT chọn bản thật hay bản giả.
class StepTrackerApp extends StatelessWidget {
  const StepTrackerApp({
    super.key,
    this.sensor,
    this.repository,
    this.notifier,
    this.friendsRepository,
    this.controller,
  });

  final StepSensorService? sensor;
  final StepRepository? repository;
  final GoalNotifier? notifier;
  final FriendsRepository? friendsRepository;
  final StepsController? controller;

  @override
  Widget build(BuildContext context) {
    final actualSensor = sensor ?? FakeStepSensorService();
    final actualRepository = repository ?? InMemoryStepRepository();
    final actualNotifier = notifier ?? FakeGoalNotifier();
    final actualFriendsRepo = friendsRepository ?? FakeFriendsRepository();

    return MultiProvider(
      providers: [
        Provider<StepSensorService>.value(value: actualSensor),
        Provider<StepRepository>.value(value: actualRepository),
        Provider<GoalNotifier>.value(value: actualNotifier),
        Provider<FriendsRepository>.value(value: actualFriendsRepo),
        ChangeNotifierProvider<StepsController>(
          create: (_) {
            if (controller != null) return controller!;
            final c = StepsController(
              sensor: actualSensor,
              repository: actualRepository,
              notifier: actualNotifier,
            );
            try {
              c.start();
            } catch (_) {}
            return c;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Theo dõi bước chân',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
        ),
        // Mở app đầu tiên là vào màn hình Đăng nhập / Đăng ký (kèm nút Dùng ở dạng khách)
        home: const AuthScreen(),
      ),
    );
  }
}
