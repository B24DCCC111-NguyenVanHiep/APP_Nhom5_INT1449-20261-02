// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra các phép tính của StepCalculator.
// Người phụ trách: Người 1

import 'package:flutter_test/flutter_test.dart';
import 'package:step_tracker/logic/step_calculator.dart';

// NGƯỜI 1. Test thuần Dart cho StepCalculator, gồm cả các trường hợp biên.
void main() {
  const calc = StepCalculator();

  group('delta (số bước tăng thêm)', () {
    test('lần đọc đầu tiên coi như 0', () {
      expect(calc.delta(null, 5000), 0);
    });

    test('cộng dồn bình thường', () {
      expect(calc.delta(1000, 1075), 75);
    });

    test('hai lần đọc bằng nhau thì không tăng', () {
      expect(calc.delta(1000, 1000), 0);
    });

    test('máy khởi động lại: cảm biến reset về nhỏ hơn', () {
      expect(calc.delta(9000, 40), 40);
    });

    test('máy khởi động lại và cảm biến đang ở 0 thì không tăng', () {
      expect(calc.delta(9000, 0), 0);
    });

    test('giá trị âm (dữ liệu hỏng) không bao giờ ra số âm', () {
      expect(calc.delta(100, -5), 0);
    });
  });

  group('reachedGoal (đạt mục tiêu)', () {
    test('đạt mục tiêu khi bằng hoặc vượt', () {
      expect(calc.reachedGoal(8000, 8000), isTrue);
      expect(calc.reachedGoal(8001, 8000), isTrue);
    });

    test('chưa đạt khi còn thiếu một bước', () {
      expect(calc.reachedGoal(7999, 8000), isFalse);
    });

    test('mục tiêu bằng 0 hoặc âm thì không bao giờ đạt', () {
      expect(calc.reachedGoal(1000, 0), isFalse);
      expect(calc.reachedGoal(1000, -1), isFalse);
    });
  });

  group('progress (tiến độ 0.0 - 1.0)', () {
    test('một nửa mục tiêu', () {
      expect(calc.progress(4000, 8000), closeTo(0.5, 1e-9));
    });

    test('tiến độ bị chặn ở 1.0', () {
      expect(calc.progress(12000, 8000), 1.0);
    });

    test('chưa đi bước nào thì bằng 0.0', () {
      expect(calc.progress(0, 8000), 0.0);
    });

    test('mục tiêu bằng 0 không gây chia cho 0', () {
      expect(calc.progress(500, 0), 0.0);
    });

    test('số bước âm được chặn ở 0.0', () {
      expect(calc.progress(-10, 8000), 0.0);
    });
  });

  group('percent (phần trăm nguyên)', () {
    test('làm tròn xuống, 7999/8000 là 99% chứ không phải 100%', () {
      expect(calc.percent(7999, 8000), 99);
    });

    test('đạt hoặc vượt mục tiêu thì 100%', () {
      expect(calc.percent(8000, 8000), 100);
      expect(calc.percent(20000, 8000), 100);
    });
  });
}
