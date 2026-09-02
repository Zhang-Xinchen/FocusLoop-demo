/// One focus timing record. Immutable and append-only.
/// In multi-device sync, records are merged idempotently by id and never conflict.
class TimeLog {
  const TimeLog({
    required this.id,
    required this.taskId,
    required this.deviceId,
    required this.startedAt,
    required this.durationSeconds,
    required this.createdAt,
  });

  final String id;
  final String taskId;

  /// Identifier of the device that generated this record; used for multi-device auditing.
  final String deviceId;

  /// The moment the timing session started (not the start of each paused segment).
  final DateTime startedAt;
  final int durationSeconds;
  final DateTime createdAt;

  Duration get duration => Duration(seconds: durationSeconds);
}
