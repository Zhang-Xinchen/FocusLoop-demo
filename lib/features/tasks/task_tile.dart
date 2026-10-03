import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/linux_progress_bar.dart';
import '../../domain/domain.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.category,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleComplete,
    this.onDetail,
  });

  final Task task;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleComplete;
  final VoidCallback? onDetail;

  bool get _completed => task.status == TaskStatus.completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = task.status == TaskStatus.active &&
        task.dueDate != null &&
        task.dueDate!.isBefore(DateTime.now());
    Widget tile = Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onToggleComplete != null) ...[
                    GestureDetector(
                      onTap: onToggleComplete,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              _completed ? scheme.primary : Colors.transparent,
                          border: Border.all(
                            color:
                                _completed ? scheme.primary : scheme.outline,
                            width: 2,
                          ),
                        ),
                        child: _completed
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (category != null) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Color(category!.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category!.name,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      task.title,
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                decoration: _completed
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: _completed
                                    ? scheme.onSurface.withValues(alpha: 0.5)
                                    : null,
                              ),
                    ),
                  ),
                  if (_completed && onToggleComplete != null)
                    IconButton(
                      tooltip: '还原',
                      icon: const Icon(Icons.replay, size: 20),
                      onPressed: onToggleComplete,
                    ),
                 if (onDetail != null)
                   IconButton(
                     tooltip: '详情',
                     icon: const Icon(Icons.timeline, size: 20),
                     onPressed: onDetail,
                   ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: '编辑',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                    ),
                ],
              ),
              if (task.hasTarget && task.timed) ...[
                const SizedBox(height: 8),
                LinuxProgressBar(value: task.progress, showPercent: true),
                const SizedBox(height: 4),
                Text(
                  '${formatDuration(task.accumulatedSeconds)} / ${formatDuration(task.targetSeconds)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (task.reviewEnabled) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.repeat, size: 14, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '艾宾浩斯复习',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.primary),
                    ),
                  ],
                ),
              ],
              if (task.dueDate != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: overdue ? scheme.error : scheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '完成日期 ${_formatDate(task.dueDate!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: overdue
                                ? scheme.error
                                : scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (onDelete != null) {
      tile = Dismissible(
        key: ValueKey(task.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          color: scheme.error,
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onDismissed: (_) => onDelete!(),
        child: tile,
      );
    }
    return tile;
  }

  String _formatDate(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';
}
