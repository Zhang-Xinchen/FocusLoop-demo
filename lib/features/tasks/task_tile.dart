import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../domain/domain.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    this.category,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Task task;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (onEdit != null)
                    IconButton(
                      tooltip: '编辑',
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                    ),
                ],
              ),
              if (task.hasTarget) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(value: task.progress),
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
}
