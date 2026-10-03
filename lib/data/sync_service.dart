import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/domain.dart';
import 'repositories.dart';
import 'sync_merge.dart';

/// Local-first sync engine. Safe to call repeatedly; rows coming from the
/// other device win whenever their `updatedAt` is newer (LWW).
class SyncService {
  SyncService({
    required this.client,
    required this.categories,
    required this.tasks,
    required this.timeLogs,
    required this.reviews,
  });

  final SupabaseClient client;
  final CategoryRepository categories;
  final TaskRepository tasks;
  final TimeLogRepository timeLogs;
  final ReviewRepository reviews;

  static const _tableCategories = 'categories';
  static const _tableTasks = 'tasks';
  static const _tableTimeLogs = 'time_logs';
  static const _tableReviews = 'review_schedules';

  Future<void> syncNow() async {
    final session = client.auth.currentSession;
    if (session == null) {
      return;
    }
    final userId = session.user.id;
    await _syncCategories(userId);
    await _syncTasks(userId);
    await _syncReviews(userId);
    await _syncTimeLogs(userId);
  }

  Future<void> _syncCategories(String userId) async {
    final local = await categories.allOnceIncludingDeleted();
    await _mergeMutable<Category>(
      table: _tableCategories,
      userId: userId,
      local: local,
      fromJson: categoryFromJson,
      toJson: categoryToJson,
      idOf: (category) => category.id,
      updatedAtOf: (category) => category.updatedAt,
      saveLocal: categories.save,
    );
  }

  Future<void> _syncTasks(String userId) async {
    final local = await tasks.allOnceIncludingDeleted();
    await _mergeMutable<Task>(
      table: _tableTasks,
      userId: userId,
      local: local,
      fromJson: taskFromJson,
      toJson: taskToJson,
      idOf: (task) => task.id,
      updatedAtOf: (task) => task.updatedAt,
      saveLocal: tasks.save,
    );
  }

  Future<void> _syncReviews(String userId) async {
    final local = await reviews.allOnceIncludingDeleted();
    await _mergeMutable<ReviewSchedule>(
      table: _tableReviews,
      userId: userId,
      local: local,
      fromJson: reviewFromJson,
      toJson: reviewToJson,
      idOf: (review) => review.id,
      updatedAtOf: (review) => review.updatedAt,
      saveLocal: reviews.save,
    );
  }

  Future<void> _syncTimeLogs(String userId) async {
    final localLogs = await timeLogs.allOnce();
    final localIds = {for (final log in localLogs) log.id};
    final remoteRows = await _fetchRows(_tableTimeLogs, userId);
    final remoteIds = <String>{};
    for (final row in remoteRows) {
      final log = timeLogFromJson(row);
      remoteIds.add(log.id);
      if (!localIds.contains(log.id)) {
        await timeLogs.add(log);
      }
    }
    for (final log in localLogs) {
      if (!remoteIds.contains(log.id)) {
        await _upsert(_tableTimeLogs, timeLogToJson(userId, log));
      }
    }
  }

  Future<void> _mergeMutable<T>({
    required String table,
    required String userId,
    required List<T> local,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(String, T) toJson,
    required String Function(T) idOf,
    required DateTime Function(T) updatedAtOf,
    required Future<void> Function(T) saveLocal,
  }) async {
    final remoteRows = await _fetchRows(table, userId);
    final localById = {for (final item in local) idOf(item): item};
    final remoteSnapshots = <String, Map<String, dynamic>>{};

    for (final row in remoteRows) {
      final id = row['id'] as String;
      remoteSnapshots[id] = row;
      final remoteItem = fromJson(row);
      final localItem = localById[id];
      if (localItem == null ||
          remoteWins(updatedAtOf(remoteItem), updatedAtOf(localItem))) {
        await saveLocal(remoteItem);
      }
    }

    for (final item in local) {
      final id = idOf(item);
      final remoteRow = remoteSnapshots[id];
      if (remoteRow == null) {
        await _upsert(table, toJson(userId, item));
        continue;
      }
      final remoteItem = fromJson(remoteRow);
      if (remoteWins(updatedAtOf(item), updatedAtOf(remoteItem))) {
        await _upsert(table, toJson(userId, item));
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchRows(
    String table,
    String userId,
  ) async {
    final response = await client.from(table).select().eq('user_id', userId);
    final rows = response as List<dynamic>;
    return rows
        .map((row) => Map<String, dynamic>.from(row as Map<dynamic, dynamic>))
        .toList();
  }

  Future<void> _upsert(String table, Map<String, dynamic> row) async {
    await client.from(table).upsert(row, onConflict: 'id');
  }
}
