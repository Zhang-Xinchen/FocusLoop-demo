import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';
import '../../platform/notification_service.dart';
import '../tasks/task_service.dart';

class ReviewController {
  ReviewController(this._ref);

  final Ref _ref;

  Future<void> completeReview(
    ReviewSchedule schedule,
    Task task,
    ReviewResult result,
  ) async {
    await _ref.read(reviewRepositoryProvider).complete(schedule, result);
    await NotificationService.instance.cancelReview(schedule.id);
    final plan = const EbbinghausScheduler().nextReview(
      completed: schedule,
      result: result,
      template: templateFor(task),
      now: DateTime.now(),
    );
    if (plan.mastered) {
      return;
    }
    final next = ReviewSchedule(
      id: const Uuid().v4(),
      taskId: schedule.taskId,
      round: plan.round,
      dueAt: plan.dueAt,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _ref.read(reviewRepositoryProvider).save(next);
    await NotificationService.instance.scheduleReview(
      scheduleId: next.id,
      title: task.title,
      round: next.round,
      dueAt: next.dueAt,
    );
  }
}

final reviewControllerProvider =
    Provider<ReviewController>((ref) => ReviewController(ref));
