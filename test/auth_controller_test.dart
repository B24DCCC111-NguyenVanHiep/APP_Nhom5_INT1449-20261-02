// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra đăng ký/đăng nhập (mở rộng) và cổng AuthGate.
// Người phụ trách: Người 3 (phần mở rộng ngoài phân công)

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:step_tracker/data/fake_auth_repository.dart';
import 'package:step_tracker/data/local_auth_repository.dart';
import 'package:step_tracker/logic/auth_controller.dart';
import 'package:step_tracker/ui/login_screen.dart';
import 'package:step_tracker/ui/strings.dart';
import 'package:step_tracker/ui/widgets/auth_gate.dart';

const _pass = 'MatKhau-Bi-Mat-123';

/// iterations nhỏ để test chạy nhanh; thuật toán băm vẫn là PBKDF2 thật.
LocalAuthRepository _local(MemoryKeyValueStore store) =>
    LocalAuthRepository(store: store, iterations: 4);

void main() {
  group('Kiểm tra dữ liệu nhập', () {
    test('email', () {
      expect(AuthController.validateEmail(''), AppStrings.authEmailEmpty);
      expect(AuthController.validateEmail('abc'), AppStrings.authEmailInvalid);
      expect(AuthController.validateEmail('a@b'), AppStrings.authEmailInvalid);
      expect(AuthController.validateEmail('ban@example.com'), isNull);
    });

    test('mật khẩu ít nhất 8 ký tự', () {
      expect(AuthController.validatePassword('1234567'), AppStrings.authPasswordShort);
      expect(AuthController.validatePassword('12345678'), isNull);
    });

    test('xác nhận mật khẩu phải khớp', () {
      expect(AuthController.validateConfirm('abc12345', 'abc1234'),
          AppStrings.authConfirmMismatch);
      expect(AuthController.validateConfirm('abc12345', 'abc12345'), isNull);
    });

    test('dữ liệu sai bị chặn, không chạm tới repository', () async {
      final repo = FakeAuthRepository();
      final c = AuthController(repository: repo);
      addTearDown(c.dispose);
      final ok = await c.signUp(
        displayName: 'An',
        email: 'an@example.com',
        password: 'ngan',
        confirmPassword: 'ngan',
      );
      expect(ok, isFalse);
      expect(c.formError, AppStrings.authPasswordShort);
      expect(repo.signUpCalls, 0);
    });
  });

  group('AuthController + LocalAuthRepository', () {
    late MemoryKeyValueStore store;
    late AuthController c;

    setUp(() async {
      store = MemoryKeyValueStore();
      c = AuthController(repository: _local(store));
      await c.start();
    });
    tearDown(() => c.dispose());

    Future<bool> register([String email = 'an@example.com']) => c.signUp(
          displayName: 'Nguyễn An',
          email: email,
          password: _pass,
          confirmPassword: _pass,
        );

    test('khởi động chưa có phiên thì unauthenticated', () {
      expect(c.status, AuthStatus.unauthenticated);
      expect(c.user, isNull);
    });

    test('đăng ký thành công thì đăng nhập luôn', () async {
      expect(await register(), isTrue);
      expect(c.status, AuthStatus.authenticated);
      expect(c.user?.email, 'an@example.com');
      expect(c.user?.walletAddress, isNull);
    });

    test('đăng ký trùng email (không phân biệt hoa thường) bị từ chối', () async {
      await register('an@example.com');
      await c.signOut();
      expect(await register('AN@Example.com'), isFalse);
      expect(c.formError, AppStrings.authEmailTaken);
      expect(c.status, AuthStatus.unauthenticated);
    });

    test('sai mật khẩu bị từ chối, đúng mật khẩu thì vào được', () async {
      await register();
      await c.signOut();
      expect(await c.signIn(email: 'an@example.com', password: 'sai-mat-khau'), isFalse);
      expect(c.formError, AppStrings.authBadCredentials);
      expect(c.status, AuthStatus.unauthenticated);

      expect(await c.signIn(email: 'an@example.com', password: _pass), isTrue);
      expect(c.status, AuthStatus.authenticated);
      expect(c.formError, isNull);
    });

    test('email chưa đăng ký cùng thông báo với sai mật khẩu (không lộ tài khoản)', () async {
      expect(await c.signIn(email: 'la@example.com', password: _pass), isFalse);
      expect(c.formError, AppStrings.authBadCredentials);
    });

    test('đăng xuất đưa về unauthenticated và xoá phiên', () async {
      await register();
      await c.signOut();
      expect(c.status, AuthStatus.unauthenticated);
      expect(c.user, isNull);

      final c2 = AuthController(repository: _local(store));
      addTearDown(c2.dispose);
      await c2.start();
      expect(c2.status, AuthStatus.unauthenticated);
    });

    test('phiên được giữ: mở lại app vẫn đăng nhập', () async {
      await register();
      final c2 = AuthController(repository: _local(store));
      addTearDown(c2.dispose);
      await c2.start();
      expect(c2.status, AuthStatus.authenticated);
      expect(c2.user?.displayName, 'Nguyễn An');
    });

    test('mật khẩu KHÔNG bao giờ được lưu dạng thô', () async {
      await register();
      expect(store.data, isNotEmpty);
      for (final value in store.data.values) {
        expect(value, isNot(contains(_pass)));
        expect(value, isNot(contains(base64Encode(utf8.encode(_pass)))));
      }
      final accounts = jsonDecode(store.data['auth.accounts.v1']!) as Map<String, dynamic>;
      final record = accounts['an@example.com'] as Map<String, dynamic>;
      expect(record['salt'], isA<String>());
      expect(record['hash'], isA<String>());
      expect(record.containsKey('password'), isFalse);
    });

    test('hai tài khoản cùng mật khẩu có salt và hash khác nhau', () async {
      await register('a@example.com');
      await c.signOut();
      await register('b@example.com');
      final accounts = jsonDecode(store.data['auth.accounts.v1']!) as Map<String, dynamic>;
      final a = accounts['a@example.com'] as Map<String, dynamic>;
      final b = accounts['b@example.com'] as Map<String, dynamic>;
      expect(a['salt'], isNot(b['salt']));
      expect(a['hash'], isNot(b['hash']));
    });

    test('PBKDF2 đúng vector chuẩn (RFC 7914, HMAC-SHA256, c=1)', () {
      // password="passwd", salt="salt", c=1, dkLen=32
      final out = LocalAuthRepository.pbkdf2('passwd', utf8.encode('salt'), 1);
      final hex = out.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      expect(hex, '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc');
    });
  });

  group('AuthController khi lỗi', () {
    test('không đọc được phiên lúc khởi động -> error rồi retry', () async {
      final repo = FakeAuthRepository()..failWithStorageError = true;
      final c = AuthController(repository: repo);
      addTearDown(c.dispose);
      await c.start();
      expect(c.status, AuthStatus.error);
      expect(c.errorMessage, AppStrings.authStorageError);

      repo.failWithStorageError = false;
      await c.start();
      expect(c.status, AuthStatus.unauthenticated);
    });
  });

  group('AuthGate', () {
    Widget wrap(AuthController c) => ChangeNotifierProvider<AuthController>.value(
          value: c,
          child: const MaterialApp(
            home: AuthGate(child: Scaffold(body: Text('NỘI DUNG THỬ THÁCH'))),
          ),
        );

    testWidgets('chưa đăng nhập thì chặn và hiện màn đăng nhập', (t) async {
      final c = AuthController(repository: FakeAuthRepository());
      addTearDown(c.dispose);
      await t.runAsync(c.start);
      await t.pumpWidget(wrap(c));
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('NỘI DUNG THỬ THÁCH'), findsNothing);
      expect(find.text(AppStrings.guestButton), findsOneWidget);
    });

    testWidgets('đăng nhập xong thì tự chuyển sang màn con', (t) async {
      final repo = FakeAuthRepository();
      final c = AuthController(repository: repo);
      addTearDown(c.dispose);
      await t.runAsync(c.start);
      await t.pumpWidget(wrap(c));
      expect(find.text('NỘI DUNG THỬ THÁCH'), findsNothing);

      await t.runAsync(() => c.signUp(
            displayName: 'Bình',
            email: 'binh@example.com',
            password: _pass,
            confirmPassword: _pass,
          ));
      await t.pump();
      expect(find.text('NỘI DUNG THỬ THÁCH'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });
}
