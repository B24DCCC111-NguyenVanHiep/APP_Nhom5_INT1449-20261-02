// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra controller và các màn hình.
// Người phụ trách: Người 3

import 'package:flutter_test/flutter_test.dart';

// NGƯỜI 3. Test StepsController bằng sensor/repository/notifier giả,
// và ít nhất 2 widget test cho luồng chính.
void main() {
  test('không có quyền thì ở trạng thái noPermission', () {}, skip: 'TODO');
  test('cộng dồn bước theo hiệu số cảm biến', () {}, skip: 'TODO');
  test('cảm biến reset vẫn cộng đúng', () {}, skip: 'TODO');
  test('đạt mục tiêu chỉ thông báo một lần trong ngày', () {}, skip: 'TODO');
  testWidgets('màn chính: chưa có bước thì hiện trạng thái trống', (t) async {},
      skip: true);
  testWidgets('màn mục tiêu: nhập không hợp lệ thì báo lỗi', (t) async {},
      skip: true);
}
