// FILE NÀY ĐỂ LÀM GÌ: Quản lý người dùng, đăng nhập, đăng ký bằng SQLite.
// Người phụ trách: Người 2 (Database)

import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import 'app_database.dart';
import 'auth_repository.dart';

class SqliteAuthRepository implements AuthRepository {
  SqliteAuthRepository(this._db);

  final AppDatabase _db;
  AppDatabase get db => _db;

  static const String _sessionKey = 'session_user';

  Future<void> _saveSession(AppUser user) async {
    await _db.database.insert(
      AppDatabase.tableSettings,
      {
        AppDatabase.columnKey: _sessionKey,
        AppDatabase.columnValue: jsonEncode(user.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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

    try {
      final existing = await _db.database.query(
        AppDatabase.tableUsers,
        where: 'LOWER(${AppDatabase.columnUserEmail}) = ?',
        whereArgs: [cleanEmail],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        throw AuthException('Email này đã được đăng ký! Vui lòng chọn đăng nhập.');
      }

      final id = 'user_${DateTime.now().millisecondsSinceEpoch}';
      await _db.database.insert(
        AppDatabase.tableUsers,
        {
          AppDatabase.columnUserId: id,
          AppDatabase.columnUserName: cleanName,
          AppDatabase.columnUserEmail: cleanEmail,
          AppDatabase.columnUserPassword: password,
          AppDatabase.columnUserCreatedAt: DateTime.now().toIso8601String(),
        },
      );

      final user = AppUser(
        id: id,
        name: cleanName,
        email: cleanEmail,
        isGuest: false,
      );
      await _saveSession(user);
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Lỗi cơ sở dữ liệu khi đăng ký: $e');
    }
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

    try {
      final rows = await _db.database.query(
        AppDatabase.tableUsers,
        where: 'LOWER(${AppDatabase.columnUserEmail}) = ?',
        whereArgs: [cleanEmail],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw AuthException('Tài khoản email này chưa được đăng ký!');
      }

      final row = rows.first;
      final storedPassword = row[AppDatabase.columnUserPassword] as String?;
      if (storedPassword != password) {
        throw AuthException('Mật khẩu không chính xác!');
      }

      final user = AppUser(
        id: row[AppDatabase.columnUserId] as String? ?? 'user_id',
        name: row[AppDatabase.columnUserName] as String? ?? 'Người dùng',
        email: cleanEmail,
        isGuest: false,
      );

      await _saveSession(user);
      return user;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Lỗi cơ sở dữ liệu khi đăng nhập: $e');
    }
  }

  @override
  Future<AppUser> loginAsGuest() async {
    try {
      final guest = AppUser(
        id: 'guest_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Khách',
        email: '',
        isGuest: true,
      );
      await _saveSession(guest);
      return guest;
    } catch (e) {
      throw AuthException('Lỗi khi đăng nhập dưới dạng khách: $e');
    }
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    try {
      final rows = await _db.database.query(
        AppDatabase.tableSettings,
        where: '${AppDatabase.columnKey} = ?',
        whereArgs: [_sessionKey],
        limit: 1,
      );

      if (rows.isEmpty) return null;
      final val = rows.first[AppDatabase.columnValue] as String?;
      if (val == null || val.isEmpty) return null;

      final data = jsonDecode(val) as Map<String, dynamic>;
      return AppUser.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _db.database.delete(
        AppDatabase.tableSettings,
        where: '${AppDatabase.columnKey} = ?',
        whereArgs: [_sessionKey],
      );
    } catch (e) {
      throw AuthException('Lỗi khi đăng xuất: $e');
    }
  }
}
