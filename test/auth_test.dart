// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra tính năng Đăng nhập, Đăng ký và Quản lý phiên tài khoản.
// Người phụ trách: Người 2 (Database)

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:step_tracker/data/app_database.dart';
import 'package:step_tracker/data/auth_repository.dart';
import 'package:step_tracker/data/in_memory_auth_repository.dart';
import 'package:step_tracker/data/sqlite_auth_repository.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final factories = <String, Future<AuthRepository> Function()>{
    'InMemoryAuthRepository': () async => InMemoryAuthRepository(),
    'SqliteAuthRepository': () async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      return SqliteAuthRepository(db);
    },
  };

  for (final entry in factories.entries) {
    group(entry.key, () {
      late AuthRepository repo;

      setUp(() async {
        repo = await entry.value();
      });

      tearDown(() async {
        if (repo is SqliteAuthRepository) {
          final r = repo as SqliteAuthRepository;
          await r.db.close();
        }
      });

      test('đăng ký thành công và tự động lưu phiên currentUser', () async {
        final user = await repo.register(
          name: 'Nguyễn Văn A',
          email: 'vana@example.com',
          password: 'password123',
        );

        expect(user.id, isNotEmpty);
        expect(user.name, 'Nguyễn Văn A');
        expect(user.email, 'vana@example.com');
        expect(user.isGuest, false);

        final current = await repo.getCurrentUser();
        expect(current, isNotNull);
        expect(current?.email, 'vana@example.com');
      });

      test('đăng ký với email trùng lặp bị từ chối', () async {
        await repo.register(
          name: 'Nguyễn Văn A',
          email: 'test@example.com',
          password: 'password123',
        );

        expect(
          () => repo.register(
            name: 'Người Khác',
            email: 'TEST@EXAMPLE.COM', // Không phân biệt hoa thường
            password: 'password456',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('đăng nhập thành công với thông tin chính xác', () async {
        await repo.register(
          name: 'Trần Thị B',
          email: 'thib@example.com',
          password: 'mypassword',
        );

        // Đăng xuất trước khi test đăng nhập lại
        await repo.logout();
        expect(await repo.getCurrentUser(), isNull);

        final user = await repo.login(
          email: 'thib@example.com',
          password: 'mypassword',
        );
        expect(user.name, 'Trần Thị B');
        expect(user.email, 'thib@example.com');

        final current = await repo.getCurrentUser();
        expect(current?.id, user.id);
      });

      test('đăng nhập sai mật khẩu bị từ chối', () async {
        await repo.register(
          name: 'Lê Văn C',
          email: 'vanc@example.com',
          password: 'correct_password',
        );

        expect(
          () => repo.login(
            email: 'vanc@example.com',
            password: 'wrong_password',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('đăng nhập tài khoản chưa tồn tại bị từ chối', () async {
        expect(
          () => repo.login(
            email: 'not_exist@example.com',
            password: 'somepassword',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('đăng nhập ở dạng khách (Guest)', () async {
        final guest = await repo.loginAsGuest();
        expect(guest.isGuest, true);
        expect(guest.name, 'Khách');

        final current = await repo.getCurrentUser();
        expect(current?.isGuest, true);
      });

      test('đăng xuất xoá phiên làm việc', () async {
        await repo.loginAsGuest();
        expect(await repo.getCurrentUser(), isNotNull);

        await repo.logout();
        expect(await repo.getCurrentUser(), isNull);
      });

      test('kiểm tra dữ liệu đầu vào không hợp lệ khi đăng ký', () async {
        // Tên rỗng
        expect(
          () => repo.register(name: '', email: 'a@b.com', password: '123456'),
          throwsA(isA<AuthException>()),
        );
        // Email không hợp lệ
        expect(
          () => repo.register(
            name: 'A',
            email: 'invalid-email',
            password: '123456',
          ),
          throwsA(isA<AuthException>()),
        );
        // Mật khẩu dưới 6 ký tự
        expect(
          () => repo.register(name: 'A', email: 'a@b.com', password: '123'),
          throwsA(isA<AuthException>()),
        );
      });
    });
  }
}
