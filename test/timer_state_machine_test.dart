import 'package:flutter_test/flutter_test.dart';

import 'package:focusloop/domain/domain.dart';

void main() {
  const engine = TimerEngine();
  final start = DateTime(2026, 9, 2, 10);

  group('TimerEngine', () {
    test('start enters running from idle', () {
      final state = engine.start(const TimerState.idle(), taskId: 'task-1', now: start);
      expect(state.isRunning, isTrue);
      expect(state.taskId, 'task-1');
      expect(state.sessionStartedAt, start);
    });

    test('start while active throws', () {
      final state = engine.start(const TimerState.idle(), taskId: 'task-1', now: start);
      expect(
        () => engine.start(state, taskId: 'task-2', now: start),
        throwsStateError,
      );
    });

    test('pause accumulates the running segment', () {
      final running = engine.start(const TimerState.idle(), taskId: 'task-1', now: start);
      final paused = engine.pause(running, start.add(const Duration(minutes: 25)));
      expect(paused.isPaused, isTrue);
      expect(paused.accumulatedSeconds, 25 * 60);
    });

    test('multiple pause/resume cycles accumulate correctly', () {
      var state = engine.start(const TimerState.idle(), taskId: 'task-1', now: start);
      state = engine.pause(state, start.add(const Duration(minutes: 10)));
      state = engine.resume(state, start.add(const Duration(minutes: 20)));
      state = engine.pause(state, start.add(const Duration(minutes: 35)));
      expect(state.accumulatedSeconds, 25 * 60);
    });

    test('stop emits a TimeLog with session start and total duration', () {
      var state = engine.start(const TimerState.idle(), taskId: 'task-1', now: start);
      state = engine.pause(state, start.add(const Duration(minutes: 10)));
      state = engine.resume(state, start.add(const Duration(minutes: 30)));
      final result = engine.stop(
        state,
        start.add(const Duration(minutes: 50)),
        logId: 'log-1',
        deviceId: 'device-1',
      );
      expect(result.state.phase, TimerPhase.idle);
      final log = result.log;
      expect(log, isNotNull);
      expect(log!.taskId, 'task-1');
      expect(log.deviceId, 'device-1');
      expect(log.startedAt, start);
      expect(log.durationSeconds, 30 * 60);
    });

    test('stop without accumulated time emits no log', () {
      final state = engine.start(const TimerState.idle(), taskId: 'task-1', now: start);
      final result = engine.stop(state, start, logId: 'log-1', deviceId: 'device-1');
      expect(result.log, isNull);
      expect(result.state.phase, TimerPhase.idle);
    });

    test('clock skew never produces negative durations', () {
      final state = engine.start(const TimerState.idle(), taskId: 'task-1', now: start);
      final paused = engine.pause(state, start.subtract(const Duration(minutes: 1)));
      expect(paused.accumulatedSeconds, 0);
    });

    test('invalid transitions throw', () {
      const idle = TimerState.idle();
      expect(() => engine.pause(idle, start), throwsStateError);
      expect(() => engine.resume(idle, start), throwsStateError);
      expect(
        () => engine.stop(idle, start, logId: 'log-1', deviceId: 'device-1'),
        throwsStateError,
      );
    });
  });

  group('Task progress', () {
    test('progress is clamped to 1.0', () {
      final task = Task(
        id: 'task-1',
        title: 'Deep work',
        targetSeconds: 3600,
        accumulatedSeconds: 7200,
        createdAt: start,
        updatedAt: start,
      );
      expect(task.hasTarget, isTrue);
      expect(task.progress, 1.0);
    });

    test('no target means zero progress', () {
      final task = Task(id: 'task-1', title: 'Reading', createdAt: start, updatedAt: start);
      expect(task.hasTarget, isFalse);
      expect(task.progress, 0.0);
    });
  });
}
