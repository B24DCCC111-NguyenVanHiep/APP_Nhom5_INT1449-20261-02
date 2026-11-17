// FILE NÀY ĐỂ LÀM GÌ: Cổng chặn: chưa đăng nhập thì hiện đăng nhập, đã đăng nhập thì hiện màn con.
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../logic/auth_controller.dart';
import '../login_screen.dart';
import '../strings.dart';
import 'state_views.dart';

/// NGƯỜI 3 (mở rộng). Bọc quanh màn cần tài khoản (chỉ màn Thử thách).
/// Vì cổng nằm TRONG route đã mở, đăng nhập xong nó tự đổi sang [child]
/// nên người dùng quay lại đúng màn Thử thách mà không cần điều hướng thêm.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    switch (auth.status) {
      case AuthStatus.authenticated:
        return child;
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.loading:
        return const Scaffold(body: SafeArea(child: LoadingView()));
      case AuthStatus.error:
        return Scaffold(
          appBar: AppBar(),
          body: SafeArea(
            child: ErrorView(
              message: auth.errorMessage ?? AppStrings.authGenericError,
              actionLabel: AppStrings.retry,
              onAction: auth.start,
            ),
          ),
        );
    }
  }
}
