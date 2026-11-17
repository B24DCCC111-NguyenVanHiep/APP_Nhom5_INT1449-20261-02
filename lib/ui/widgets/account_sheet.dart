// FILE NÀY ĐỂ LÀM GÌ: Bảng nhỏ hiện thông tin tài khoản và nút Đăng xuất.
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/auth_controller.dart';
import '../strings.dart';

/// NGƯỜI 3 (mở rộng). Mở từ biểu tượng tài khoản trên màn chính.
/// Chỉ đọc AuthController KHI người dùng bấm (không phải lúc dựng Home),
/// nên màn chính vẫn chạy được khi chưa có AuthController.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const _AccountSheet(),
  );
}

class _AccountSheet extends StatelessWidget {
  const _AccountSheet();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.user;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.accountTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (user != null) ...[
              Text(user.displayName, style: Theme.of(context).textTheme.titleMedium),
              Text(user.email),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await auth.signOut();
                  navigator.pop();
                },
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                icon: const Icon(Icons.logout_rounded),
                label: const Text(AppStrings.signOut),
              ),
            ] else ...[
              const Text(AppStrings.accountGuestInfo),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: const Text(AppStrings.close),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
