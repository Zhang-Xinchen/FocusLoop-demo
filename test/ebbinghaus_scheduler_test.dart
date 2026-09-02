import 'package:flutter_test/flutter_test.dart';

import 'package:focusloop/domain/domain.dart';

void main() {
  const scheduler = EbbinghausScheduler();
  final now = DateTime(2026, 9, 2, 9);

  ReviewSchedule schedule({required int round, DateTime? dueAt}) {
    return ReviewSchedule(
      id: 's$round',
      taskId: 'task-1',
      round: round,
      dueAt: dueAt ?? now,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('firstReview', () {
    test('Standard curve first review is due after 1 day', () {
      final plan = scheduler.firstReview(
        template: ReviewTemplate.standard,
        now: now,
      );
      expect(plan.round, 1);
      expect(plan.mastered, isFalse);
      expect(plan.dueAt, now.add(const Duration(days: 1)));
    });

    test('Compact curve first review is due after 12 hours', () {
      final plan = scheduler.firstReview(
        template: ReviewTemplate.compact,
        now: now,
      );
      expect(plan.dueAt, now.add(const Duration(hours: 12)));
    });

    test('Empty template is mastered immediately', () {
      const empty = ReviewTemplate(id: 'empty', name: 'empty', intervals: []);
      final plan = scheduler.firstReview(template: empty, now: now);
      expect(plan.mastered, isTrue);
    });
  });

  group('nextReview remembered', () {
    test('Advances one round with the matching interval', () {
      final plan = scheduler.nextReview(
        completed: schedule(round: 1),
        result: ReviewResult.remembered,
        template: ReviewTemplate.standard,
        now: now,
      );
      expect(plan.round, 2);
      expect(plan.dueAt, now.add(const Duration(days: 2)));
    });

    test('Mastered after completing the final round', () {
      final plan = scheduler.nextReview(
        completed: schedule(round: ReviewTemplate.standard.totalRounds),
        result: ReviewResult.remembered,
        template: ReviewTemplate.standard,
        now: now,
      );
      expect(plan.mastered, isTrue);
    });
  });

  group('nextReview forgotten', () {
    test('Falls back 2 rounds and is due after 12 hours', () {
      final plan = scheduler.nextReview(
        completed: schedule(round: 4),
        result: ReviewResult.forgotten,
        template: ReviewTemplate.standard,
        now: now,
      );
      expect(plan.round, 2);
      expect(plan.dueAt, now.add(ReviewTemplate.fallbackDelay));
    });

    test('Fallback round is floored at 1', () {
      for (final round in const [1, 2, 3]) {
        final plan = scheduler.nextReview(
          completed: schedule(round: round),
          result: ReviewResult.forgotten,
          template: ReviewTemplate.standard,
          now: now,
        );
        expect(plan.round, 1, reason: 'round $round should fall back to 1');
      }
    });
  });

  group('ReviewSchedule', () {
    test('isDue only when overdue and not completed', () {
      final overdue = schedule(
        round: 1,
        dueAt: now.subtract(const Duration(minutes: 1)),
      );
      final upcoming = schedule(
        round: 1,
        dueAt: now.add(const Duration(minutes: 1)),
      );
      final completed = overdue.copyWith(
        completedAt: now,
        result: ReviewResult.remembered,
      );
      expect(overdue.isDue(now), isTrue);
      expect(upcoming.isDue(now), isFalse);
      expect(completed.isDue(now), isFalse);
    });
  });
}
