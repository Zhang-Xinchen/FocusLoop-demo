import 'package:drift/drift.dart';

import '../domain/models/review_schedule.dart';
import '../domain/models/task.dart';
import 'connection.dart' if (dart.library.js_interop) 'connection_web.dart';

part 'database.g.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  IntColumn get targetSeconds => integer().withDefault(const Constant(0))();
  IntColumn get accumulatedSeconds => integer().withDefault(const Constant(0))();
  TextColumn get status => textEnum<TaskStatus>()();
  BoolColumn get reviewEnabled => boolean().withDefault(const Constant(false))();
  TextColumn get reviewTemplateId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

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
  int get schemaVersion => 1;
}

AppDatabase openAppDatabase() => AppDatabase(openConnection());
