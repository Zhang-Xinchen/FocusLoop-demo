import 'package:flutter/material.dart';

const _levelColors = [
  Color(0xFFEBEDF0),
  Color(0xFF9BE9A8),
  Color(0xFF40C463),
  Color(0xFF30A14E),
  Color(0xFF216E39),
  Color(0xFFAA00FF),
];

const _emptyCellDark = Color(0xFF2D333B);

/// Maps focused seconds to a GitHub-style intensity level (0-5).
int contributionLevel(int seconds) {
  if (seconds <= 0) {
    return 0;
  }
  if (seconds <= 120 * 60) {
    return 1;
  }
  if (seconds <= 300 * 60) {
    return 2;
  }
  if (seconds <= 450 * 60) {
    return 3;
  }
  if (seconds <= 599 * 60) {
    return 4;
  }
  return 5;
}

/// Monday of the week containing [date] (midnight).
DateTime startOfWeek(DateTime date) {
  final daysFromMonday = (date.weekday - DateTime.monday) % 7;
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: daysFromMonday));
}

/// Month-grid focus heatmap: shows one month at a time (defaults to the
/// current month). Tapping the month title opens a picker for other
/// years and months; the arrows step month by month.
class MonthHeatmap extends StatefulWidget {
  const MonthHeatmap({
    super.key,
    required this.dailySeconds,
    this.onDayTap,
  });

  final Map<DateTime, int> dailySeconds;
  final void Function(DateTime day, int seconds)? onDayTap;

  @override
  State<MonthHeatmap> createState() => _MonthHeatmapState();
}

class _MonthHeatmapState extends State<MonthHeatmap> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _pickMonth() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(initial: _month),
    );
    if (picked != null) {
      setState(() => _month = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintStyle =
        TextStyle(fontSize: 11, color: Theme.of(context).hintColor);
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = _month.weekday - 1;
    final weekCount = ((leading + daysInMonth) / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final cellSize =
            ((constraints.maxWidth - gap * 6) / 7).clamp(24.0, 56.0);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: '上个月',
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: () => _shiftMonth(-1),
                ),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _pickMonth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        '${_month.year}年${_month.month}月',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '下个月',
                  icon: const Icon(Icons.chevron_right, size: 20),
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final label in const ['一', '二', '三', '四', '五', '六', '日'])
                  SizedBox(
                    width: cellSize + gap,
                    child: Text(label, style: hintStyle),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (var week = 0; week < weekCount; week++)
              Padding(
                padding: EdgeInsets.only(bottom: gap),
                child: Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      _cell(
                        context,
                        week * 7 + col - leading + 1,
                        daysInMonth,
                        todayMidnight,
                        isDark,
                        cellSize,
                        gap,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('少',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hintColor)),
                const SizedBox(width: 4),
                for (var level = 0; level < _levelColors.length; level++)
                  Padding(
                    padding: EdgeInsets.only(right: gap),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: level == 0 && isDark
                            ? _emptyCellDark
                            : _levelColors[level],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                const SizedBox(width: 1),
                Text('多',
                    style: TextStyle(
                        fontSize: 12, color: Theme.of(context).hintColor)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _cell(
    BuildContext context,
    int day,
    int daysInMonth,
    DateTime today,
    bool isDark,
    double cellSize,
    double gap,
  ) {
    if (day < 1 || day > daysInMonth) {
      return SizedBox(width: cellSize + gap, height: cellSize);
    }
    final date = DateTime(_month.year, _month.month, day);
    final isFuture = date.isAfter(today);
    final seconds = widget.dailySeconds[date] ?? 0;
    final level = contributionLevel(seconds);
    final color = isFuture
        ? Colors.transparent
        : level == 0
            ? (isDark ? _emptyCellDark : _levelColors[0])
            : _levelColors[level];
    final isToday = date == today;
    return Padding(
      padding: EdgeInsets.only(right: gap),
      child: GestureDetector(
        onTap: isFuture ? null : () => widget.onDayTap?.call(date, seconds),
        child: Container(
          width: cellSize,
          height: cellSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: isToday
                ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: cellSize * 0.36,
              color: isFuture
                  ? Theme.of(context).hintColor
                  : level >= 3
                      ? Colors.white
                      : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});

  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year;

  @override
  void initState() {
    super.initState();
    _year = widget.initial.year;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(
      now.year + 1 - 2020,
      (index) => now.year + 1 - index,
    );
    return AlertDialog(
      title: const Text('选择年月'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: _year,
              decoration: const InputDecoration(labelText: '年份'),
              items: [
                for (final year in years)
                  DropdownMenuItem(value: year, child: Text('$year 年')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _year = value);
                }
              },
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              children: [
                for (var month = 1; month <= 12; month++)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            _year == widget.initial.year &&
                                    month == widget.initial.month
                                ? Theme.of(context).colorScheme.primary
                                : null,
                        foregroundColor:
                            _year == widget.initial.year &&
                                    month == widget.initial.month
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                      ),
                      onPressed: () => Navigator.of(context)
                          .pop(DateTime(_year, month)),
                      child: Text('$month 月'),
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
