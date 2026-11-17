// FILE NÀY ĐỂ LÀM GÌ: Trạng thái đăng nhập + kiểm tra dữ liệu nhập cho đăng ký/đăng nhập.
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_repository.dart';
import '../models/user_account.dart';
import '../ui/strings.dart';

enum AuthStatus { loading, unauthenticated, authenticated, error }

/// NGƯỜI 3 (mở rộng). Controller của đăng nhập; không import widget, repository truyền qua constructor.
///
/// Hai loại lỗi tách riêng để UI dễ xử lý:
/// - [status] == error + [errorMessage]: KHÔNG đọc được phiên đã lưu lúc khởi động (AuthGate hiện nút Thử lại).
/// - [formError]: lỗi của một lần bấm Đăng nhập/Đăng ký (sai mật khẩu, trùng email...), status vẫn là unauthenticated.
class AuthController extends ChangeNotifier {
  AuthController({required this.repository});

  final AuthRepository repository;

  AuthStatus status = AuthStatus.loading;
  UserAccount? user;
  String? errorMessage;
  String? formError;
  bool busy = false;

  StreamSubscription<UserAccount?>? _sub;
  bool _disposed = false;

  static const int minPasswordLength = 8;
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  // ---- Kiểm tra dữ liệu nhập (trả null nếu hợp lệ). UI dùng lại cho validator của Form. ----
  static String? validateName(String? v) =>
      (v == null || v.trim().length < 2) ? AppStrings.authNameEmpty : null;

  static String? validateEmail(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return AppStrings.authEmailEmpty;
    return _emailPattern.hasMatch(text) ? null : AppStrings.authEmailInvalid;
  }

  static String? validatePassword(String? v) =>
      (v == null || v.length < minPasswordLength) ? AppStrings.authPasswordShort : null;

  static String? validateConfirm(String? password, String? confirm) =>
      password == confirm ? null : AppStrings.authConfirmMismatch;

  // ---- Vòng đời ----

  /// Đọc phiên đã lưu rồi nghe thay đổi. Gọi lại được (nút Thử lại).
  Future<void> start() async {
    if (_disposed) return;
    final old = _sub;
    _sub = null;
    await old?.cancel(); // await đầu tiên: notify đầu không chạy đồng bộ lúc build
    if (_disposed) return;
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final current = await repository.currentUser();
      if (_disposed) return;
      _sub = repository.authChanges.listen(_apply);
      _apply(current);
    } on AuthException catch (e) {
      _startFailed(e.message);
    } catch (_) {
      _startFailed(AppStrings.authGenericError);
    }
  }

  Future<bool> signIn({required String email, required String password}) {
    final problem = validateEmail(email) ??
        (password.isEmpty ? AppStrings.authPasswordEmpty : null);
    if (problem != null) return _reject(problem);
    return _run(() => repository.signIn(email: email.trim(), password: password));
  }

  Future<bool> signUp({
    required String displayName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    final problem = validateName(displayName) ??
        validateEmail(email) ??
        validatePassword(password) ??
        validateConfirm(password, confirmPassword);
    if (problem != null) return _reject(problem);
    return _run(
      () => repository.signUp(
        displayName: displayName.trim(),
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> signOut() async {
    try {
      await repository.signOut();
      _apply(null);
    } on AuthException catch (e) {
      formError = e.message;
      notifyListeners();
    } catch (_) {
      formError = AppStrings.authGenericError;
      notifyListeners();
    }
  }

  /// Xoá lỗi form khi người dùng gõ lại. Chỉ báo UI khi thật sự có lỗi để tránh rebuild thừa.
  void clearError() {
    if (formError == null) return;
    formError = null;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    final s = _sub;
    _sub = null;
    if (s != null) unawaited(s.cancel());
    super.dispose();
  }

  // ---- Nội bộ ----

  Future<bool> _reject(String message) async {
    formError = message;
    notifyListeners();
    return false;
  }

  Future<bool> _run(Future<UserAccount> Function() action) async {
    if (busy) return false; // chặn bấm đúp
    busy = true;
    formError = null;
    notifyListeners();
    try {
      final account = await action();
      busy = false;
      _apply(account);
      return true;
    } on AuthException catch (e) {
      busy = false;
      formError = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      busy = false;
      formError = AppStrings.authGenericError;
      notifyListeners();
      return false;
    }
  }

  void _apply(UserAccount? account) {
    user = account;
    status = account == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    if (account != null) formError = null;
    notifyListeners();
  }

  void _startFailed(String message) {
    status = AuthStatus.error;
    errorMessage = message;
    notifyListeners();
  }
}
