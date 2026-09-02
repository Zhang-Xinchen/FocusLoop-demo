import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';
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
    final plan = const EbbinghausScheduler().nextReview(
      completed: schedule,
      result: result,
      template: templateFor(task),
      now: DateTime.now(),
    );
    if (plan.mastered) {
      return;
    }
    await _ref.read(reviewRepositoryProvider).save(ReviewSchedule(
          id: const Uuid().v4(),
          taskId: schedule.taskId,
          round: plan.round,
          dueAt: plan.dueAt,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
  }
}

final reviewControllerProvider =
    Provider<ReviewController>((ref) => ReviewController(ref));
