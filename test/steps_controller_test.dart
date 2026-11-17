// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra controller và các màn hình.
// Người phụ trách: Người 3

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:step_tracker/data/step_repository.dart';
import 'package:step_tracker/data/step_sensor_service.dart';
import 'package:step_tracker/logic/step_calculator.dart';
import 'package:step_tracker/logic/steps_controller.dart';
import 'package:step_tracker/models/daily_steps.dart';
import 'package:step_tracker/services/notification_service.dart';
import 'package:step_tracker/ui/goal_screen.dart';
import 'package:step_tracker/ui/home_screen.dart';
import 'package:step_tracker/ui/strings.dart';
import 'package:step_tracker/ui/widgets/state_views.dart';

// NGƯỜI 3. Toàn bộ bản giả nằm TRONG file test để không phụ thuộc phần của người khác
// (Người 1: StepCalculator, Người 2: InMemoryStepRepository, Người 5: LocalGoalNotifier).

/// Bản giả của StepCalculator với hành vi theo đúng mô tả trong test của Người 1.
/// Giả định: lần đọc đầu (last == null) tính là 0; cảm biến reset (current < last)
/// thì số bước tăng thêm chính là current.
class TestCalculator extends StepCalculator {
  const TestCalculator();

  @override
  int delta(int? last, int current) {
    if (last == null) return 0;
    if (current < last) return current;
    return current - last;
  }

  @override
  bool reachedGoal(int steps, int goal) => goal > 0 && steps >= goal;

  @override
  double progress(int steps, int goal) {
    if (goal <= 0) return 0;
    final p = steps / goal;
    return p > 1 ? 1.0 : p;
  }
}

class FakeSensor implements StepSensorService {
  FakeSensor({this.granted = true});

  bool granted;
  bool grantOnRequest = true;
  int requestCalls = 0;
  // broadcast để start()/retry() nghe lại được nhiều lần.
  final StreamController<int> _controller = StreamController<int>.broadcast();

  bool get hasListener => _controller.hasListener;
  void emit(int value) => _controller.add(value);
  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<int> get cumulativeSteps => _controller.stream;

  @override
  Future<bool> requestPermission() async {
    requestCalls++;
    if (grantOnRequest) granted = true;
    return granted;
  }

  @override
  Future<bool> hasPermission() async => granted;
}

class FakeRepository implements StepRepository {
  final Map<String, DailySteps> days = {};
  int goalValue = 8000;
  int? lastSensor;
  DateTime? lastNotified;
  bool failReads = false;
  bool failWrites = false;

  void _check(bool fail) {
    if (fail) throw StepRepositoryException('Không đọc được dữ liệu (giả lập).');
  }

  @override
  Future<void> saveDay(DailySteps day) async {
    _check(failWrites);
    days[day.key] = day;
  }

  @override
  Future<DailySteps?> getDay(DateTime date) async {
    _check(failReads);
    return days[DailySteps(date, 0).key];
  }

  @override
  Future<List<DailySteps>> getRange(DateTime from, DateTime to) async {
    _check(failReads);
    final list = days.values
        .where((d) => !d.date.isBefore(DailySteps.dayOf(from)) &&
            !d.date.isAfter(DailySteps.dayOf(to)))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  @override
  Future<int> getGoal() async {
    _check(failReads);
    return goalValue;
  }

  @override
  Future<void> setGoal(int goal) async {
    _check(failWrites);
    goalValue = goal;
  }

  @override
  Future<int?> getLastSensorValue() async {
    _check(failReads);
    return lastSensor;
  }

  @override
  Future<void> setLastSensorValue(int value) async {
    _check(failWrites);
    lastSensor = value;
  }

  @override
  Future<DateTime?> getLastGoalNotifiedDay() async {
    _check(failReads);
    return lastNotified;
  }

  @override
  Future<void> setLastGoalNotifiedDay(DateTime day) async {
    _check(failWrites);
    lastNotified = day;
  }
}

/// Dùng FakeGoalNotifier của Người 5, thêm công tắc giả lập thông báo bị lỗi.
class FakeNotifier extends FakeGoalNotifier {
  bool fail = false;

  @override
  Future<void> showGoalReached(int steps) async {
    if (fail) throw StateError('thông báo hỏng');
    await super.showGoalReached(steps);
  }
}

class Harness {
  Harness({int goal = 100, DateTime? now})
      : now = now ?? DateTime(2026, 11, 16, 9, 0) {
    repo.goalValue = goal;
    controller = StepsController(
      sensor: sensor,
      repository: repo,
      notifier: notifier,
      calculator: const TestCalculator(),
      clock: () => this.now,
    );
  }

  DateTime now;
  final sensor = FakeSensor();
  final repo = FakeRepository();
  final notifier = FakeNotifier();
  late final StepsController controller;

  DateTime get day => DailySteps.dayOf(now);
}

void main() {
  group('StepsController', () {
    test('không có quyền thì ở trạng thái noPermission', () async {
      final h = Harness();
      h.sensor.granted = false;
      await h.controller.start();
      expect(h.controller.status, StepsStatus.noPermission);
      expect(h.sensor.hasListener, isFalse);
    });

    test('cấp quyền xong thì chuyển sang ready và bắt đầu nghe cảm biến', () async {
      final h = Harness();
      h.sensor.granted = false;
      await h.controller.start();
      await h.controller.requestPermissionAndStart();
      expect(h.sensor.requestCalls, 1);
      expect(h.controller.status, StepsStatus.ready);
      expect(h.sensor.hasListener, isTrue);
    });

    test('từ chối quyền thì ở lại noPermission kèm thông báo', () async {
      final h = Harness();
      h.sensor
        ..granted = false
        ..grantOnRequest = false;
      await h.controller.start();
      await h.controller.requestPermissionAndStart();
      expect(h.controller.status, StepsStatus.noPermission);
      expect(h.controller.errorMessage, AppStrings.permissionDenied);
    });

    test('start đọc mục tiêu và số bước đã lưu của hôm nay', () async {
      final h = Harness(goal: 9000);
      h.repo.days[DailySteps(h.now, 0).key] = DailySteps(h.now, 1234);
      await h.controller.start();
      expect(h.controller.status, StepsStatus.ready);
      expect(h.controller.goal, 9000);
      expect(h.controller.todaySteps, 1234);
    });

    test('cộng dồn bước theo hiệu số cảm biến và lưu lại', () async {
      final h = Harness();
      h.repo.lastSensor = 1000;
      await h.controller.start();
      h.sensor.emit(1010);
      h.sensor.emit(1030);
      await pumpEventQueue();
      expect(h.controller.todaySteps, 30);
      expect(h.repo.days[DailySteps(h.now, 0).key]?.steps, 30);
      expect(h.repo.lastSensor, 1030);
    });

    test('lần đọc đầu tiên (chưa có mốc) không cộng bước', () async {
      final h = Harness();
      await h.controller.start();
      h.sensor.emit(5000);
      await pumpEventQueue();
      expect(h.controller.todaySteps, 0);
      expect(h.controller.isEmptyToday, isTrue);
      expect(h.repo.lastSensor, 5000); // nhưng đã ghi mốc cho lần sau
    });

    test('cảm biến reset (nhỏ hơn mốc cũ) vẫn cộng đúng', () async {
      final h = Harness();
      h.repo.lastSensor = 5000;
      await h.controller.start();
      h.sensor.emit(20);
      await pumpEventQueue();
      expect(h.controller.todaySteps, 20);
      expect(h.repo.lastSensor, 20);
    });

    test('bước đến dồn dập vẫn được xử lý tuần tự, không đếm sai', () async {
      final h = Harness(goal: 100000);
      h.repo.lastSensor = 0;
      await h.controller.start();
      for (var i = 1; i <= 10; i++) {
        h.sensor.emit(i * 10); // phát liền nhau, không chờ
      }
      await pumpEventQueue();
      expect(h.controller.todaySteps, 100);
      expect(h.repo.lastSensor, 100);
    });

    test('đạt mục tiêu chỉ thông báo một lần trong ngày', () async {
      final h = Harness(goal: 100);
      h.repo.lastSensor = 1000;
      await h.controller.start();
      h.sensor.emit(1060); // 60
      await pumpEventQueue();
      expect(h.notifier.shown, 0);
      h.sensor.emit(1110); // 110: đạt
      await pumpEventQueue();
      expect(h.notifier.shown, 1);
      h.sensor.emit(1150); // vẫn trên mục tiêu: không báo lại
      await pumpEventQueue();
      expect(h.notifier.shown, 1);
      expect(h.repo.lastNotified, h.day);
    });

    test('sang ngày mới thì được thông báo lại', () async {
      final h = Harness(goal: 100, now: DateTime(2026, 11, 16, 23, 50));
      h.repo.lastSensor = 1000;
      await h.controller.start();
      h.sensor.emit(1100);
      await pumpEventQueue();
      expect(h.notifier.shown, 1);

      h.now = DateTime(2026, 11, 17, 8, 0);
      h.sensor.emit(1200); // +100 trong ngày mới
      await pumpEventQueue();
      expect(h.notifier.shown, 2);
    });

    test('qua nửa đêm: bước tính vào ngày mới, ngày cũ giữ nguyên', () async {
      final h = Harness(goal: 100000, now: DateTime(2026, 11, 16, 23, 59));
      h.repo.lastSensor = 1000;
      await h.controller.start();
      h.sensor.emit(1100);
      await pumpEventQueue();
      expect(h.controller.todaySteps, 100);

      h.now = DateTime(2026, 11, 17, 0, 1);
      h.sensor.emit(1130);
      await pumpEventQueue();
      expect(h.controller.todaySteps, 30); // hôm nay là ngày mới
      expect(h.repo.days['2026-11-16']?.steps, 100);
      expect(h.repo.days['2026-11-17']?.steps, 30);
    });

    test('thông báo bị lỗi không làm dừng việc đếm bước', () async {
      final h = Harness(goal: 50);
      h.notifier.fail = true;
      h.repo.lastSensor = 0;
      await h.controller.start();
      h.sensor.emit(60);
      await pumpEventQueue();
      expect(h.controller.status, StepsStatus.ready);
      expect(h.controller.todaySteps, 60);
      expect(h.repo.lastNotified, isNull); // chưa đánh dấu để còn thử lại
    });

    test('lỗi repository khi start -> error rồi retry thành công', () async {
      final h = Harness();
      h.repo.failReads = true;
      await h.controller.start();
      expect(h.controller.status, StepsStatus.error);
      expect(h.controller.errorMessage, 'Không đọc được dữ liệu (giả lập).');

      h.repo.failReads = false;
      await h.controller.retry();
      expect(h.controller.status, StepsStatus.ready);
      expect(h.controller.errorMessage, isNull);
    });

    test('lỗi khi lưu bước -> error và ngừng nghe cảm biến', () async {
      final h = Harness();
      h.repo.lastSensor = 0;
      await h.controller.start();
      h.repo.failWrites = true;
      h.sensor.emit(10);
      await pumpEventQueue();
      expect(h.controller.status, StepsStatus.error);
      expect(h.sensor.hasListener, isFalse);
    });

    test('lỗi từ stream cảm biến -> error, thông báo không lộ chi tiết kỹ thuật', () async {
      final h = Harness();
      await h.controller.start();
      h.sensor.emitError(Exception('PlatformException(sensor, stack...)'));
      await pumpEventQueue();
      expect(h.controller.status, StepsStatus.error);
      expect(h.controller.errorMessage, AppStrings.errorSensor);
      expect(h.controller.errorMessage, isNot(contains('Exception')));
    });

    test('setGoal hợp lệ: lưu vào repository và cập nhật goal', () async {
      final h = Harness();
      await h.controller.start();
      var notified = 0;
      h.controller.addListener(() => notified++);
      await h.controller.setGoal(12000);
      expect(h.controller.goal, 12000);
      expect(h.repo.goalValue, 12000);
      expect(notified, 1);
    });

    test('setGoal ngoài khoảng 1..100000 bị từ chối, không lưu gì', () async {
      final h = Harness(goal: 8000);
      await h.controller.start();
      for (final bad in [0, -5, 100001]) {
        await expectLater(
          h.controller.setGoal(bad),
          throwsA(isA<InvalidGoalException>()),
        );
      }
      expect(h.controller.goal, 8000);
      expect(h.repo.goalValue, 8000);
      // hai đầu khoảng là hợp lệ
      await h.controller.setGoal(1);
      await h.controller.setGoal(100000);
      expect(h.controller.goal, 100000);
    });

    test('setGoal gặp lỗi lưu: ném StepRepositoryException, goal giữ nguyên, màn chính không lỗi', () async {
      final h = Harness(goal: 8000);
      await h.controller.start();
      h.repo.failWrites = true;
      await expectLater(
        h.controller.setGoal(9000),
        throwsA(isA<StepRepositoryException>()),
      );
      expect(h.controller.goal, 8000);
      expect(h.controller.status, StepsStatus.ready);
    });

    test('dispose huỷ stream và sự kiện đến muộn không gây lỗi', () async {
      final h = Harness();
      h.repo.lastSensor = 0;
      await h.controller.start();
      expect(h.sensor.hasListener, isTrue);
      h.sensor.emit(10); // đang bay dở
      h.controller.dispose();
      await pumpEventQueue(); // nếu còn notify sau dispose, test sẽ ném lỗi ở đây
      expect(h.sensor.hasListener, isFalse);
    });

    test('getter hiển thị: phần trăm, còn lại, ước tính km/kcal/phút', () async {
      final h = Harness(goal: 10000);
      h.repo.days[DailySteps(h.now, 0).key] = DailySteps(h.now, 2500);
      await h.controller.start();
      final c = h.controller;
      expect(c.percent, 25);
      expect(c.remainingSteps, 7500);
      expect(c.isEmptyToday, isFalse);
      expect(c.estimatedKm, closeTo(1.75, 0.001));
      expect(c.estimatedMinutes, 25);
      expect(c.estimatedKcal, closeTo(100, 0.001));
    });

    test('remainingSteps không âm khi vượt mục tiêu', () async {
      final h = Harness(goal: 100);
      h.repo.days[DailySteps(h.now, 0).key] = DailySteps(h.now, 250);
      await h.controller.start();
      expect(h.controller.remainingSteps, 0);
      expect(h.controller.percent, 100);
    });
  });

  group('Widget', () {
    Widget wrap(StepsController c, {Widget home = const HomeScreen()}) {
      return ChangeNotifierProvider<StepsController>.value(
        value: c,
        child: MaterialApp(home: home),
      );
    }

    void bigScreen(WidgetTester t) {
      t.view.physicalSize = const Size(800, 1800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
    }

    testWidgets('màn chính: đang tải thì hiện LoadingView', (t) async {
      bigScreen(t);
      final h = Harness(); // chưa gọi start()
      addTearDown(h.controller.dispose);
      await t.pumpWidget(wrap(h.controller));
      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text(AppStrings.loading), findsOneWidget);
    });

    testWidgets('màn chính: chưa có bước thì hiện trạng thái trống', (t) async {
      bigScreen(t);
      final h = Harness();
      addTearDown(h.controller.dispose);
      await t.runAsync(h.controller.start);
      await t.pumpWidget(wrap(h.controller));
      expect(find.byType(EmptyView), findsOneWidget);
      expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    });

    testWidgets('màn chính: có bước thì thấy số bước và phần trăm', (t) async {
      bigScreen(t);
      final h = Harness(goal: 10000);
      addTearDown(h.controller.dispose);
      h.repo.days[DailySteps(h.now, 0).key] = DailySteps(h.now, 2500);
      await t.runAsync(h.controller.start);
      await t.pumpWidget(wrap(h.controller));
      expect(find.text('2.500'), findsOneWidget);
      expect(find.text('25% mục tiêu'), findsOneWidget);
      expect(find.byType(EmptyView), findsNothing);
    });

    testWidgets('màn chính: lỗi thì có nút Thử lại và bấm được', (t) async {
      bigScreen(t);
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.repo.failReads = true;
      await t.runAsync(h.controller.start);
      await t.pumpWidget(wrap(h.controller));
      expect(find.text('Thử lại'), findsOneWidget);

      h.repo.failReads = false;
      await t.tap(find.text('Thử lại'));
      await t.pump();
      await t.pump();
      expect(find.text('Thử lại'), findsNothing);
      expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    });

    testWidgets('màn chính: chưa có quyền thì có nút Cấp quyền', (t) async {
      bigScreen(t);
      final h = Harness();
      addTearDown(h.controller.dispose);
      h.sensor.granted = false;
      await t.runAsync(h.controller.start);
      await t.pumpWidget(wrap(h.controller));
      expect(find.text('Cấp quyền'), findsOneWidget);
    });

    testWidgets('màn chính: bấm "Đổi" mở màn mục tiêu', (t) async {
      bigScreen(t);
      final h = Harness(goal: 10000);
      addTearDown(h.controller.dispose);
      h.repo.days[DailySteps(h.now, 0).key] = DailySteps(h.now, 2500);
      await t.runAsync(h.controller.start);
      await t.pumpWidget(wrap(h.controller));
      await t.tap(find.text('Đổi'));
      await t.pumpAndSettle();
      expect(find.byType(GoalScreen), findsOneWidget);
    });

    testWidgets('màn mục tiêu: nhập không hợp lệ thì báo lỗi', (t) async {
      bigScreen(t);
      final h = Harness();
      addTearDown(h.controller.dispose);
      await t.pumpWidget(wrap(h.controller, home: const GoalScreen()));

      await t.enterText(find.byType(TextField), '0');
      await t.tap(find.text(AppStrings.save));
      await t.pump();
      expect(find.text(AppStrings.goalOutOfRange), findsOneWidget);

      await t.enterText(find.byType(TextField), '');
      await t.tap(find.text(AppStrings.save));
      await t.pump();
      expect(find.text(AppStrings.goalEmpty), findsOneWidget);
      expect(h.repo.goalValue, 100); // không lưu gì
    });

    testWidgets('màn mục tiêu: nhập đúng thì lưu và quay về', (t) async {
      bigScreen(t);
      final h = Harness();
      addTearDown(h.controller.dispose);
      await t.runAsync(h.controller.start);
      await t.pumpWidget(
        wrap(
          h.controller,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<bool>(builder: (_) => const GoalScreen()),
                  ),
                  child: const Text('mở'),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('mở'));
      await t.pumpAndSettle();
      await t.tap(find.text('7.500')); // chọn mục tiêu gợi ý
      await t.pump();
      await t.tap(find.text(AppStrings.save));
      await t.pump();
      await t.pump();
      await t.pumpAndSettle();
      expect(h.repo.goalValue, 7500);
      expect(h.controller.goal, 7500);
      expect(find.byType(GoalScreen), findsNothing);
    });

    testWidgets('màn mục tiêu: lưu thất bại thì báo lỗi và ở lại màn', (t) async {
      bigScreen(t);
      final h = Harness();
      addTearDown(h.controller.dispose);
      await t.runAsync(h.controller.start);
      h.repo.failWrites = true;
      await t.pumpWidget(wrap(h.controller, home: const GoalScreen()));
      await t.enterText(find.byType(TextField), '9000');
      await t.tap(find.text(AppStrings.save));
      await t.pump();
      await t.pump();
      expect(find.text('Không đọc được dữ liệu (giả lập).'), findsOneWidget);
      expect(find.byType(GoalScreen), findsOneWidget);
    });
  });
}
