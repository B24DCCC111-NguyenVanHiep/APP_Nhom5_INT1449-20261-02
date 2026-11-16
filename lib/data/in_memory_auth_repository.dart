// FILE NÀY ĐỂ LÀM GÌ: Quản lý người dùng, đăng nhập, đăng ký giả lập trong bộ nhớ và web storage.
// Người phụ trách: Người 2 (Database)

import 'dart:convert';

import '../models/app_user.dart';
import 'auth_repository.dart';
import 'web_storage.dart';

class InMemoryAuthRepository implements AuthRepository {
  InMemoryAuthRepository({bool clear = false}) {
    if (clear) {
      _users.clear();
      _currentUser = null;
      _saveToStorage();
    } else {
      _loadFromStorage();
    }
  }

  static final Map<String, Map<String, dynamic>> _users = {};
  static AppUser? _currentUser;
  static bool _initialized = false;

  static void _loadFromStorage() {
    if (_initialized) return;
    _initialized = true;
    try {
      final saved = getWebStorage('step_tracker_users');
      if (saved != null && saved.isNotEmpty) {
        final decoded = jsonDecode(saved) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _users[entry.key] = Map<String, dynamic>.from(entry.value as Map);
        }
      }
      final session = getWebStorage('step_tracker_session');
      if (session != null && session.isNotEmpty) {
        _currentUser =
            AppUser.fromJson(jsonDecode(session) as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  static void _saveToStorage() {
    try {
      setWebStorage('step_tracker_users', jsonEncode(_users));
      if (_currentUser != null) {
        setWebStorage(
          'step_tracker_session',
          jsonEncode(_currentUser!.toJson()),
        );
      } else {
        removeWebStorage('step_tracker_session');
      }
    } catch (_) {}
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _loadFromStorage();
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw AuthException('Vui lòng nhập họ và tên');
    }
    if (cleanEmail.isEmpty ||
        !cleanEmail.contains('@') ||
        !cleanEmail.contains('.')) {
      throw AuthException('Email không hợp lệ');
    }
    if (password.length < 6) {
      throw AuthException('Mật khẩu phải từ 6 ký tự trở lên');
    }

    if (_users.containsKey(cleanEmail)) {
      throw AuthException(
          'Email này đã được đăng ký! Vui lòng chọn đăng nhập.');
    }

    final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _users[cleanEmail] = {
      'id': id,
      'name': cleanName,
      'email': cleanEmail,
      'password': password,
    };

    final user = AppUser(
      id: id,
      name: cleanName,
      email: cleanEmail,
      isGuest: false,
    );
    _currentUser = user;
    _saveToStorage();
    return user;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    _loadFromStorage();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanEmail.isEmpty) {
      throw AuthException('Vui lòng nhập email');
    }
    if (password.isEmpty) {
      throw AuthException('Vui lòng nhập mật khẩu');
    }

    if (!_users.containsKey(cleanEmail)) {
      throw AuthException('Tài khoản email này chưa được đăng ký!');
    }

    final data = _users[cleanEmail]!;
    if (data['password'] != password) {
      throw AuthException('Mật khẩu không chính xác!');
    }

    final user = AppUser(
      id: data['id'] as String,
      name: data['name'] as String,
      email: cleanEmail,
      isGuest: false,
    );
    _currentUser = user;
    _saveToStorage();
    return user;
  }

  @override
  Future<AppUser> loginAsGuest() async {
    final guest = AppUser(
      id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Khách',
      email: '',
      isGuest: true,
    );
    _currentUser = guest;
    _saveToStorage();
    return guest;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    _loadFromStorage();
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    _saveToStorage();
  }
}
