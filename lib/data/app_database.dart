// FILE NÀY ĐỂ LÀM GÌ: Tạo cơ sở dữ liệu SQLite trên máy.
// Người phụ trách: Người 2

/// NGƯỜI 2. Mở và khởi tạo SQLite.
/// TODO: thêm gói `sqflite` và `path`.
/// TODO: bảng daily_steps(date TEXT PRIMARY KEY, steps INTEGER),
///       bảng settings(key TEXT PRIMARY KEY, value TEXT).
class AppDatabase {
  AppDatabase._();

  static Future<AppDatabase> open({String? path}) =>
      throw UnimplementedError();

  Future<void> close() => throw UnimplementedError();
}
