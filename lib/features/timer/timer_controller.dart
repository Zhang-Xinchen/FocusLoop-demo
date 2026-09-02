import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';

class TimerController extends Notifier<TimerState> {
  static const _engine = TimerEngine();

  @override
  TimerState build() => const TimerState.idle();

  void start(String taskId) {
    state = _engine.start(state, taskId: taskId, now: DateTime.now());
  }

  void pause() {
    state = _engine.pause(state, DateTime.now());
  }

  void resume() {
    state = _engine.resume(state, DateTime.now());
  }

  Future<void> stop() async {
    final deviceId = await ref.read(deviceIdProvider.future);
    final result = _engine.stop(
      state,
      DateTime.now(),
      logId: const Uuid().v4(),
      deviceId: deviceId,
    );
    state = result.state;
    final log = result.log;
    if (log != null) {
      await ref.read(timeLogRepositoryProvider).add(log);
      await ref
          .read(taskRepositoryProvider)
          .addAccumulated(log.taskId, log.durationSeconds);
    }
  }
}

final timerControllerProvider =
    NotifierProvider<TimerController, TimerState>(TimerController.new);
