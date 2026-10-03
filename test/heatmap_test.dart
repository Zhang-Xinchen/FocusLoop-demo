import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusloop/features/stats/heatmap.dart';

void main() {
  group('contributionLevel', () {
    test('zero seconds is level 0', () {
      expect(contributionLevel(0), 0);
    });

    test('1 to 120 minutes is level 1', () {
      expect(contributionLevel(1), 1);
      expect(contributionLevel(120 * 60), 1);
    });

    test('121 to 300 minutes is level 2', () {
      expect(contributionLevel(121 * 60), 2);
      expect(contributionLevel(300 * 60), 2);
    });

    test('301 to 450 minutes is level 3', () {
      expect(contributionLevel(301 * 60), 3);
      expect(contributionLevel(450 * 60), 3);
    });

    test('451 to 599 minutes is level 4', () {
      expect(contributionLevel(451 * 60), 4);
      expect(contributionLevel(599 * 60), 4);
    });

    test('600 minutes and above is level 5', () {
      expect(contributionLevel(600 * 60), 5);
      expect(contributionLevel(20 * 3600), 5);
    });
  });

  group('startOfWeek', () {
    test('Friday maps back to Monday of the same week', () {
      // 2026-09-04 is a Friday.
      final friday = DateTime(2026, 9, 4);
      expect(startOfWeek(friday), DateTime(2026, 8, 31));
    });

    test('Sunday maps back to Monday of the same week', () {
      final sunday = DateTime(2026, 9, 6);
      expect(startOfWeek(sunday), DateTime(2026, 8, 31));
    });

    test('Monday stays on the same day', () {
      final monday = DateTime(2026, 8, 31);
      expect(startOfWeek(monday), monday);
    });
  });

  testWidgets('month heatmap shows current month and legend', (tester) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthHeatmap(dailySeconds: {}),
          ),
        ),
      ),
    );

    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
    expect(find.text('少'), findsOneWidget);
    expect(find.text('多'), findsOneWidget);
  });

  testWidgets('month heatmap steps to previous month', (tester) async {
    final now = DateTime.now();
    final previous = DateTime(now.year, now.month - 1);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MonthHeatmap(dailySeconds: {}),
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('上个月'));
    await tester.pump();

    expect(find.text('${previous.year}年${previous.month}月'), findsOneWidget);
  });
}
