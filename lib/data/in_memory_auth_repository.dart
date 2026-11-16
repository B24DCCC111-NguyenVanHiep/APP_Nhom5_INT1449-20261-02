// FILE NÀY ĐỂ LÀM GÌ: Quản lý người dùng, đăng nhập, đăng ký giả lập trong bộ nhớ.
// Người phụ trách: Người 2 (Database)

import '../models/app_user.dart';
import 'auth_repository.dart';

class InMemoryAuthRepository implements AuthRepository {
  final Map<String, Map<String, dynamic>> _users = {};
  AppUser? _currentUser;

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();

    if (cleanName.isEmpty) {
      throw AuthException('Vui lòng nhập họ và tên');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      throw AuthException('Email không hợp lệ');
    }
    if (password.length < 6) {
      throw AuthException('Mật khẩu phải từ 6 ký tự trở lên');
    }

    if (_users.containsKey(cleanEmail)) {
      throw AuthException('Email này đã được đăng ký! Vui lòng chọn đăng nhập.');
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
    return user;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
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
    return guest;
  }

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;

  @override
  Future<void> logout() async {
    _currentUser = null;
  }
}
