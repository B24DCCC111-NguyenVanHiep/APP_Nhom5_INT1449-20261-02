// FILE NÀY ĐỂ LÀM GÌ: Ba giao diện dùng chung: đang tải, lỗi, chưa có dữ liệu.
// Người phụ trách: Người 3

import 'package:flutter/material.dart';

/// NGƯỜI 3. Ba trạng thái bắt buộc của rubric, dùng chung cho mọi màn hình.
/// TODO: mỗi trạng thái có lối ra (nút bấm), vùng chạm >= 48dp.

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: Text('TODO'));
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });
  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => const Center(child: Text('TODO'));
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.hint});
  final String message;
  final String? hint;
  @override
  Widget build(BuildContext context) => const Center(child: Text('TODO'));
}
