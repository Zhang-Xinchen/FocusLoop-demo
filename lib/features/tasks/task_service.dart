import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';

ReviewTemplate templateFor(Task task) {
  final id = task.reviewTemplateId ?? ReviewTemplate.standard.id;
  return ReviewTemplate.builtIn.firstWhere(
    (template) => template.id == id,
    orElse: () => ReviewTemplate.standard,
  );
}

class TaskService {
  TaskService(this._ref);

  final Ref _ref;

  Future<void> saveTask(Task task) async {
    final repo = _ref.read(taskRepositoryProvider);
    final isNew = await repo.get(task.id) == null;
    await repo.save(task);
    if (isNew && task.reviewEnabled) {
      final plan = const EbbinghausScheduler().firstReview(
        template: templateFor(task),
        now: DateTime.now(),
      );
      await _ref.read(reviewRepositoryProvider).save(ReviewSchedule(
            id: const Uuid().v4(),
            taskId: task.id,
            round: plan.round,
            dueAt: plan.dueAt,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ));
    }
  }
}

final taskServiceProvider = Provider<TaskService>((ref) => TaskService(ref));
