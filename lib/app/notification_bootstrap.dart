import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/domain.dart';
import '../platform/notification_service.dart';
import 'providers.dart';

/// Initializes notifications on startup and re-schedules reminders for
/// pending reviews and due tasks (the OS may have cleared them).
final notificationBootstrapProvider = FutureProvider<void>((ref) async {
  final service = NotificationService.instance;
  await service.init();
  await service.requestPermissions();

  final reviews = await ref.read(reviewRepositoryProvider).pendingOnce();
  final tasks = await ref.read(taskRepositoryProvider).allOnce();
  final meta = ref.read(metaRepositoryProvider);
  final taskById = {for (final task in tasks) task.id: task};

  for (final review in reviews) {
    final task = taskById[review.taskId];
    if (task == null) {
      continue;
    }
    await service.scheduleReview(
      scheduleId: review.id,
      title: task.title,
      round: review.round,
      dueAt: review.dueAt,
    );
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  for (final task in tasks) {
    if (task.status != TaskStatus.active || task.dueDate == null) {
      continue;
    }
    final dueDay =
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final overdue = dueDay.isBefore(today);
    final reminderDay = overdue ? today : dueDay;

    await service.scheduleTaskDueDay(
      taskId: task.id,
      title: task.title,
      day: reminderDay,
    );

    var latestPassed = -1;
    for (var i = 0; i < NotificationService.dueReminderSlots.length; i++) {
      if (!reminderDay.add(NotificationService.dueReminderSlots[i]).isAfter(now)) {
        latestPassed = i;
      }
    }
    if (latestPassed < 0) {
      continue;
    }
    final flagKey = 'task_due_notified:${task.id}:'
        '${reminderDay.millisecondsSinceEpoch}:$latestPassed';
    final notified = await meta.get(flagKey);
    if (notified != null) {
      continue;
    }
    await service.showTaskDueNow(
      task.id,
      task.title,
      overdue: overdue,
      slotKey: NotificationService.taskDueSlotKeys[latestPassed],
    );
    await meta.set(flagKey, '1');
  }
});
