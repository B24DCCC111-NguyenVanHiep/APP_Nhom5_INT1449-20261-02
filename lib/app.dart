// FILE NÀY ĐỂ LÀM GÌ: Gốc ứng dụng: tạo các đối tượng chung và chuyển cho các màn hình dùng.
// Người phụ trách: Người 5

import 'package:flutter/material.dart';

import 'ui/auth_screen.dart';

/// NGƯỜI 5. Gốc ứng dụng và nơi DUY NHẤT chọn bản thật hay bản giả.
/// TODO: thêm gói `provider`; tạo StepsController, truyền sensor, repository,
/// notifier, friends vào constructor của StepTrackerApp rồi cung cấp bằng
/// MultiProvider.
class StepTrackerApp extends StatelessWidget {
  const StepTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theo dõi bước chân',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const AuthScreen(),
    );
  }
}
