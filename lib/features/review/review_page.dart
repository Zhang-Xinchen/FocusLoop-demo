import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../domain/domain.dart';
import 'review_controller.dart';

class ReviewPage extends ConsumerWidget {
  const ReviewPage({super.key, required this.scheduleId});

  final String scheduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending =
        ref.watch(pendingReviewsProvider).valueOrNull ?? const <ReviewSchedule>[];
    final schedule = pending.where((r) => r.id == scheduleId).firstOrNull;
    final tasks = ref.watch(tasksProvider).valueOrNull ?? const <Task>[];
    final task = tasks.where((t) => t.id == schedule?.taskId).firstOrNull;

    Future<void> complete(ReviewResult result) async {
      if (schedule == null || task == null) {
        if (context.mounted) {
          context.pop();
        }
        return;
      }
      await ref
          .read(reviewControllerProvider)
          .completeReview(schedule, task, result);
      if (context.mounted) {
        context.pop();
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('复习 · 第 ${schedule?.round ?? '-'} 轮')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                task?.title ?? '任务不存在',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (task?.note != null && task!.note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(task.note!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => complete(ReviewResult.remembered),
                    icon: const Icon(Icons.check),
                    label: const Text('记得'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    onPressed: () => complete(ReviewResult.forgotten),
                    icon: const Icon(Icons.refresh),
                    label: const Text('忘了'),
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
