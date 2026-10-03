import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';
import 'task_editor.dart';
import 'task_service.dart';
import 'task_tile.dart';

class TasksPage extends ConsumerStatefulWidget {
  const TasksPage({super.key});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  String? _filterCategoryId;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务'),
        actions: [
          IconButton(
            tooltip: '分类管理',
            icon: const Icon(Icons.folder_outlined),
            onPressed: () => context.push('/categories'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('新任务'),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (tasks) {
          final filtered = _filterCategoryId == null
              ? tasks
              : tasks
                  .where((task) => task.categoryId == _filterCategoryId)
                  .toList();
          final active = sortTasksByDueDate(
            filtered
                .where((task) => task.status == TaskStatus.active)
                .toList(),
          );
          final completed = sortTasksByDueDate(
            filtered
                .where((task) => task.status == TaskStatus.completed)
                .toList(),
          );

          if (filtered.isEmpty) {
            return const Center(child: Text('暂无任务'));
          }
          return Column(
            children: [
              SizedBox(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _FilterChip(
                      label: '全部',
                      selected: _filterCategoryId == null,
                      onSelected: () =>
                          setState(() => _filterCategoryId = null),
                    ),
                    for (final category in categories)
                      _FilterChip(
                        label: category.name,
                        color: Color(category.color),
                        selected: _filterCategoryId == category.id,
                        onSelected: () =>
                            setState(() => _filterCategoryId = category.id),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  children: [
                    for (final task in active)
                      _tile(task, categories),
                    if (completed.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('已完成',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final task in completed)
                        _tile(task, categories),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Task task) async {
    if (task.status == TaskStatus.completed) {
      await ref.read(taskServiceProvider).deleteTask(task.id);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('「${task.title}」尚未完成，确定删除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(taskServiceProvider).deleteTask(task.id);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget _tile(Task task, List<Category> categories) {
    return TaskTile(
      task: task,
      category:
          categories.where((c) => c.id == task.categoryId).firstOrNull,
      onTap: task.timed && task.status == TaskStatus.active
          ? () => context.push('/timer/${task.id}')
          : () => showTaskEditor(context, task: task),
      onEdit: () => showTaskEditor(context, task: task),
      onDelete: () => _confirmDelete(task),
      onToggleComplete: () =>
          ref.read(taskServiceProvider).toggleComplete(task),
      onDetail: task.timed ? () => context.push('/task/${task.id}') : null,
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
