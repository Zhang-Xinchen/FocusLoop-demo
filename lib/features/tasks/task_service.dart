import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';
import '../../platform/notification_service.dart';

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
    await repo.save(task);
    final reviewRepo = _ref.read(reviewRepositoryProvider);
    final hasSchedules = await reviewRepo.hasSchedulesFor(task.id);
    if (task.reviewEnabled && !hasSchedules) {
      final plan = const EbbinghausScheduler().firstReview(
        template: templateFor(task),
        now: DateTime.now(),
      );
      final schedule = ReviewSchedule(
        id: const Uuid().v4(),
        taskId: task.id,
        round: plan.round,
        dueAt: plan.dueAt,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _ref.read(reviewRepositoryProvider).save(schedule);
      await NotificationService.instance.scheduleReview(
        scheduleId: schedule.id,
        title: task.title,
        round: schedule.round,
        dueAt: schedule.dueAt,
      );
    }
    if (task.dueDate == null) {
      await NotificationService.instance.cancelTaskDue(task.id);
    } else {
      await _rescheduleTaskDue(task);
    }
  }

  Future<void> toggleComplete(Task task) async {
    final next = task.status == TaskStatus.completed
        ? TaskStatus.active
        : TaskStatus.completed;
    await _ref.read(taskRepositoryProvider).save(
          task.copyWith(status: next, updatedAt: DateTime.now()),
        );
    if (next == TaskStatus.completed) {
      await NotificationService.instance.cancelTaskDue(task.id);
    } else {
      await _rescheduleTaskDue(task);
    }
  }

  Future<void> deleteTask(String taskId) async {
    await _ref.read(taskRepositoryProvider).softDelete(taskId);
    await NotificationService.instance.cancelTaskDue(taskId);
  }

  Future<void> _rescheduleTaskDue(Task task) async {
    if (task.dueDate == null) {
      return;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay =
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final reminderDay = dueDay.isBefore(today) ? today : dueDay;
    await NotificationService.instance.scheduleTaskDueDay(
      taskId: task.id,
      title: task.title,
      day: reminderDay,
    );
  }
}

final taskServiceProvider = Provider<TaskService>((ref) => TaskService(ref));
