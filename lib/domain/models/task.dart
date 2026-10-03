enum TaskStatus { active, completed, archived }

/// Task: supports target duration, focus-time accumulation,
/// and optionally enabling Ebbinghaus review.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.note,
    this.categoryId,
    this.dueDate,
    this.targetSeconds = 0,
    this.accumulatedSeconds = 0,
    this.status = TaskStatus.active,
    this.timed = true,
    this.reviewEnabled = false,
    this.reviewTemplateId,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final String title;
  final String? note;
  final String? categoryId;

  /// Optional completion date for this task (a to-do target date).
  final DateTime? dueDate;

  /// Target duration (seconds); 0 means no target is set.
  final int targetSeconds;

  /// Accumulated focus duration (seconds). Cached aggregate of TimeLog.
  final int accumulatedSeconds;
  final TaskStatus status;

  /// Whether this is a timed task. When false, it behaves as a plain
  /// to-do that can be checked off without the timer screen.
  final bool timed;

  /// Whether this is an Ebbinghaus review task.
  final bool reviewEnabled;
  final String? reviewTemplateId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft-delete tombstone; used for multi-device sync.
  final bool deleted;

  bool get hasTarget => targetSeconds > 0;

  /// Progress toward target, clamped to [0, 1]; 0 when no target is set.
  double get progress => hasTarget
      ? (accumulatedSeconds / targetSeconds).clamp(0.0, 1.0)
      : 0.0;

  Task copyWith({
    String? id,
    String? title,
    String? note,
    String? categoryId,
    DateTime? dueDate,
    int? targetSeconds,
    int? accumulatedSeconds,
    TaskStatus? status,
    bool? timed,
    bool? reviewEnabled,
    String? reviewTemplateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      categoryId: categoryId ?? this.categoryId,
      dueDate: dueDate ?? this.dueDate,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      status: status ?? this.status,
      timed: timed ?? this.timed,
      reviewEnabled: reviewEnabled ?? this.reviewEnabled,
      reviewTemplateId: reviewTemplateId ?? this.reviewTemplateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}

/// Orders tasks by due date, nearest first; tasks without a due date
/// keep their original relative order and come before dated tasks.
List<Task> sortTasksByDueDate(List<Task> tasks) {
  final undated = <Task>[];
  final dated = <Task>[];
  for (final task in tasks) {
    if (task.dueDate == null) {
      undated.add(task);
    } else {
      dated.add(task);
    }
  }
  dated.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  return [...undated, ...dated];
}
