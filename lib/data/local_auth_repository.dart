// FILE NÀY ĐỂ LÀM GÌ: Tài khoản ngoại tuyến: băm mật khẩu (salt + PBKDF2) và lưu bằng secure storage.
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_account.dart';
import '../ui/strings.dart';
import 'auth_repository.dart';

/// Kho khoá-giá trị đơn giản. Tách ra để test không cần plugin thật.
abstract class SecureKeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Bản thật: Keystore (Android) / Keychain (iOS) qua flutter_secure_storage.
class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Bản trong bộ nhớ cho test/demo. [data] để test kiểm tra "không lưu mật khẩu thô".
class MemoryKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> data = {};
  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async => data[key] = value;
  @override
  Future<void> delete(String key) async => data.remove(key);
}

/// NGƯỜI 3 (mở rộng). Tài khoản lưu CỤC BỘ trên máy, không cần mạng.
///
/// Bảo mật (mức đồ án, KHÔNG thay cho backend thật):
/// - Không bao giờ lưu mật khẩu thô. Mỗi tài khoản có salt ngẫu nhiên 16 byte,
///   hash = PBKDF2-HMAC-SHA256(mật khẩu, salt, [iterations] vòng). Số vòng lưu kèm
///   bản ghi để sau này tăng được mà tài khoản cũ vẫn đăng nhập được.
/// - So sánh hash bằng hàm thời gian không đổi.
/// - Sai email và sai mật khẩu cùng một thông báo (không lộ email nào đã đăng ký).
/// - Tài khoản + phiên nằm trong secure storage, KHÔNG dùng app_database.dart của Người 2.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository({
    SecureKeyValueStore? store,
    this.iterations = 10000,
    Random? random,
    DateTime Function()? clock,
  })  : _store = store ?? FlutterSecureKeyValueStore(),
        _random = random ?? Random.secure(),
        _clock = clock ?? DateTime.now;

  final int iterations;
  final SecureKeyValueStore _store;
  final Random _random;
  final DateTime Function() _clock;
  final StreamController<UserAccount?> _changes =
      StreamController<UserAccount?>.broadcast();

  static const _accountsKey = 'auth.accounts.v1';
  static const _sessionKey = 'auth.session.v1';

  @override
  Stream<UserAccount?> get authChanges => _changes.stream;

  void dispose() => _changes.close();

  @override
  Future<UserAccount> signUp({
    required String displayName,
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final key = _normalize(email);
        final accounts = await _readAccounts();
        if (accounts.containsKey(key)) {
          throw AuthException(AppStrings.authEmailTaken);
        }
        final salt = _randomBytes(16);
        final user = UserAccount(
          id: base64Url.encode(_randomBytes(12)),
          displayName: displayName.trim(),
          email: key,
          createdAt: _clock(),
        );
        accounts[key] = {
          ...user.toJson(),
          'salt': base64Encode(salt),
          'hash': base64Encode(pbkdf2(password, salt, iterations)),
          'iterations': iterations,
        };
        await _store.write(_accountsKey, jsonEncode(accounts));
        await _store.write(_sessionKey, key);
        _changes.add(user);
        return user;
      });

  @override
  Future<UserAccount> signIn({required String email, required String password}) =>
      _guard(() async {
        final key = _normalize(email);
        final accounts = await _readAccounts();
        final record = accounts[key];
        if (record is! Map<String, dynamic>) {
          throw AuthException(AppStrings.authBadCredentials);
        }
        final actual = pbkdf2(
          password,
          base64Decode(record['salt'] as String),
          record['iterations'] as int,
        );
        final expected = base64Decode(record['hash'] as String);
        if (!_constantTimeEquals(actual, expected)) {
          throw AuthException(AppStrings.authBadCredentials);
        }
        final user = UserAccount.fromJson(record);
        await _store.write(_sessionKey, key);
        _changes.add(user);
        return user;
      });

  @override
  Future<void> signOut() => _guard(() async {
        await _store.delete(_sessionKey);
        _changes.add(null);
      });

  @override
  Future<UserAccount?> currentUser() => _guard(() async {
        final key = await _store.read(_sessionKey);
        if (key == null) return null;
        final record = (await _readAccounts())[key];
        if (record is! Map<String, dynamic>) {
          await _store.delete(_sessionKey); // phiên mồ côi (tài khoản không còn)
          return null;
        }
        return UserAccount.fromJson(record);
      });

  /// PBKDF2-HMAC-SHA256, một khối 32 byte. Công khai (static) để test kiểm tra được.
  static List<int> pbkdf2(String password, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes; // U1 = HMAC(P, salt || INT(1))
    final result = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= u[j];
      }
    }
    return result;
  }

  String _normalize(String email) => email.trim().toLowerCase();

  List<int> _randomBytes(int n) => List<int>.generate(n, (_) => _random.nextInt(256));

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  Future<Map<String, dynamic>> _readAccounts() async {
    final raw = await _store.read(_accountsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  /// Lỗi nghiệp vụ giữ nguyên; lỗi lạ (hỏng JSON, plugin lỗi...) đổi thành thông báo dễ hiểu.
  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(AppStrings.authStorageError);
    }
  }
}
