import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/categories/categories_page.dart';
import '../features/home/home_page.dart';
import '../features/review/review_page.dart';
import '../features/settings/settings_page.dart';
import '../features/stats/stats_page.dart';
import '../features/tasks/tasks_page.dart';
import '../features/timer/timer_page.dart';
import 'app_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(path: '/tasks', builder: (_, __) => const TasksPage()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
          GoRoute(path: '/stats', builder: (_, __) => const StatsPage()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
        ],
      ),
      GoRoute(
        path: '/timer/:taskId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            TimerPage(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/review/:scheduleId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            ReviewPage(scheduleId: state.pathParameters['scheduleId']!),
      ),
    ],
  );
});
