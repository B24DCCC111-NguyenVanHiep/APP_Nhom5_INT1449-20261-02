// FILE NÀY ĐỂ LÀM GÌ: Hàm định dạng số bước, số thập phân và ngày theo kiểu Việt Nam.
// Người phụ trách: Người 3

import 'strings.dart';

/// 10000 -> "10.000" (dấu chấm ngăn cách hàng nghìn). Tự viết để khỏi thêm gói intl.
String formatSteps(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

/// 4.2 -> "4,2" (dấu phẩy thập phân).
String formatDecimal(double value, {int digits = 1}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

/// "Thứ Hai, 16/11/2026".
String formatDateVi(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  return '${AppStrings.weekdays[d.weekday - 1]}, $day/$month/${d.year}';
}

String greetingFor(int hour) {
  if (hour >= 5 && hour < 11) return AppStrings.greetingMorning;
  if (hour >= 11 && hour < 18) return AppStrings.greetingAfternoon;
  return AppStrings.greetingEvening;
}
