import 'package:drift/drift.dart';

import '../domain/domain.dart';
import 'database.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  Stream<List<Category>> watchCategories() {
    final query = _db.select(_db.categories)
      ..where((c) => c.deleted.equals(false))
      ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<void> save(Category category) {
    return _db
        .into(_db.categories)
        .insertOnConflictUpdate(_toCompanion(category));
  }

  Future<void> softDelete(String id) {
    return (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Category>> allOnceIncludingDeleted() async {
    final rows = await (_db.select(_db.categories)).get();
    return rows.map(_toDomain).toList();
  }

  Category _toDomain(CategoryRow row) => Category(
        id: row.id,
        name: row.name,
        color: row.color,
        sortOrder: row.sortOrder,
        targetSeconds: row.targetSeconds,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deleted: row.deleted,
      );

  CategoriesCompanion _toCompanion(Category category) =>
      CategoriesCompanion.insert(
        id: category.id,
        name: category.name,
        color: category.color,
        sortOrder: Value(category.sortOrder),
        targetSeconds: Value(category.targetSeconds),
        createdAt: category.createdAt,
        updatedAt: category.updatedAt,
        deleted: Value(category.deleted),
      );
}

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  Stream<List<Task>> watchTasks() {
    final query = _db.select(_db.tasks)
      ..where((t) => t.deleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<Task?> get(String id) async {
    final row =
        await (_db.select(_db.tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Future<void> save(Task task) {
    return _db.into(_db.tasks).insertOnConflictUpdate(_toCompanion(task));
  }

  Future<void> addAccumulated(String taskId, int seconds) async {
    final task = await get(taskId);
    if (task == null) {
      return;
    }
    final nextSeconds = task.accumulatedSeconds + seconds;
    final reachedTarget =
        task.hasTarget && nextSeconds >= task.targetSeconds;
    await save(task.copyWith(
      accumulatedSeconds: nextSeconds,
      updatedAt: DateTime.now(),
      status: reachedTarget ? TaskStatus.completed : task.status,
    ));
  }

  Future<void> softDelete(String id) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<List<Task>> allOnce() async {
    final rows = await (_db.select(_db.tasks)
          ..where((t) => t.deleted.equals(false)))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<Task>> allOnceIncludingDeleted() async {
    final rows = await (_db.select(_db.tasks)).get();
    return rows.map(_toDomain).toList();
  }

  Task _toDomain(TaskRow row) => Task(
        id: row.id,
        title: row.title,
        note: row.note,
        categoryId: row.categoryId,
        dueDate: row.dueDate,
        targetSeconds: row.targetSeconds,
        accumulatedSeconds: row.accumulatedSeconds,
        status: row.status,
        timed: row.timed,
        reviewEnabled: row.reviewEnabled,
        reviewTemplateId: row.reviewTemplateId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deleted: row.deleted,
      );

  TasksCompanion _toCompanion(Task task) => TasksCompanion.insert(
        id: task.id,
        title: task.title,
        note: Value(task.note),
        categoryId: Value(task.categoryId),
        dueDate: Value(task.dueDate),
        targetSeconds: Value(task.targetSeconds),
        accumulatedSeconds: Value(task.accumulatedSeconds),
        status: task.status,
        timed: Value(task.timed),
        reviewEnabled: Value(task.reviewEnabled),
        reviewTemplateId: Value(task.reviewTemplateId),
        createdAt: task.createdAt,
        updatedAt: task.updatedAt,
        deleted: Value(task.deleted),
      );
}

class TimeLogRepository {
  TimeLogRepository(this._db);

  final AppDatabase _db;

  Future<void> add(TimeLog log) {
    return _db.into(_db.timeLogs).insertOnConflictUpdate(TimeLogsCompanion.insert(
          id: log.id,
          taskId: log.taskId,
          deviceId: log.deviceId,
          startedAt: log.startedAt,
          durationSeconds: log.durationSeconds,
          createdAt: log.createdAt,
        ));
  }

  Stream<int> watchTotalSeconds() {
    final expr = _db.timeLogs.durationSeconds.sum();
    final query = _db.selectOnly(_db.timeLogs)..addColumns([expr]);
    return query.watchSingle().map((row) => row.read(expr) ?? 0);
  }

  Stream<int> watchTotalSecondsSince(DateTime since) {
    final expr = _db.timeLogs.durationSeconds.sum();
    final query = _db.selectOnly(_db.timeLogs)
      ..addColumns([expr])
      ..where(_db.timeLogs.startedAt.isBiggerOrEqualValue(since));
    return query.watchSingle().map((row) => row.read(expr) ?? 0);
  }

  /// Total focused seconds per calendar day (key = midnight of the day).
  Stream<Map<DateTime, int>> watchDailySeconds() {
    final query = _db.selectOnly(_db.timeLogs)
      ..addColumns([_db.timeLogs.startedAt, _db.timeLogs.durationSeconds]);
    return query.watch().map((rows) {
      final byDay = <DateTime, int>{};
      for (final row in rows) {
        final startedAt = row.read(_db.timeLogs.startedAt);
        final seconds = row.read(_db.timeLogs.durationSeconds) ?? 0;
        if (startedAt == null) {
          continue;
        }
        final day = DateTime(startedAt.year, startedAt.month, startedAt.day);
        byDay[day] = (byDay[day] ?? 0) + seconds;
      }
      return byDay;
    });
  }

  Future<List<TimeLog>> allOnce() async {
    final rows = await (_db.select(_db.timeLogs)).get();
    return rows.map(_toDomain).toList();
  }

  Stream<List<TimeLog>> watchLogsForTask(String taskId) {
    final query = _db.select(_db.timeLogs)
      ..where((log) => log.taskId.equals(taskId))
      ..orderBy([(log) => OrderingTerm.desc(log.startedAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  TimeLog _toDomain(TimeLogRow row) => TimeLog(
        id: row.id,
        taskId: row.taskId,
        deviceId: row.deviceId,
        startedAt: row.startedAt,
        durationSeconds: row.durationSeconds,
        createdAt: row.createdAt,
      );
}

class ReviewRepository {
  ReviewRepository(this._db);

  final AppDatabase _db;

  Stream<List<ReviewSchedule>> watchPending() {
    final query = _db.select(_db.reviewSchedules)
      ..where((r) => r.deleted.equals(false) & r.completedAt.isNull())
      ..orderBy([(r) => OrderingTerm.asc(r.dueAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  Future<void> save(ReviewSchedule schedule) {
    return _db
        .into(_db.reviewSchedules)
        .insertOnConflictUpdate(_toCompanion(schedule));
  }

  Future<void> complete(ReviewSchedule schedule, ReviewResult result) {
    return save(schedule.copyWith(
      completedAt: DateTime.now(),
      result: result,
      updatedAt: DateTime.now(),
    ));
  }

  Future<bool> hasSchedulesFor(String taskId) async {
    final rows = await (_db.select(_db.reviewSchedules)
          ..where((r) => r.taskId.equals(taskId) & r.deleted.equals(false)))
        .get();
    return rows.isNotEmpty;
  }

  Future<List<ReviewSchedule>> pendingOnce() async {
    final rows = await (_db.select(_db.reviewSchedules)
          ..where((r) => r.deleted.equals(false) & r.completedAt.isNull()))
        .get();
    return rows.map(_toDomain).toList();
  }

  Future<List<ReviewSchedule>> allOnceIncludingDeleted() async {
    final rows = await (_db.select(_db.reviewSchedules)).get();
    return rows.map(_toDomain).toList();
  }

  ReviewSchedule _toDomain(ReviewScheduleRow row) => ReviewSchedule(
        id: row.id,
        taskId: row.taskId,
        round: row.round,
        dueAt: row.dueAt,
        completedAt: row.completedAt,
        result: row.result,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        deleted: row.deleted,
      );

  ReviewSchedulesCompanion _toCompanion(ReviewSchedule schedule) =>
      ReviewSchedulesCompanion.insert(
        id: schedule.id,
        taskId: schedule.taskId,
        round: schedule.round,
        dueAt: schedule.dueAt,
        completedAt: Value(schedule.completedAt),
        result: Value(schedule.result),
        createdAt: schedule.createdAt,
        updatedAt: schedule.updatedAt,
        deleted: Value(schedule.deleted),
      );
}

class MetaRepository {
  MetaRepository(this._db);

  final AppDatabase _db;

  Future<String?> get(String key) async {
    final row = await (_db.select(_db.meta)
          ..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> set(String key, String value) {
    return _db
        .into(_db.meta)
        .insertOnConflictUpdate(MetaCompanion.insert(key: key, value: value));
  }
}
