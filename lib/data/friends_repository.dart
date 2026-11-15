// FILE NÀY ĐỂ LÀM GÌ: Lấy và gửi số bước của bạn bè (bản giả trước, sau đó Firestore).
// Người phụ trách: Người 5

/// NGƯỜI 5. Thử thách bạn bè (mở rộng).
/// Bắt đầu bằng bản giả trong bộ nhớ, sau đó thay bằng Firestore.
/// Lưu ý Firebase: không commit khoá riêng, đặt Firestore rules đúng.
class FriendEntry {
  const FriendEntry(this.name, this.steps);
  final String name;
  final int steps;
}

abstract class FriendsRepository {
  Future<List<FriendEntry>> leaderboard(String groupCode);
  Future<void> submitMySteps(String groupCode, String myName, int steps);
}

class FakeFriendsRepository implements FriendsRepository {
  /// TODO: leaderboard sắp theo steps giảm dần; mã nhóm không có thì trả rỗng.
  @override
  Future<List<FriendEntry>> leaderboard(String groupCode) =>
      throw UnimplementedError();

  @override
  Future<void> submitMySteps(String groupCode, String myName, int steps) =>
      throw UnimplementedError();
}
