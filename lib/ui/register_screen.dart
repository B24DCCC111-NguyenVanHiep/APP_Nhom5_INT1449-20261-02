// FILE NÀY ĐỂ LÀM GÌ: Màn hình tạo tài khoản mới (chỉ cần khi muốn vào Thử thách).
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../logic/auth_controller.dart';
import 'strings.dart';
import 'widgets/state_views.dart';

/// NGƯỜI 3 (mở rộng). Form đăng ký: họ tên, email, mật khẩu (>= 8 ký tự), xác nhận.
/// Đăng ký thành công thì tự pop; AuthGate bên dưới đã đổi sang màn Thử thách.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await context.read<AuthController>().signUp(
          displayName: _name.text,
          email: _email.text,
          password: _password.text,
          confirmPassword: _confirm.text,
        );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final toggle = IconButton(
      tooltip: _obscure ? AppStrings.showPassword : AppStrings.hidePassword,
      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
      onPressed: () => setState(() => _obscure = !_obscure),
    );
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.registerTitle)),
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
                    const Text(AppStrings.registerIntro),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      enabled: !auth.busy,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      onChanged: (_) => auth.clearError(),
                      validator: AuthController.validateName,
                      decoration: _decoration(AppStrings.nameLabel, Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
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
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) => auth.clearError(),
                      validator: AuthController.validatePassword,
                      decoration: _decoration(
                        AppStrings.passwordLabel,
                        Icons.lock_outline,
                        suffix: toggle,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirm,
                      enabled: !auth.busy,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => auth.clearError(),
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => AuthController.validateConfirm(_password.text, v),
                      decoration: _decoration(AppStrings.confirmLabel, Icons.lock_reset),
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
                          : const Text(AppStrings.registerButton),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.busy ? null : () => Navigator.of(context).maybePop(),
                      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: const Text(AppStrings.goLogin),
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
