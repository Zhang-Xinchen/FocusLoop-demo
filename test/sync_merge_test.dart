import 'package:flutter_test/flutter_test.dart';
import 'package:focusloop/data/sync_merge.dart';
import 'package:focusloop/domain/domain.dart';

void main() {
  group('remoteWins', () {
    test('newer remote timestamp wins', () {
      final remote = DateTime(2026, 9, 4, 10);
      final local = DateTime(2026, 9, 4, 9);
      expect(remoteWins(remote, local), isTrue);
    });

    test('older remote timestamp loses', () {
      final remote = DateTime(2026, 9, 4, 9);
      final local = DateTime(2026, 9, 4, 10);
      expect(remoteWins(remote, local), isFalse);
    });

    test('equal timestamps keep the local row', () {
      final time = DateTime(2026, 9, 4, 10);
      expect(remoteWins(time, time), isFalse);
    });
  });

  group('json round trips', () {
    test('category keeps every field including tombstone', () {
      final category = Category(
        id: 'c1',
        name: '考试复习',
        color: 0xFF4A90D9,
        sortOrder: 3,
        targetSeconds: 3600,
        createdAt: DateTime(2026, 9, 1, 8),
        updatedAt: DateTime(2026, 9, 3, 20, 30),
        deleted: true,
      );
      final restored = categoryFromJson(categoryToJson('user-1', category));
      expect(restored.id, category.id);
      expect(restored.name, category.name);
      expect(restored.color, category.color);
      expect(restored.sortOrder, category.sortOrder);
      expect(restored.targetSeconds, category.targetSeconds);
      expect(restored.deleted, isTrue);
      expect(restored.updatedAt, category.updatedAt);
    });

    test('task keeps status, timing and review flags', () {
      final task = Task(
        id: 't1',
        title: '背单词',
        note: '每天 50 个',
        categoryId: 'c1',
        dueDate: DateTime(2026, 9, 10),
        targetSeconds: 1800,
        accumulatedSeconds: 720,
        status: TaskStatus.completed,
        timed: false,
        reviewEnabled: true,
        reviewTemplateId: 'standard',
        createdAt: DateTime(2026, 9, 1, 8),
        updatedAt: DateTime(2026, 9, 2, 12),
      );
      final restored = taskFromJson(taskToJson('user-1', task));
      expect(restored.id, task.id);
      expect(restored.title, task.title);
      expect(restored.targetSeconds, task.targetSeconds);
      expect(restored.dueDate, task.dueDate);
      expect(restored.accumulatedSeconds, task.accumulatedSeconds);
      expect(restored.status, TaskStatus.completed);
      expect(restored.timed, isFalse);
      expect(restored.reviewEnabled, isTrue);
      expect(restored.reviewTemplateId, 'standard');
    });

    test('time log keeps identity and duration', () {
      final log = TimeLog(
        id: 'l1',
        taskId: 't1',
        deviceId: 'device-a',
        startedAt: DateTime(2026, 9, 4, 9, 15),
        durationSeconds: 720,
        createdAt: DateTime(2026, 9, 4, 9, 15),
      );
      final restored = timeLogFromJson(timeLogToJson('user-1', log));
      expect(restored.id, log.id);
      expect(restored.taskId, log.taskId);
      expect(restored.deviceId, log.deviceId);
      expect(restored.durationSeconds, log.durationSeconds);
    });

    test('completed review keeps result and completion time', () {
      final review = ReviewSchedule(
        id: 'r1',
        taskId: 't1',
        round: 2,
        dueAt: DateTime(2026, 9, 4, 9),
        completedAt: DateTime(2026, 9, 4, 10),
        result: ReviewResult.remembered,
        createdAt: DateTime(2026, 9, 3),
        updatedAt: DateTime(2026, 9, 4, 10),
      );
      final restored = reviewFromJson(reviewToJson('user-1', review));
      expect(restored.round, review.round);
      expect(restored.completedAt, review.dueAt.add(const Duration(hours: 1)));
      expect(restored.result, ReviewResult.remembered);
    });
  });
}
