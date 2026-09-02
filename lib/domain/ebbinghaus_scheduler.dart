import 'dart:math' as math;

import 'models/review_schedule.dart';
import 'models/review_template.dart';

/// The scheduling result for the next review.
class ReviewPlan {
  const ReviewPlan({
    required this.round,
    required this.dueAt,
    this.mastered = false,
  });

  /// All rounds completed; the task is considered mastered.
  factory ReviewPlan.mastered() => ReviewPlan(
        round: 0,
        dueAt: DateTime.fromMillisecondsSinceEpoch(0),
        mastered: true,
      );

  final int round;
  final DateTime dueAt;
  final bool mastered;
}

/// Ebbinghaus forgetting curve review scheduler.
///
/// A pure-function implementation with no framework or storage dependencies,
/// making it easy to unit test.
class EbbinghausScheduler {
  const EbbinghausScheduler();

  /// Schedules the first review after initial learning completes.
  ReviewPlan firstReview({
    required ReviewTemplate template,
    required DateTime now,
  }) {
    if (template.totalRounds == 0) {
      return ReviewPlan.mastered();
    }
    return ReviewPlan(round: 1, dueAt: now.add(template.intervals.first));
  }

  /// Schedules the next review based on the result of this review.
  ///
  /// - remembered: advance one round and delay by that round's interval;
  ///   mark mastered once the final round is completed.
  /// - forgotten: roll back two rounds (minimum round 1) and reappear after 12 hours.
  ReviewPlan nextReview({
    required ReviewSchedule completed,
    required ReviewResult result,
    required ReviewTemplate template,
    required DateTime now,
  }) {
    if (template.totalRounds == 0) {
      return ReviewPlan.mastered();
    }
    switch (result) {
      case ReviewResult.remembered:
        if (completed.round >= template.totalRounds) {
          return ReviewPlan.mastered();
        }
        return ReviewPlan(
          round: completed.round + 1,
          dueAt: now.add(template.intervals[completed.round]),
        );
      case ReviewResult.forgotten:
        final fallbackRound = math.max(1, completed.round - 2);
        return ReviewPlan(
          round: fallbackRound,
          dueAt: now.add(ReviewTemplate.fallbackDelay),
        );
    }
  }
}
