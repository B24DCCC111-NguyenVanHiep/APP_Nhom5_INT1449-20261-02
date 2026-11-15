// FILE NÀY ĐỂ LÀM GÌ: Mô tả số bước của một ngày. File chung, không cần sửa.
// Người phụ trách: Cả nhóm

/// Số bước của một ngày. Ngày luôn được chuẩn hoá về 00:00 (bỏ giờ).
class DailySteps {
  DailySteps(DateTime date, this.steps) : date = dayOf(date);

  final DateTime date;
  final int steps;

  static DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Khoá dạng yyyy-MM-dd, dùng để lưu SQLite.
  String get key =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DailySteps copyWith({int? steps}) => DailySteps(date, steps ?? this.steps);

  @override
  bool operator ==(Object other) =>
      other is DailySteps && other.date == date && other.steps == steps;

  @override
  int get hashCode => Object.hash(date, steps);

  @override
  String toString() => 'DailySteps($key, $steps)';
}
