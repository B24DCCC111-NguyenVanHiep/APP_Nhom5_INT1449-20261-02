// FILE NÀY ĐỂ LÀM GÌ: Màn hình Đăng nhập / Đăng ký tài khoản cục bộ (Offline).
// Người phụ trách: Người 5

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'home_screen.dart';

/// Thông tin người dùng
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.isGuest = false,
  });

  final String id;
  final String name;
  final String email;
  final bool isGuest;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'isGuest': isGuest,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? 'guest_id',
        name: json['name'] as String? ?? 'Khách',
        email: json['email'] as String? ?? '',
        isGuest: json['isGuest'] as bool? ?? false,
      );
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.allowGuest = true,
    this.onAuthenticated,
  });

  final bool allowGuest;
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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<File?> _getAccountsFile() async {
    try {
      final dbPath = await getDatabasesPath();
      return File(p.join(dbPath, 'user_accounts.json'));
    } catch (_) {
      return null;
    }
  }

  Future<File?> _getSessionFile() async {
    try {
      final dbPath = await getDatabasesPath();
      return File(p.join(dbPath, 'user_profile.json'));
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _readAccounts() async {
    try {
      final file = await _getAccountsFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          return jsonDecode(content) as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _saveSession(AppUser user) async {
    try {
      final file = await _getSessionFile();
      if (file == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(user.toJson()));
    } catch (_) {}
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      final accounts = await _readAccounts();

      if (_isLogin) {
        // --- ĐĂNG NHẬP ---
        if (!accounts.containsKey(email)) {
          _showError('Tài khoản email này chưa được đăng ký!');
          return;
        }

        final userData = accounts[email] as Map<String, dynamic>;
        if (userData['password'] != password) {
          _showError('Mật khẩu không chính xác!');
          return;
        }

        final user = AppUser(
          id: userData['id'] as String? ??
              'user_${DateTime.now().millisecondsSinceEpoch}',
          name: userData['name'] as String? ?? 'Người dùng',
          email: email,
          isGuest: false,
        );

        await _saveSession(user);
        _finishAuth(user);
      } else {
        // --- ĐĂNG KÝ ---
        if (accounts.containsKey(email)) {
          _showError('Email này đã tồn tại! Vui lòng chọn đăng nhập.');
          return;
        }

        final newId = 'user_${DateTime.now().millisecondsSinceEpoch}';
        accounts[email] = {
          'id': newId,
          'name': name,
          'password': password,
          'created_at': DateTime.now().toIso8601String(),
        };

        final file = await _getAccountsFile();
        if (file != null) {
          await file.parent.create(recursive: true);
          await file.writeAsString(jsonEncode(accounts));
        }

        final user =
            AppUser(id: newId, name: name, email: email, isGuest: false);
        await _saveSession(user);
        _finishAuth(user);
      }
    } catch (e) {
      _showError('Đã có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Nút bấm: Dùng ở dạng khách
  Future<void> _continueAsGuest() async {
    final guest = AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Khách',
      email: '',
      isGuest: true,
    );
    await _saveSession(guest);
    _finishAuth(guest);
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
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
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
                          child: Text('HOẶC',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: BorderSide(
                            color: Colors.green.shade700, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _continueAsGuest,
                      icon:
                          const Icon(Icons.person_outline, color: Colors.green),
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
