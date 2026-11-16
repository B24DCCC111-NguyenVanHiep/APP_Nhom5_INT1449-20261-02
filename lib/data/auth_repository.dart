// FILE NÀY ĐỂ LÀM GÌ: Quy ước chung: quản lý tài khoản, đăng nhập, đăng ký và phiên làm việc.
// Người phụ trách: Người 2 (Database)

import '../models/app_user.dart';

abstract class AuthRepository {
  /// Đăng ký tài khoản mới. Trả về [AppUser] vừa tạo và tự động lưu phiên đăng nhập.
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  /// Đăng nhập bằng email và mật khẩu. Trả về [AppUser] và lưu phiên đăng nhập.
  Future<AppUser> login({
    required String email,
    required String password,
  });

  /// Đăng nhập dưới dạng Khách (Guest) không cần tài khoản.
  Future<AppUser> loginAsGuest();

  /// Lấy thông tin người dùng đang đăng nhập trong phiên hiện tại (nếu có).
  Future<AppUser?> getCurrentUser();

  /// Đăng xuất: xoá phiên người dùng hiện tại.
  Future<void> logout();
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}
