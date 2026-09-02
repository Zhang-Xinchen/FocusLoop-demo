import 'models/time_log.dart';

enum TimerPhase { idle, running, paused }

/// Snapshot of timer state. Immutable; every transition returns a new state.
class TimerState {
  const TimerState.idle()
      : phase = TimerPhase.idle,
        taskId = null,
        sessionStartedAt = null,
        segmentStartedAt = null,
        accumulatedSeconds = 0;

  const TimerState({
    required this.phase,
    required this.taskId,
    required this.sessionStartedAt,
    required this.segmentStartedAt,
    required this.accumulatedSeconds,
  });

  final TimerPhase phase;
  final String? taskId;

  /// The start time of this timing session (used as TimeLog.startedAt).
  final DateTime? sessionStartedAt;

  /// The start time of the current running segment; null while paused.
  final DateTime? segmentStartedAt;

  /// Accumulated seconds excluding the current running segment.
  final int accumulatedSeconds;

  bool get isRunning => phase == TimerPhase.running;
  bool get isPaused => phase == TimerPhase.paused;
}

/// Result of stopping the timer: state resets to idle plus the generated timing record
/// (null when there is no valid accumulated duration).
class TimerStopResult {
  const TimerStopResult({required this.state, required this.log});

  final TimerState state;
  final TimeLog? log;
}

/// Timer state machine.
///
/// All transitions take wall-clock time [now] as input. This lets the app
/// reconcile against real elapsed time after suspension or screen-off,
/// and allows tests to inject arbitrary times.
class TimerEngine {
  const TimerEngine();

  TimerState start(
    TimerState current, {
    required String taskId,
    required DateTime now,
  }) {
    _require(
      current.phase == TimerPhase.idle,
      'An unfinished timing session already exists',
    );
    return TimerState(
      phase: TimerPhase.running,
      taskId: taskId,
      sessionStartedAt: now,
      segmentStartedAt: now,
      accumulatedSeconds: 0,
    );
  }

  TimerState pause(TimerState state, DateTime now) {
    _require(state.phase == TimerPhase.running, 'Only a running timer can be paused');
    return TimerState(
      phase: TimerPhase.paused,
      taskId: state.taskId,
      sessionStartedAt: state.sessionStartedAt,
      segmentStartedAt: null,
      accumulatedSeconds: state.accumulatedSeconds + _segmentSeconds(state, now),
    );
  }

  TimerState resume(TimerState state, DateTime now) {
    _require(state.phase == TimerPhase.paused, 'Only a paused timer can be resumed');
    return TimerState(
      phase: TimerPhase.running,
      taskId: state.taskId,
      sessionStartedAt: state.sessionStartedAt,
      segmentStartedAt: now,
      accumulatedSeconds: state.accumulatedSeconds,
    );
  }

  TimerStopResult stop(
    TimerState state,
    DateTime now, {
    required String logId,
    required String deviceId,
  }) {
    _require(state.phase != TimerPhase.idle, 'There is no active timing session to stop');
    final totalSeconds = state.accumulatedSeconds + _segmentSeconds(state, now);
    final taskId = state.taskId;
    final sessionStartedAt = state.sessionStartedAt;
    final log = totalSeconds > 0 && taskId != null && sessionStartedAt != null
        ? TimeLog(
            id: logId,
            taskId: taskId,
            deviceId: deviceId,
            startedAt: sessionStartedAt,
            durationSeconds: totalSeconds,
            createdAt: now,
          )
        : null;
    return TimerStopResult(state: const TimerState.idle(), log: log);
  }

  int _segmentSeconds(TimerState state, DateTime now) {
    final segmentStartedAt = state.segmentStartedAt;
    if (segmentStartedAt == null) {
      return 0;
    }
    final seconds = now.difference(segmentStartedAt).inSeconds;
    return seconds > 0 ? seconds : 0;
  }

  void _require(bool condition, String message) {
    if (!condition) {
      throw StateError(message);
    }
  }
}
