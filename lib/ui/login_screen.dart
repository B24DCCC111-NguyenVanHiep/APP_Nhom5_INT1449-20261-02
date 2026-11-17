// FILE NÀY ĐỂ LÀM GÌ: Màn hình đăng nhập (hiện khi vào Thử thách mà chưa có tài khoản).
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/auth_controller.dart';
import 'register_screen.dart';
import 'strings.dart';
import 'widgets/state_views.dart';

/// NGƯỜI 3 (mở rộng). Form đăng nhập. Không chứa logic nghiệp vụ: kiểm tra dữ liệu
/// dùng hàm tĩnh của AuthController, đăng nhập gọi controller.signIn.
/// Có lối thoát "Dùng thử không cần tài khoản" để về màn chính.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Thành công thì AuthGate tự đổi sang màn Thử thách, không cần điều hướng ở đây.
    await context.read<AuthController>().signIn(
          email: _email.text,
          password: _password.text,
        );
  }

  void _openRegister() {
    context.read<AuthController>().clearError();
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.loginTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(AppStrings.loginIntro),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      enabled: !auth.busy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      onChanged: (_) => auth.clearError(),
                      validator: AuthController.validateEmail,
                      decoration: _decoration(AppStrings.emailLabel, Icons.mail_outline),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !auth.busy,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onChanged: (_) => auth.clearError(),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? AppStrings.authPasswordEmpty : null,
                      decoration: _decoration(
                        AppStrings.passwordLabel,
                        Icons.lock_outline,
                        suffix: IconButton(
                          tooltip: _obscure
                              ? AppStrings.showPassword
                              : AppStrings.hidePassword,
                          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    if (auth.formError != null) ...[
                      const SizedBox(height: 16),
                      InlineErrorBanner(message: auth.formError!),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      child: auth.busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.loginButton),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.busy ? null : _openRegister,
                      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text(AppStrings.goRegister),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text(AppStrings.guestButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffix,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
  );
}
