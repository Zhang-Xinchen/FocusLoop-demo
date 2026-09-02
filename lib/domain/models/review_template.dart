/// Ebbinghaus review curve template.
/// `intervals[i]` is the delay before round `i + 1`.
class ReviewTemplate {
  const ReviewTemplate({
    required this.id,
    required this.name,
    required this.intervals,
  });

  final String id;
  final String name;
  final List<Duration> intervals;

  int get totalRounds => intervals.length;

  /// Delay before the next review after a "forgot" result.
  static const fallbackDelay = Duration(hours: 12);

  /// Standard curve: 1, 2, 4, 7, 15, 30 days.
  static const standard = ReviewTemplate(
    id: 'standard',
    name: 'Standard curve',
    intervals: [
      Duration(days: 1),
      Duration(days: 2),
      Duration(days: 4),
      Duration(days: 7),
      Duration(days: 15),
      Duration(days: 30),
    ],
  );

  /// Compact curve: 12 hours, 1, 2, 4, 7 days.
  static const compact = ReviewTemplate(
    id: 'compact',
    name: 'Compact curve',
    intervals: [
      Duration(hours: 12),
      Duration(days: 1),
      Duration(days: 2),
      Duration(days: 4),
      Duration(days: 7),
    ],
  );

  static const builtIn = [standard, compact];
}
