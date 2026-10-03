import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../domain/domain.dart';
import 'timer_controller.dart';

class TimerPage extends ConsumerWidget {
  const TimerPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
    final task = tasks.where((t) => t.id == taskId).firstOrNull;
    final timerState = ref.watch(timerControllerProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final controller = ref.read(timerControllerProvider.notifier);

    final isCurrentTask =
        timerState.taskId == taskId && timerState.phase != TimerPhase.idle;

    var liveSeconds = task?.accumulatedSeconds ?? 0;
    if (isCurrentTask) {
      liveSeconds += timerState.accumulatedSeconds;
      final segmentStartedAt = timerState.segmentStartedAt;
      if (timerState.isRunning && segmentStartedAt != null) {
        final delta = now.difference(segmentStartedAt).inSeconds;
        liveSeconds += delta > 0 ? delta : 0;
      }
    }

    final double? progress;
    if (task != null && task.hasTarget) {
      progress = (liveSeconds / task.targetSeconds).clamp(0.0, 1.0);
    } else {
      progress = null;
    }

    return Scaffold(
      appBar: AppBar(title: Text(task?.title ?? '计时')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ProgressRing(progress: progress, label: formatClock(liveSeconds)),
              const SizedBox(height: 16),
              if (task != null && task.hasTarget)
                Text(
                  '目标 ${formatDuration(task.targetSeconds)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              const SizedBox(height: 40),
              if (!isCurrentTask)
                FilledButton.icon(
                  onPressed: () => controller.start(taskId),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始专注'),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          timerState.isRunning ? controller.pause : controller.resume,
                      icon:
                          Icon(timerState.isRunning ? Icons.pause : Icons.play_arrow),
                      label: Text(timerState.isRunning ? '暂停' : '继续'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      onPressed: () => controller.stop(),
                      icon: const Icon(Icons.stop),
                      label: const Text('结束'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.label,
    this.size = 240,
  });

  final double? progress;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: progress,
          color: scheme.primary,
          track: scheme.surfaceContainerHighest,
        ),
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.color,
    required this.track,
  });

  final double? progress;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);
    final value = progress;
    if (value != null && value > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * value,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.track != track;
}
