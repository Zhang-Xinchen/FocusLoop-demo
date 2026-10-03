import '../domain/domain.dart';

/// True when the remote row should replace the local row (LWW by updatedAt).
bool remoteWins(DateTime remoteUpdatedAt, DateTime localUpdatedAt) =>
    remoteUpdatedAt.isAfter(localUpdatedAt);

DateTime _dateFrom(Object? value, DateTime fallback) {
  if (value is String) {
    return DateTime.parse(value).toLocal();
  }
  return fallback;
}

String _iso(DateTime value) => value.toUtc().toIso8601String();

Category categoryFromJson(Map<String, dynamic> row) => Category(
      id: row['id'] as String,
      name: row['name'] as String,
      color: (row['color'] as num).toInt(),
      sortOrder: (row['sort_order'] as num).toInt(),
      targetSeconds: (row['target_seconds'] as num? ?? 0).toInt(),
      createdAt: _dateFrom(row['created_at'], DateTime.now()),
      updatedAt: _dateFrom(row['updated_at'], DateTime.now()),
      deleted: row['deleted'] as bool? ?? false,
    );

Map<String, dynamic> categoryToJson(String userId, Category category) => {
      'id': category.id,
      'user_id': userId,
      'name': category.name,
      'color': category.color,
      'sort_order': category.sortOrder,
      'target_seconds': category.targetSeconds,
      'created_at': _iso(category.createdAt),
      'updated_at': _iso(category.updatedAt),
      'deleted': category.deleted,
    };

Task taskFromJson(Map<String, dynamic> row) => Task(
      id: row['id'] as String,
      title: row['title'] as String,
      note: row['note'] as String?,
      categoryId: row['category_id'] as String?,
      dueDate: row['due_date'] == null
          ? null
          : DateTime.parse(row['due_date'] as String).toLocal(),
      targetSeconds: (row['target_seconds'] as num).toInt(),
      accumulatedSeconds: (row['accumulated_seconds'] as num).toInt(),
      status: _taskStatusFrom(row['status'] as String?),
      timed: row['timed'] as bool? ?? false,
      reviewEnabled: row['review_enabled'] as bool? ?? false,
      reviewTemplateId: row['review_template_id'] as String?,
      createdAt: _dateFrom(row['created_at'], DateTime.now()),
      updatedAt: _dateFrom(row['updated_at'], DateTime.now()),
      deleted: row['deleted'] as bool? ?? false,
    );

Map<String, dynamic> taskToJson(String userId, Task task) => {
      'id': task.id,
      'user_id': userId,
      'title': task.title,
      'note': task.note,
      'category_id': task.categoryId,
      'due_date': task.dueDate == null ? null : _iso(task.dueDate!),
      'target_seconds': task.targetSeconds,
      'accumulated_seconds': task.accumulatedSeconds,
      'status': task.status.name,
      'timed': task.timed,
      'review_enabled': task.reviewEnabled,
      'review_template_id': task.reviewTemplateId,
      'created_at': _iso(task.createdAt),
      'updated_at': _iso(task.updatedAt),
      'deleted': task.deleted,
    };

TimeLog timeLogFromJson(Map<String, dynamic> row) => TimeLog(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      deviceId: row['device_id'] as String,
      startedAt: _dateFrom(row['started_at'], DateTime.now()),
      durationSeconds: (row['duration_seconds'] as num).toInt(),
      createdAt: _dateFrom(row['created_at'], DateTime.now()),
    );

Map<String, dynamic> timeLogToJson(String userId, TimeLog log) => {
      'id': log.id,
      'user_id': userId,
      'task_id': log.taskId,
      'device_id': log.deviceId,
      'started_at': _iso(log.startedAt),
      'duration_seconds': log.durationSeconds,
      'created_at': _iso(log.createdAt),
    };

ReviewSchedule reviewFromJson(Map<String, dynamic> row) => ReviewSchedule(
      id: row['id'] as String,
      taskId: row['task_id'] as String,
      round: (row['round'] as num).toInt(),
      dueAt: _dateFrom(row['due_at'], DateTime.now()),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String).toLocal(),
      result: _reviewResultFrom(row['result'] as String?),
      createdAt: _dateFrom(row['created_at'], DateTime.now()),
      updatedAt: _dateFrom(row['updated_at'], DateTime.now()),
      deleted: row['deleted'] as bool? ?? false,
    );

Map<String, dynamic> reviewToJson(String userId, ReviewSchedule review) => {
      'id': review.id,
      'user_id': userId,
      'task_id': review.taskId,
      'round': review.round,
      'due_at': _iso(review.dueAt),
      'completed_at':
          review.completedAt == null ? null : _iso(review.completedAt!),
      'result': review.result?.name,
      'created_at': _iso(review.createdAt),
      'updated_at': _iso(review.updatedAt),
      'deleted': review.deleted,
    };

TaskStatus _taskStatusFrom(String? value) {
  for (final status in TaskStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return TaskStatus.active;
}

ReviewResult? _reviewResultFrom(String? value) => switch (value) {
      'remembered' => ReviewResult.remembered,
      'forgotten' => ReviewResult.forgotten,
      _ => null,
    };
