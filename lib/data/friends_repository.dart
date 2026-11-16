// FILE NÀY ĐỂ LÀM GÌ: Lấy và gửi số bước của bạn bè, tự động lưu xuống ổ đĩa không mất khi tắt app.
// Người phụ trách: Người 5

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// NGƯỜI 5. Thử thách bạn bè.
/// Dữ liệu lưu bền vững xuống ổ đĩa thiết bị (không bị mất khi tắt app).
class FriendEntry {
  const FriendEntry(
    this.name,
    this.steps, {
    this.id = '',
  });

  final String id;
  final String name;
  final int steps;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FriendEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          steps == other.steps;

  @override
  int get hashCode => Object.hash(id, name, steps);

  @override
  String toString() => 'FriendEntry(id: $id, name: $name, steps: $steps)';
}

abstract class FriendsRepository {
  Future<List<FriendEntry>> leaderboard(String groupCode);

  Future<void> submitMySteps(
    String groupCode,
    String userId,
    String name,
    int steps,
  );
}

class FakeFriendsRepository implements FriendsRepository {
  FakeFriendsRepository([Map<String, Map<String, FriendEntry>>? initialData])
      : _groups = initialData ??
            <String, Map<String, FriendEntry>>{
              'DEMO': <String, FriendEntry>{
                'user_01':
                    const FriendEntry('Nguyễn Văn A', 9500, id: 'user_01'),
                'user_02':
                    const FriendEntry('Trần Thị B', 8200, id: 'user_02'),
                'user_03':
                    const FriendEntry('Lê Văn C', 6100, id: 'user_03'),
                'user_04':
                    const FriendEntry('Phạm Minh D', 4300, id: 'user_04'),
              },
            } {
    // Tự động tải lại dữ liệu đã lưu từ ổ đĩa khi khởi động
    _loadFromDisk();
  }

  /// Cấu trúc trong bộ nhớ: groupCode -> (userId -> FriendEntry)
  final Map<String, Map<String, FriendEntry>> _groups;
  bool _diskLoaded = false;

  /// Đường dẫn file lưu dữ liệu bền vững
  Future<File?> _getStorageFile() async {
    try {
      final dbPath = await getDatabasesPath();
      return File(p.join(dbPath, 'friends_leaderboard.json'));
    } catch (_) {
      return null;
    }
  }

  /// Đọc dữ liệu từ file khi mở app
  Future<void> _loadFromDisk() async {
    if (_diskLoaded) return;
    try {
      final file = await _getStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          for (final groupCode in decoded.keys) {
            final groupMap = decoded[groupCode] as Map<String, dynamic>;
            final targetGroup =
                _groups.putIfAbsent(groupCode, () => <String, FriendEntry>{});
            for (final userId in groupMap.keys) {
              final item = groupMap[userId] as Map<String, dynamic>;
              targetGroup[userId] = FriendEntry(
                item['name'] as String,
                item['steps'] as int,
                id: item['id'] as String? ?? userId,
              );
            }
          }
        }
      }
      _diskLoaded = true;
    } catch (_) {
      // Bỏ qua lỗi nếu môi trường test không có ổ đĩa Android
    }
  }

  /// Lưu toàn bộ dữ liệu xuống file ngay khi có thay đổi
  Future<void> _saveToDisk() async {
    try {
      final file = await _getStorageFile();
      if (file == null) return;

      final data = <String, Map<String, dynamic>>{};
      for (final groupEntry in _groups.entries) {
        data[groupEntry.key] = groupEntry.value.map(
          (userId, entry) => MapEntry(userId, {
            'id': entry.id,
            'name': entry.name,
            'steps': entry.steps,
          }),
        );
      }

      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(data));
    } catch (_) {
      // Giữ app hoạt động bình thường kể cả khi ghi file gặp vấn đề
    }
  }

  @override
  Future<List<FriendEntry>> leaderboard(String groupCode) async {
    await _loadFromDisk();
    final group = _groups[groupCode.trim()];
    if (group == null || group.isEmpty) {
      return <FriendEntry>[];
    }
    final entries = group.values.toList();
    entries.sort((a, b) => b.steps.compareTo(a.steps));
    return entries;
  }

  @override
  Future<void> submitMySteps(
    String groupCode,
    String userId,
    String name,
    int steps,
  ) async {
    final cleanGroup = groupCode.trim();
    final cleanId = userId.trim();
    final cleanName = name.trim();

    if (cleanGroup.isEmpty || cleanId.isEmpty || cleanName.isEmpty) return;

    await _loadFromDisk();
    final group = _groups.putIfAbsent(cleanGroup, () => <String, FriendEntry>{});
    group[cleanId] = FriendEntry(cleanName, steps, id: cleanId);

    // Lưu bền vững ngay xuống ổ đĩa
    await _saveToDisk();
  }
}
