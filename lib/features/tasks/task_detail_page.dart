import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/linux_progress_bar.dart';
import '../../domain/domain.dart';

class TaskDetailPage extends ConsumerWidget {
  const TaskDetailPage({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref
        .watch(tasksProvider)
        .valueOrNull
        ?.where((candidate) => candidate.id == taskId)
        .firstOrNull;
    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('任务详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final logs = ref.watch(taskTimeLogsProvider(taskId)).valueOrNull ??
        const <TimeLog>[];
    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      floatingActionButton: task.timed && task.status == TaskStatus.active
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/timer/${task.id}'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始专注'),
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _SummaryCard(task: task),
          const SizedBox(height: 12),
          _DailyProgressCard(logs: logs),
          const SizedBox(height: 12),
          _TimelineCard(logs: logs),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining =
        math.max(0, task.targetSeconds - task.accumulatedSeconds);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目标进度', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (task.hasTarget)
              LinuxProgressBar(
                value: task.progress,
                height: 16,
                showPercent: true,
              )
            else
              Text(
                '未设置目标时间，开始专注后会自动累计时长。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: '已完成',
                    value: formatDuration(task.accumulatedSeconds),
                    color: scheme.primary,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: '目标',
                    value: task.hasTarget
                        ? formatDuration(task.targetSeconds)
                        : '未设置',
                    color: scheme.onSurface,
                  ),
                ),
                if (task.hasTarget)
                  Expanded(
                    child: _Metric(
                      label: '剩余',
                      value: formatDuration(remaining),
                      color: scheme.secondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  const _DailyProgressCard({required this.logs});

  final List<TimeLog> logs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final byDay = <DateTime, int>{};
    for (final log in logs) {
      final day =
          DateTime(log.startedAt.year, log.startedAt.month, log.startedAt.day);
      byDay[day] = (byDay[day] ?? 0) + log.durationSeconds;
    }
    final days = [
      for (var offset = 13; offset >= 0; offset--)
        today.subtract(Duration(days: offset)),
    ];
    final maxSeconds = byDay.values.fold<int>(
      1,
      (current, value) => math.max(current, value),
    );
    const weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('近 14 天进度', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 128,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  height: math.max(
                                    4.0,
                                    84 * (byDay[day] ?? 0) / maxSeconds,
                                  ),
                                  decoration: BoxDecoration(
                                    color: scheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              weekdayLabels[day.weekday - 1],
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.logs});

  final List<TimeLog> logs;

  @override
  Widget build(BuildContext context) {
    final grouped = <DateTime, List<TimeLog>>{};
    for (final log in logs) {
      final day =
          DateTime(log.startedAt.year, log.startedAt.month, log.startedAt.day);
      grouped.putIfAbsent(day, () => []).add(log);
    }
    final days = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('专注时间线', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (logs.isEmpty)
              Text(
                '还没有专注记录，开始一次计时后这里会显示进度。',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              for (var dayIndex = 0; dayIndex < days.length; dayIndex++) ...[
                _DayHeader(day: days[dayIndex]),
                for (var logIndex = 0;
                    logIndex < grouped[days[dayIndex]]!.length;
                    logIndex++)
                  _TimelineItem(
                    log: grouped[days[dayIndex]]![logIndex],
                    isLast:
                        dayIndex == days.length - 1 &&
                            logIndex == grouped[days[dayIndex]]!.length - 1,
                  ),
              ],
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final label = day == today
        ? '今天'
        : day == yesterday
            ? '昨天'
            : '${day.month}月${day.day}日';
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.log,
    required this.isLast,
  });

  final TimeLog log;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final startedAt = log.startedAt;
    final endedAt = log.startedAt.add(Duration(seconds: log.durationSeconds));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: scheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _timeLabel(startedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _timeLabel(endedAt),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formatDuration(log.durationSeconds),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _timeLabel(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(time.hour)}:${two(time.minute)}';
  }
}
