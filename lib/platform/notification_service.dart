import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Stable notification ID: FNV-1a hash of the input string.
/// Must be deterministic across app restarts so scheduled
/// notifications can be updated or cancelled later.
int stableNotificationId(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash & 0x7fffffff;
}

const _taskReminderDetails = NotificationDetails(
  android: AndroidNotificationDetails(
    'focusloop_task',
    '任务提醒',
    channelDescription: '任务到期与复习到期提醒',
  ),
);

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  /// Reminder moments within a due day: 07:00, 12:30 and 18:00.
  static const dueReminderSlots = <Duration>[
    Duration(hours: 7),
    Duration(hours: 12, minutes: 30),
    Duration(hours: 18),
  ];

  /// Stable keys paired with [dueReminderSlots], used in notification ids.
  static const taskDueSlotKeys = <String>['morning', 'noon', 'evening'];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) {
      return;
    }
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
      windows: WindowsInitializationSettings(
        appName: 'FocusLoop',
        appUserModelId: 'com.focusloop.focusloop',
        guid: 'a3f1c2d4-5b6e-4f7a-8c9d-0e1f2a3b4c5d',
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (!_initialized || kIsWeb) {
      return;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules plain message reminders for every still-future slot of [day].
  Future<void> scheduleTaskDueDay({
    required String taskId,
    required String title,
    required DateTime day,
  }) async {
    if (!_initialized || kIsWeb) {
      return;
    }
    final now = DateTime.now();
    for (var i = 0; i < dueReminderSlots.length; i++) {
      final at = day.add(dueReminderSlots[i]);
      if (!at.isAfter(now)) {
        continue;
      }
      await _plugin.zonedSchedule(
        stableNotificationId('task_due:$taskId:${taskDueSlotKeys[i]}'),
        '任务提醒',
        '「$title」今天到期，记得完成',
        tz.TZDateTime.from(at, tz.local),
        _taskReminderDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Shows a task reminder immediately for a slot that already passed
  /// while the app was closed.
  Future<void> showTaskDueNow(
    String taskId,
    String title, {
    bool overdue = false,
    required String slotKey,
  }) async {
    if (!_initialized || kIsWeb) {
      return;
    }
    await _plugin.show(
      stableNotificationId('task_due:$taskId:$slotKey'),
      '任务提醒',
      overdue ? '「$title」已过期，请尽快处理' : '「$title」今天到期，记得完成',
      _taskReminderDetails,
    );
  }

  Future<void> cancelTaskDue(String taskId) async {
    if (!_initialized || kIsWeb) {
      return;
    }
    for (final key in taskDueSlotKeys) {
      await _plugin.cancel(stableNotificationId('task_due:$taskId:$key'));
    }
  }

  Future<void> scheduleReview({
    required String scheduleId,
    required String title,
    required int round,
    required DateTime dueAt,
  }) async {
    if (!_initialized || kIsWeb || !dueAt.isAfter(DateTime.now())) {
      return;
    }
    await _plugin.zonedSchedule(
      stableNotificationId(scheduleId),
      '任务提醒',
      '「$title」第 $round 轮复习到期了',
      tz.TZDateTime.from(dueAt, tz.local),
      _taskReminderDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelReview(String scheduleId) async {
    if (!_initialized || kIsWeb) {
      return;
    }
    await _plugin.cancel(stableNotificationId(scheduleId));
  }
}
