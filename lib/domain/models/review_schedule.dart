enum ReviewResult { remembered, forgotten }

/// Review plan for one round of a review task.
/// When `dueAt` arrives and it has not been completed, the task "reappears" in the due-reviews list.
class ReviewSchedule {
  const ReviewSchedule({
    required this.id,
    required this.taskId,
    required this.round,
    required this.dueAt,
    this.completedAt,
    this.result,
    required this.createdAt,
    required this.updatedAt,
    this.deleted = false,
  });

  final String id;
  final String taskId;
  final int round;
  final DateTime dueAt;
  final DateTime? completedAt;
  final ReviewResult? result;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Soft-delete tombstone; used for multi-device sync.
  final bool deleted;

  bool get isPending => completedAt == null;

  bool isDue(DateTime now) => isPending && !dueAt.isAfter(now);

  ReviewSchedule copyWith({
    String? id,
    String? taskId,
    int? round,
    DateTime? dueAt,
    DateTime? completedAt,
    ReviewResult? result,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? deleted,
  }) {
    return ReviewSchedule(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      round: round ?? this.round,
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
      result: result ?? this.result,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}
