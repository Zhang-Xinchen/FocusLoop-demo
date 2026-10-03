import 'package:drift/drift.dart';

import '../domain/models/review_schedule.dart';
import '../domain/models/task.dart';
import 'connection.dart' if (dart.library.js_interop) 'connection_web.dart';

part 'database.g.dart';

@DataClassName('CategoryRow')
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get targetSeconds => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TaskRow')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get targetSeconds => integer().withDefault(const Constant(0))();
  IntColumn get accumulatedSeconds => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<TaskStatus>()();
  BoolColumn get timed => boolean().withDefault(const Constant(true))();
  BoolColumn get reviewEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get reviewTemplateId => text().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TimeLogRow')
class TimeLogs extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get deviceId => text()();
  DateTimeColumn get startedAt => dateTime()();
  IntColumn get durationSeconds => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReviewScheduleRow')
class ReviewSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  IntColumn get round => integer()();
  DateTimeColumn get dueAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get result => textEnum<ReviewResult>().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [Categories, Tasks, TimeLogs, ReviewSchedules, Meta])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) => m.createAll(),
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          if (!await _hasColumn(m, 'tasks', 'timed')) {
            await m.addColumn(tasks, tasks.timed);
          }
        }
        if (from < 3) {
          if (!await _hasColumn(m, 'tasks', 'due_date')) {
            await m.addColumn(tasks, tasks.dueDate);
          }
        }
        if (from < 4) {
          if (!await _hasColumn(m, 'categories', 'target_seconds')) {
            await m.addColumn(categories, categories.targetSeconds);
          }
        }
      },
    );
  }

  Future<bool> _hasColumn(Migrator m, String table, String column) async {
    final rows = await m.database.customSelect('PRAGMA table_info($table)').get();
    return rows.any((row) => row.read<String>('name') == column);
  }
}

AppDatabase openAppDatabase() => AppDatabase(openConnection());
