// FILE NÀY ĐỂ LÀM GÌ: Màn hình biểu đồ 7 ngày và 30 ngày.
// Người phụ trách: Người 4

import 'package:flutter/material.dart';

/// NGƯỜI 4. Biểu đồ bước chân theo ngày.
/// TODO: thêm gói `fl_chart`; chuyển 7 ngày / 30 ngày.
/// TODO: đủ 3 trạng thái (dùng widgets/state_views.dart của người 3).
/// TODO: không gọi database trong build(); tải dữ liệu trong initState.
class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Biểu đồ')),
      body: const Center(child: Text('TODO: người 4')),
    );
  }
}
