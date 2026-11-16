// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra bảng xếp hạng đúng thứ tự và cập nhật theo ID.
// Người phụ trách: Người 5

import 'package:flutter_test/flutter_test.dart';
import 'package:step_tracker/data/friends_repository.dart';

// NGƯỜI 5.
void main() {
  group('FakeFriendsRepository tests (Lưu theo ID)', () {
    test('bảng xếp hạng sắp theo số bước giảm dần', () async {
      final repo = FakeFriendsRepository({});
      await repo.submitMySteps('NHOM1', 'u1', 'Alice', 3000);
      await repo.submitMySteps('NHOM1', 'u2', 'Bob', 8000);
      await repo.submitMySteps('NHOM1', 'u3', 'Charlie', 5000);

      final list = await repo.leaderboard('NHOM1');

      expect(list.length, 3);
      expect(list[0].id, 'u2');
      expect(list[0].name, 'Bob');
      expect(list[0].steps, 8000);

      expect(list[1].id, 'u3');
      expect(list[1].name, 'Charlie');
      expect(list[1].steps, 5000);

      expect(list[2].id, 'u1');
      expect(list[2].name, 'Alice');
      expect(list[2].steps, 3000);
    });

    test('gửi bước của mình rồi xuất hiện trong bảng', () async {
      final repo = FakeFriendsRepository({});
      await repo.submitMySteps('NHOM1', 'my_id', 'Hiệp', 12000);

      final list = await repo.leaderboard('NHOM1');

      expect(list.length, 1);
      expect(list.first.id, 'my_id');
      expect(list.first.name, 'Hiệp');
      expect(list.first.steps, 12000);
    });

    test('đổi tên cùng userId không làm nhân đôi bản ghi mà chỉ cập nhật tên', () async {
      final repo = FakeFriendsRepository({});
      const userId = 'user_unique_123';

      // Lần 1: đặt tên "Hiệp"
      await repo.submitMySteps('NHOM1', userId, 'Hiệp', 8000);
      var list = await repo.leaderboard('NHOM1');
      expect(list.length, 1);
      expect(list.first.name, 'Hiệp');
      expect(list.first.steps, 8000);

      // Lần 2: đổi tên thành "Nguyễn Văn Hiệp", tăng bước lên 10000
      await repo.submitMySteps('NHOM1', userId, 'Nguyễn Văn Hiệp', 10000);
      list = await repo.leaderboard('NHOM1');

      // Vẫn chỉ có đúng 1 người trong nhóm, tên và bước được cập nhật
      expect(list.length, 1);
      expect(list.first.id, userId);
      expect(list.first.name, 'Nguyễn Văn Hiệp');
      expect(list.first.steps, 10000);
    });

    test('mã nhóm không tồn tại trả về danh sách rỗng', () async {
      final repo = FakeFriendsRepository({});
      final list = await repo.leaderboard('KHONG_TON_TAI');

      expect(list, isEmpty);
    });

    test('khoảng trắng ở mã nhóm, id hoặc tên được chuẩn hoá', () async {
      final repo = FakeFriendsRepository({});
      await repo.submitMySteps('  NHOM_A  ', '  u_100  ', '  Nam  ', 7000);

      final list = await repo.leaderboard('NHOM_A');
      expect(list.length, 1);
      expect(list.first.id, 'u_100');
      expect(list.first.name, 'Nam');
      expect(list.first.steps, 7000);
    });
  });
}
