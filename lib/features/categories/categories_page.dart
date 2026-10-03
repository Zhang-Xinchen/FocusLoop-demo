import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/linux_progress_bar.dart';
import '../../domain/domain.dart';
import 'category_editor.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
    final repo = ref.watch(categoryRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('分类管理')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('新分类'),
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('暂无分类，点击右下角添加'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              for (final category in categories)
                _CategoryCard(
                  category: category,
                  accumulatedSeconds: tasks
                      .where((task) => task.categoryId == category.id)
                      .fold(0, (sum, task) => sum + task.accumulatedSeconds),
                  onEdit: () => showCategoryEditor(
                    context,
                    ref,
                    category: category,
                  ),
                  onDelete: () => repo.softDelete(category.id),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.accumulatedSeconds,
    required this.onEdit,
    required this.onDelete,
  });

  final Category category;
  final int accumulatedSeconds;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Color(category.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: '修改',
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: '删除',
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (category.hasTarget) ...[
                LinuxProgressBar(
                  value: category.targetSeconds > 0
                      ? accumulatedSeconds / category.targetSeconds
                      : 0,
                  showPercent: true,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDuration(accumulatedSeconds)} / ${formatDuration(category.targetSeconds)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ] else
                Text(
                  '累计专注 ${formatDuration(accumulatedSeconds)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}


