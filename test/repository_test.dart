// FILE NÀY ĐỂ LÀM GÌ: Kiểm tra việc lưu và đọc dữ liệu đúng.
// Người phụ trách: Người 2

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:step_tracker/data/app_database.dart';
import 'package:step_tracker/data/in_memory_step_repository.dart';
import 'package:step_tracker/data/sqlite_step_repository.dart';
import 'package:step_tracker/data/step_repository.dart';
import 'package:step_tracker/models/daily_steps.dart';

// NGƯỜI 2. Chạy cùng bộ test cho InMemoryStepRepository và SqliteStepRepository
// (SQLite dùng sqflite_common_ffi, database trong bộ nhớ).
void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final factories = <String, Future<StepRepository> Function()>{
    'InMemoryStepRepository': () async => InMemoryStepRepository(),
    'SqliteStepRepository': () async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      return SqliteStepRepository(db);
    },
  };

  for (final entry in factories.entries) {
    group(entry.key, () {
      late StepRepository repository;

      setUp(() async {
        repository = await entry.value();
      });

      tearDown(() async {
        if (repository is SqliteStepRepository) {
          final r = repository as SqliteStepRepository;
          await r.db.close();
        }
      });

      test('lưu rồi đọc lại một ngày', () async {
        final day = DailySteps(DateTime(2026, 11, 16), 5432);
        await repository.saveDay(day);

        final loaded = await repository.getDay(DateTime(2026, 11, 16));
        expect(loaded, isNotNull);
        expect(loaded?.date, DateTime(2026, 11, 16));
        expect(loaded?.steps, 5432);
      });

      test('ngày chưa có dữ liệu trả về null', () async {
        final loaded = await repository.getDay(DateTime(2026, 1, 1));
        expect(loaded, isNull);
      });

      test('lưu đè cùng ngày', () async {
        final date = DateTime(2026, 11, 16);
        await repository.saveDay(DailySteps(date, 3000));
        await repository.saveDay(DailySteps(date, 7500));

        final loaded = await repository.getDay(date);
        expect(loaded?.steps, 7500);
      });

      test('getRange gồm hai đầu và sắp xếp tăng dần', () async {
        final d1 = DateTime(2026, 11, 10);
        final d2 = DateTime(2026, 11, 12);
        final d3 = DateTime(2026, 11, 15);
        final d4 = DateTime(2026, 11, 20);

        await repository.saveDay(DailySteps(d3, 3000));
        await repository.saveDay(DailySteps(d1, 1000));
        await repository.saveDay(DailySteps(d4, 4000));
        await repository.saveDay(DailySteps(d2, 2000));

        final range = await repository.getRange(d1, d3);
        expect(range.length, 3);
        expect(range[0].date, d1);
        expect(range[0].steps, 1000);
        expect(range[1].date, d2);
        expect(range[1].steps, 2000);
        expect(range[2].date, d3);
        expect(range[2].steps, 3000);
      });

      test('mục tiêu không hợp lệ bị từ chối', () async {
        expect(
          () => repository.setGoal(0),
          throwsA(isA<StepRepositoryException>()),
        );
        expect(
          () => repository.setGoal(-500),
          throwsA(isA<StepRepositoryException>()),
        );

        await repository.setGoal(10000);
        expect(await repository.getGoal(), 10000);
      });

      test('dòng dữ liệu hỏng bị bỏ qua', () async {
        if (repository is SqliteStepRepository) {
          final sqliteRepo = repository as SqliteStepRepository;

          await sqliteRepo.saveDay(DailySteps(DateTime(2026, 11, 16), 5000));

          await sqliteRepo.db.database.rawInsert(
            'INSERT INTO ${AppDatabase.tableDailySteps}(${AppDatabase.columnDate}, ${AppDatabase.columnSteps}) VALUES(?, ?)',
            ['invalid-date-string', 1234],
          );
          await sqliteRepo.db.database.rawInsert(
            'INSERT INTO ${AppDatabase.tableDailySteps}(${AppDatabase.columnDate}, ${AppDatabase.columnSteps}) VALUES(?, ?)',
            ['2026-11-17', -50],
          );

          final list = await sqliteRepo.getRange(
            DateTime(2026, 1, 1),
            DateTime(2026, 12, 31),
          );
          expect(list.length, 1);
          expect(list.first.date, DateTime(2026, 11, 16));
          expect(list.first.steps, 5000);
        } else {
          final res = await repository.getDay(DateTime(2026, 5, 5));
          expect(res, isNull);
        }
      });
    });
  }

  group('Cài đặt các settings phụ', () {
    test('lastSensorValue lưu và đọc đúng', () async {
      final inMemory = InMemoryStepRepository();
      expect(await inMemory.getLastSensorValue(), isNull);
      await inMemory.setLastSensorValue(1500);
      expect(await inMemory.getLastSensorValue(), 1500);

      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final sqliteRepo = SqliteStepRepository(db);
      expect(await sqliteRepo.getLastSensorValue(), isNull);
      await sqliteRepo.setLastSensorValue(2500);
      expect(await sqliteRepo.getLastSensorValue(), 2500);
      await db.close();
    });

    test('lastGoalNotifiedDay lưu và đọc đúng', () async {
      final today = DateTime(2026, 11, 16);

      final inMemory = InMemoryStepRepository();
      expect(await inMemory.getLastGoalNotifiedDay(), isNull);
      await inMemory.setLastGoalNotifiedDay(today);
      expect(await inMemory.getLastGoalNotifiedDay(), DailySteps.dayOf(today));

      final db = await AppDatabase.open(path: inMemoryDatabasePath);
      final sqliteRepo = SqliteStepRepository(db);
      expect(await sqliteRepo.getLastGoalNotifiedDay(), isNull);
      await sqliteRepo.setLastGoalNotifiedDay(today);
      expect(await sqliteRepo.getLastGoalNotifiedDay(), DailySteps.dayOf(today));
      await db.close();
    });
  });
}
