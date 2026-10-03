import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';
import '../tasks/task_editor.dart';
import '../tasks/task_service.dart';
import '../tasks/task_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(tasksProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final pending =
        ref.watch(pendingReviewsProvider).valueOrNull ?? const <ReviewSchedule>[];
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('今日')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('新任务'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (tasks) {
          final taskById = {for (final task in tasks) task.id: task};
          final dueReviews = pending
              .where((review) =>
                  review.isDue(now) && taskById.containsKey(review.taskId))
              .toList();
          final today = DateTime(now.year, now.month, now.day);
          final activeTasks = tasks
              .where((task) =>
                  task.status == TaskStatus.active &&
                  task.dueDate != null &&
                  task.dueDate!.year == today.year &&
                  task.dueDate!.month == today.month &&
                  task.dueDate!.day == today.day)
              .toList();

          if (dueReviews.isEmpty && activeTasks.isEmpty) {
            return const _EmptyState();
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              if (dueReviews.isNotEmpty) ...[
                Text('待复习', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final review in dueReviews)
                  _ReviewTile(
                    task: taskById[review.taskId]!,
                    schedule: review,
                    onTap: () => context.push('/review/${review.id}'),
                  ),
                const SizedBox(height: 24),
              ],
              Text('任务', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final task in activeTasks)
                TaskTile(
                  task: task,
                  category: _categoryOf(task, categories),
                  onTap: task.timed
                      ? () => context.push('/timer/${task.id}')
                      : () => showTaskEditor(context, task: task),
                  onEdit: () => showTaskEditor(context, task: task),
                  onToggleComplete: () =>
                      ref.read(taskServiceProvider).toggleComplete(task),
                  onDetail: task.timed
                      ? () => context.push('/task/${task.id}')
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }
}

Category? _categoryOf(Task task, List<Category> categories) {
  final id = task.categoryId;
  if (id == null) {
    return null;
  }
  return categories.where((category) => category.id == id).firstOrNull;
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.task,
    required this.schedule,
    required this.onTap,
  });

  final Task task;
  final ReviewSchedule schedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: scheme.primaryContainer,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.repeat, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '第 ${schedule.round} 轮复习',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.beach_access_outlined, size: 64),
          SizedBox(height: 16),
          Text('今天还没有任务和待复习内容'),
          Text('点击右下角「新任务」开始吧'),
        ],
      ),
    );
  }
}
