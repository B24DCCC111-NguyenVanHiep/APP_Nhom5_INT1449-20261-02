// FILE NÀY ĐỂ LÀM GÌ: Màn hình chính: số bước và vòng tròn tiến độ.
// Người phụ trách: Người 3

import 'package:flutter/material.dart';

/// NGƯỜI 3. Màn hình chính.
/// TODO: vòng tròn tiến độ, số bước hôm nay / mục tiêu.
/// TODO: đủ 3 trạng thái: đang tải, lỗi (có nút Thử lại/Cấp quyền), chưa có dữ liệu.
/// TODO: nút điều hướng sang biểu đồ, bạn bè, đặt mục tiêu (vùng chạm >= 48dp).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bước chân')),
      body: const Center(child: Text('TODO: người 3')),
    );
  }
}
