// FILE NÀY ĐỂ LÀM GÌ: Hợp đồng đăng ký/đăng nhập; UI chỉ biết giao diện này.
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import '../models/user_account.dart';

/// Giao diện trừu tượng để sau này thay LocalAuthRepository bằng Firebase Auth
/// hoặc backend riêng mà KHÔNG phải sửa màn hình hay AuthController.
abstract class AuthRepository {
  Future<UserAccount> signUp({
    required String displayName,
    required String email,
    required String password,
  });

  Future<UserAccount> signIn({required String email, required String password});

  Future<void> signOut();

  /// Người đang đăng nhập (đọc từ phiên đã lưu), null nếu chưa đăng nhập.
  Future<UserAccount?> currentUser();

  /// Phát người dùng mới mỗi khi đăng nhập/đăng ký (UserAccount) hoặc đăng xuất (null).
  Stream<UserAccount?> get authChanges;
}

/// Lỗi nghiệp vụ của đăng nhập. [message] là tiếng Việt, hiển thị thẳng cho người dùng.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
