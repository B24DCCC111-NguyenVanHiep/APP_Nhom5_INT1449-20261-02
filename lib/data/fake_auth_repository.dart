// FILE NÀY ĐỂ LÀM GÌ: Bản tài khoản giả trong bộ nhớ cho test và chế độ demo.
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'dart:async';

import '../models/user_account.dart';
import '../ui/strings.dart';
import 'auth_repository.dart';

/// NGƯỜI 3 (mở rộng). Chỉ dùng cho test/demo: mật khẩu giữ trong RAM, KHÔNG dùng cho bản thật.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({UserAccount? signedIn}) : _current = signedIn;

  final Map<String, _Entry> _accounts = {};
  final StreamController<UserAccount?> _changes =
      StreamController<UserAccount?>.broadcast();
  UserAccount? _current;
  int _nextId = 1;

  /// Đếm số lần gọi để test xác nhận "dữ liệu sai không chạm tới repository".
  int signUpCalls = 0;
  int signInCalls = 0;

  /// Bật để giả lập kho lưu hỏng.
  bool failWithStorageError = false;

  void dispose() => _changes.close();

  @override
  Stream<UserAccount?> get authChanges => _changes.stream;

  @override
  Future<UserAccount?> currentUser() async {
    _maybeFail();
    return _current;
  }

  @override
  Future<UserAccount> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    signUpCalls++;
    _maybeFail();
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) throw AuthException(AppStrings.authEmailTaken);
    final user = UserAccount(
      id: 'fake-${_nextId++}',
      displayName: displayName.trim(),
      email: key,
      createdAt: DateTime(2026, 1, 1),
    );
    _accounts[key] = _Entry(user, password);
    _current = user;
    _changes.add(user);
    return user;
  }

  @override
  Future<UserAccount> signIn({required String email, required String password}) async {
    signInCalls++;
    _maybeFail();
    final entry = _accounts[email.trim().toLowerCase()];
    if (entry == null || entry.password != password) {
      throw AuthException(AppStrings.authBadCredentials);
    }
    _current = entry.user;
    _changes.add(entry.user);
    return entry.user;
  }

  @override
  Future<void> signOut() async {
    _maybeFail();
    _current = null;
    _changes.add(null);
  }

  void _maybeFail() {
    if (failWithStorageError) throw AuthException(AppStrings.authStorageError);
  }
}

class _Entry {
  _Entry(this.user, this.password);
  final UserAccount user;
  final String password;
}
