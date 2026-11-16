// FILE NÀY ĐỂ LÀM GÌ: Màn hình Đăng nhập / Đăng ký tài khoản cục bộ (Offline).
// Người phụ trách: Người 5 & Người 2

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../data/auth_repository.dart';
import '../data/in_memory_auth_repository.dart';
import '../data/sqlite_auth_repository.dart';
import '../models/app_user.dart';
import 'home_screen.dart';

export '../data/auth_repository.dart';
export '../models/app_user.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.allowGuest = true,
    this.authRepository,
    this.onAuthenticated,
  });

  final bool allowGuest;
  final AuthRepository? authRepository;
  final ValueChanged<AppUser>? onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true; // true: Đăng nhập, false: Đăng ký
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AuthRepository? _internalRepo;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<AuthRepository> _getRepo() async {
    if (widget.authRepository != null) return widget.authRepository!;
    if (_internalRepo != null) return _internalRepo!;
    if (kIsWeb) {
      _internalRepo = InMemoryAuthRepository();
      return _internalRepo!;
    }
    try {
      final db = await AppDatabase.open();
      _internalRepo = SqliteAuthRepository(db);
      return _internalRepo!;
    } catch (_) {
      _internalRepo = InMemoryAuthRepository();
      return _internalRepo!;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      final repo = await _getRepo();
      final AppUser user;

      if (_isLogin) {
        user = await repo.login(email: email, password: password);
      } else {
        user = await repo.register(
          name: name,
          email: email,
          password: password,
        );
      }

      _finishAuth(user);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Đã có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Nút bấm: Dùng ở dạng khách
  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      final repo = await _getRepo();
      final guest = await repo.loginAsGuest();
      _finishAuth(guest);
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('Đã có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _finishAuth(AppUser user) {
    if (!mounted) return;
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!(user);
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(user);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      );
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: canPop
          ? AppBar(
              title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  const Icon(
                    Icons.directions_walk_rounded,
                    size: 80,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),

                  // Tiêu đề
                  Text(
                    'Step Tracker',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isLogin
                        ? 'Đăng nhập để lưu tiến trình và thi đấu'
                        : 'Tạo tài khoản theo dõi bước chân',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // Ô Tên (khi đăng ký)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập họ và tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Ô Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!val.contains('@') || !val.contains('.')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Ô Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      if (val.length < 6) {
                        return 'Mật khẩu phải từ 6 ký tự trở lên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Xác nhận mật khẩu (khi đăng ký)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Xác nhận mật khẩu',
                        prefixIcon: Icon(Icons.lock_reset),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val != _passwordController.text) {
                          return 'Mật khẩu xác nhận không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // Nút Đăng nhập / Đăng ký (Vùng chạm >= 48dp)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isLogin ? 'Đăng nhập' : 'Đăng ký tài khoản',
                            style: const TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Đổi qua lại Đăng nhập / Đăng ký (Vùng chạm >= 48dp)
                  TextButton(
                    style: TextButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isLogin
                          ? 'Chưa có tài khoản? Đăng ký ngay'
                          : 'Đã có tài khoản? Đăng nhập',
                    ),
                  ),

                  // NÚT BẤM: DÙNG Ở DẠNG KHÁCH (chỉ hiện khi cho phép khách)
                  if (widget.allowGuest) ...[
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'HOẶC',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: BorderSide(
                          color: Colors.green.shade700,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _continueAsGuest,
                      icon: const Icon(
                        Icons.person_outline,
                        color: Colors.green,
                      ),
                      label: Text(
                        'Dùng ở dạng khách',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
