import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import 'heatmap.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalSeconds = ref.watch(totalSecondsProvider).valueOrNull ?? 0;
    final todaySeconds = ref.watch(todaySecondsProvider).valueOrNull ?? 0;
    final taskCount = ref.watch(tasksProvider).valueOrNull?.length ?? 0;
    final dailySeconds = ref.watch(dailySecondsProvider).valueOrNull ?? {};

    return Scaffold(
      appBar: AppBar(title: const Text('统计')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '专注热力图',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '本月每天的专注时长，颜色越深表示专注越久；点击月份可查看其他年月',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                  ),
                  const SizedBox(height: 12),
                  MonthHeatmap(
                    dailySeconds: dailySeconds,
                    onDayTap: (day, seconds) =>
                        _showDayDetail(context, day, seconds),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _StatCard(
            icon: Icons.today,
            title: '今日专注',
            value: formatDuration(todaySeconds),
          ),
          _StatCard(
            icon: Icons.timer,
            title: '累计专注',
            value: formatDuration(totalSeconds),
          ),
          _StatCard(
            icon: Icons.task_alt,
            title: '任务数',
            value: '$taskCount',
          ),
        ],
      ),
    );
  }

  void _showDayDetail(BuildContext context, DateTime day, int seconds) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${day.year}年${day.month}月${day.day}日'),
        content: Text(
          seconds > 0 ? '专注 ${formatDuration(seconds)}' : '当天没有专注记录',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
