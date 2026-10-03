import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../domain/domain.dart';
import '../features/timer/timer_controller.dart';
import 'providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _destinations = [
    (path: '/', icon: Icons.today_outlined, label: '今日'),
    (path: '/tasks', icon: Icons.task_alt_outlined, label: '任务'),
    (path: '/stats', icon: Icons.bar_chart_outlined, label: '统计'),
    (path: '/settings', icon: Icons.settings_outlined, label: '设置'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final index = _destinations.indexWhere((d) => d.path == location);
    final selectedIndex = index < 0 ? 0 : index;

    final timerState = ref.watch(timerControllerProvider);
    final now = timerState.phase == TimerPhase.idle
        ? DateTime.now()
        : ref.watch(clockProvider).value ?? DateTime.now();
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
    final runningTask = timerState.phase == TimerPhase.idle
        ? null
        : tasks.where((task) => task.id == timerState.taskId).firstOrNull;

    Widget body = child;
    if (runningTask != null) {
      final bar = _RunningTimerBar(
        task: runningTask,
        state: timerState,
        now: now,
        onTap: () => context.go('/timer/${runningTask.id}'),
      );
      body = Column(
        children: [
          SafeArea(bottom: false, child: bar),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) =>
                      context.go(_destinations[i].path),
                  labelType: NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in _destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(_destinations[i].path),
            destinations: [
              for (final destination in _destinations)
                NavigationDestination(
                  icon: Icon(destination.icon),
                  label: destination.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RunningTimerBar extends StatelessWidget {
  const _RunningTimerBar({
    required this.task,
    required this.state,
    required this.now,
    required this.onTap,
  });

  final Task task;
  final TimerState state;
  final DateTime now;
  final VoidCallback onTap;

  int get _sessionSeconds {
    var seconds = state.accumulatedSeconds;
    final segmentStartedAt = state.segmentStartedAt;
    if (state.isRunning && segmentStartedAt != null) {
      final delta = now.difference(segmentStartedAt).inSeconds;
      seconds += delta > 0 ? delta : 0;
    }
    return seconds;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                state.isRunning ? Icons.timer : Icons.pause_circle_outline,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '正在计时：${task.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                    Text(
                      state.isRunning ? '计时进行中' : '已暂停',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                formatClock(_sessionSeconds),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              Icon(Icons.chevron_right, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
