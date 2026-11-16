// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra thống kê.
// Người phụ trách: Người 4
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:step_tracker/data/step_repository.dart';
import 'package:step_tracker/models/daily_steps.dart';
import 'package:step_tracker/logic/stats_calculator.dart';
import 'package:step_tracker/ui/chart_screen.dart' show ChartScreen;

/// Mock repository dùng đúng hợp đồng của nhóm, không cần SQLite/cảm biến.
class _FakeStepRepository implements StepRepository {
  _FakeStepRepository({List<DailySteps>? history}) : history = history ?? [];

  List<DailySteps> history;
  int goal = 8000;
  bool shouldFail = false;
  final List<(DateTime, DateTime)> queries = [];
  int goalReads = 0;

  @override
  Future<void> saveDay(DailySteps day) async {
    history.add(day);
  }

  @override
  Future<DailySteps?> getDay(DateTime date) async {
    for (final day in history) {
      if (day.date == DailySteps.dayOf(date)) return day;
    }
    return null;
  }

  @override
  Future<List<DailySteps>> getRange(DateTime from, DateTime to) async {
    queries.add((from, to));
    if (shouldFail) throw StepRepositoryException('Không tải được dữ liệu');
    return history
        .where((e) =>
            !e.date.isBefore(DailySteps.dayOf(from)) &&
            !e.date.isAfter(DailySteps.dayOf(to)))
        .toList();
  }

  @override
  Future<int> getGoal() async {
    goalReads++;
    return goal;
  }

  @override
  Future<void> setGoal(int value) async {
    goal = value;
  }

  @override
  Future<int?> getLastSensorValue() async => null;

  @override
  Future<void> setLastSensorValue(int value) async {}

  @override
  Future<DateTime?> getLastGoalNotifiedDay() async => null;

  @override
  Future<void> setLastGoalNotifiedDay(DateTime day) async {}
}

void main() {
  final today = DateTime(2026, 11, 16);

  group('Phân loại màu theo tỷ lệ hoàn thành mục tiêu', () {
    test('Mức 100% trở lên là xanh / achieved', () {
      expect(StatsCalculator.classifyGoalLevel(steps: 8000, dailyGoal: 8000),
          StepGoalLevel.achieved);
      expect(StatsCalculator.classifyGoalLevel(steps: 9000, dailyGoal: 8000),
          StepGoalLevel.achieved);
    });

    test('Từ 80% đến dưới 100% là vàng / near', () {
      expect(StatsCalculator.classifyGoalLevel(steps: 6400, dailyGoal: 8000),
          StepGoalLevel.near);
      expect(StatsCalculator.classifyGoalLevel(steps: 7999, dailyGoal: 8000),
          StepGoalLevel.near);
    });

    test('Dưới 80% là đỏ / low, bao gồm ngày 0 bước', () {
      expect(StatsCalculator.classifyGoalLevel(steps: 6399, dailyGoal: 8000),
          StepGoalLevel.low);
      expect(StatsCalculator.classifyGoalLevel(steps: 0, dailyGoal: 8000),
          StepGoalLevel.low);
    });

    test('Không chấp nhận mục tiêu hoặc số bước bất hợp lệ', () {
      expect(
        () => StatsCalculator.classifyGoalLevel(steps: -1, dailyGoal: 8000),
        throwsArgumentError,
      );
      expect(
        () => StatsCalculator.classifyGoalLevel(steps: 10, dailyGoal: 0),
        throwsArgumentError,
      );
    });
  });

  group('StatsCalculator - thống kê 7/30 ngày', () {
    test('Bù ngày thiếu bằng 0; ngày xếp từ cũ đến mới', () {
      final stats = StatsCalculator.calculate(
        records: [
          DailySteps(DateTime(2026, 11, 16, 20), 10000),
          DailySteps(DateTime(2026, 11, 14, 8), 3000),
        ],
        numberOfDays: 3,
        dailyGoal: 8000,
        referenceDate: today,
      );
      expect(stats.days.map((d) => d.date.day).toList(), [14, 15, 16]);
      expect(stats.days.map((d) => d.steps).toList(), [3000, 0, 10000]);
      expect(stats.totalSteps, 13000);
      expect(stats.averageSteps, closeTo(4333.333, 0.01));
      expect(stats.daysReachedGoal, 1);
      expect(stats.bestDayDate, today);
      expect(stats.bestDaySteps, 10000);
    });

    test('Đạt đúng 8.000 bước được tính là đạt mục tiêu', () {
      final stats = StatsCalculator.calculate(
        records: [
          DailySteps(today, 8000),
          DailySteps(DateTime(2026, 11, 15), 7999),
        ],
        numberOfDays: 2,
        dailyGoal: 8000,
        referenceDate: today,
      );
      expect(stats.daysReachedGoal, 1);
    });

    test('Hai bản ghi trùng ngày lấy bước lớn nhất (không cộng)', () {
      final stats = StatsCalculator.calculate(
        records: [
          DailySteps(DateTime(2026, 11, 16, 8), 3000),
          DailySteps(DateTime(2026, 11, 16, 18), 7000),
          DailySteps(DateTime(2026, 11, 16, 12), 4500),
        ],
        numberOfDays: 1,
        dailyGoal: 8000,
        referenceDate: today,
      );
      expect(stats.totalSteps, 7000);
      expect(stats.bestDaySteps, 7000);
    });

    test('Bỏ qua bản ghi trước/sau kỳ thống kê', () {
      final stats = StatsCalculator.calculate(
        records: [
          DailySteps(DateTime(2026, 11, 1), 100000),
          DailySteps(DateTime(2026, 11, 17), 100000),
          DailySteps(today, 2000),
        ],
        numberOfDays: 7,
        dailyGoal: 8000,
        referenceDate: today,
      );
      expect(stats.totalSteps, 2000);
    });

    test('30 ngày không có dữ liệu: đủ 30 ngày, trung bình bằng 0', () {
      final stats = StatsCalculator.calculate(
        records: [],
        numberOfDays: 30,
        dailyGoal: 10000,
        referenceDate: today,
      );
      expect(stats.days.length, 30);
      expect(stats.startDate, DateTime(2026, 10, 18));
      expect(stats.endDate, today);
      expect(stats.totalSteps, 0);
      expect(stats.averageSteps, 0);
      expect(stats.daysReachedGoal, 0);
      expect(stats.bestDayDate, isNull);
    });

    test('Ngày qua năm mới và tháng 2 năm nhuận', () {
      expect(StatsCalculator.startDateFor(DateTime(2027, 1, 2), 7),
          DateTime(2026, 12, 27));
      expect(StatsCalculator.startDateFor(DateTime(2024, 3, 2), 7),
          DateTime(2024, 2, 25));
    });

    test('Từ chối kỳ thống kê, mục tiêu hoặc bước chân không hợp lệ', () {
      expect(
        () => StatsCalculator.calculate(
            records: [], numberOfDays: 0, dailyGoal: 8000),
        throwsArgumentError,
      );
      expect(
        () => StatsCalculator.calculate(
            records: [], numberOfDays: 7, dailyGoal: 0),
        throwsArgumentError,
      );
      expect(
        () => StatsCalculator.calculate(
          records: [DailySteps(today, -1)],
          numberOfDays: 7,
          dailyGoal: 8000,
          referenceDate: today,
        ),
        throwsArgumentError,
      );
    });
  });

  group('ChartScreen - tích hợp StepRepository.getRange', () {
    testWidgets('Mở 7 ngày, đổi 30 ngày: gọi getRange với đúng mốc',
        (tester) async {
      final repo = _FakeStepRepository(
        history: [DailySteps(today, 10000)],
      );
      await tester.pumpWidget(MaterialApp(
        home: ChartScreen(repository: repo, referenceDate: today),
      ));
      await tester.pumpAndSettle();

      expect(repo.queries.length, 1);
      expect(repo.queries.first.$1, DateTime(2026, 11, 10));
      expect(repo.queries.first.$2, today);
      expect(repo.goalReads, 1);
      expect(find.text('Tổng số bước'), findsOneWidget);
      expect(find.text('10.000'), findsNWidgets(2));

      await tester.tap(find.text('30 ngày').first);
      await tester.pumpAndSettle();
      expect(repo.queries.length, 2);
      expect(repo.queries.last.$1, DateTime(2026, 10, 18));
      expect(repo.queries.last.$2, today);
      expect(
          tester
              .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '30 ngày'))
              .selected,
          isTrue);
    });

    testWidgets('Không có lịch sử: hiện thông báo và ngày đạt mục tiêu 0/7',
        (tester) async {
      final repo = _FakeStepRepository();
      await tester.pumpWidget(MaterialApp(
        home: ChartScreen(repository: repo, referenceDate: today),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có lịch sử bước chân'), findsOneWidget);
      expect(find.text('0/7'), findsOneWidget);
    });

    testWidgets('Repository lỗi: bấm Thử lại rồi tải thành công',
        (tester) async {
      final repo = _FakeStepRepository()..shouldFail = true;
      await tester.pumpWidget(MaterialApp(
        home: ChartScreen(repository: repo, referenceDate: today),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được lịch sử bước chân'), findsOneWidget);
      repo.shouldFail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có lịch sử bước chân'), findsOneWidget);
    });

    testWidgets('Chạm cột hiển thị ngày, số bước và ngày thiếu dữ liệu',
        (tester) async {
      final repo = _FakeStepRepository(history: [
        DailySteps(today, 10000),
        DailySteps(DateTime(2026, 11, 14), 0),
      ]);
      await tester.pumpWidget(MaterialApp(
        home: ChartScreen(repository: repo, referenceDate: today),
      ));
      await tester.pumpAndSettle();

      final chart = find.byKey(const Key('step-chart-interactive'));
      await tester.ensureVisible(chart);
      await tester.pumpAndSettle();
      final rect = tester.getRect(chart);

      Offset centerOfDay(int index) => Offset(
            rect.left + 57 + (rect.width - 57 - 12) * (index + 0.5) / 7,
            rect.top + 150,
          );

      // 16/11: có 10.000 bước, đã đạt mục tiêu 8.000.
      await tester.tapAt(centerOfDay(6));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('step-chart-tooltip')),
          matching: find.text('16/11/2026'),
        ),
        findsOneWidget,
      );
      expect(find.text('10.000 bước'), findsOneWidget);
      expect(find.text('Đã đạt mục tiêu'), findsOneWidget);

      // 15/11: không có bản ghi gốc, được điền thành 0 bước.
      await tester.tapAt(centerOfDay(5));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('step-chart-tooltip')),
          matching: find.text('15/11/2026'),
        ),
        findsOneWidget,
      );
      expect(find.text('0 bước'), findsOneWidget);
      expect(find.text('Chưa ghi nhận dữ liệu'), findsOneWidget);
    });

    testWidgets('Tooltip phân biệt ngày gần đạt màu vàng và thấp màu đỏ',
        (tester) async {
      final repo = _FakeStepRepository(history: [
        DailySteps(today, 6400), // 80%: vàng.
        DailySteps(DateTime(2026, 11, 15), 6399), // Dưới 80%: đỏ.
      ]);
      await tester.pumpWidget(MaterialApp(
        home: ChartScreen(repository: repo, referenceDate: today),
      ));
      await tester.pumpAndSettle();
      final chart = find.byKey(const Key('step-chart-interactive'));
      await tester.ensureVisible(chart);
      await tester.pumpAndSettle();
      final rect = tester.getRect(chart);
      Offset centerOfDay(int index) => Offset(
            rect.left + 57 + (rect.width - 57 - 12) * (index + 0.5) / 7,
            rect.top + 150,
          );
      await tester.tapAt(centerOfDay(6));
      await tester.pump();
      expect(find.text('Gần đạt mục tiêu'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Gần đạt mục tiêu')).style?.color,
          const Color(0xFFF59E0B));
      await tester.tapAt(centerOfDay(5));
      await tester.pump();
      expect(find.text('Mức vận động thấp'), findsOneWidget);
      expect(tester.widget<Text>(find.text('Mức vận động thấp')).style?.color,
          const Color(0xFFDC2626));
    });

    testWidgets('Chưa được app truyền repository: hiển thị thông báo',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChartScreen()));
      expect(find.text('Chưa kết nối dữ liệu bước chân'), findsOneWidget);
    });
  });
}
