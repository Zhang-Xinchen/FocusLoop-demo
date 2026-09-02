import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/device_id.dart';
import '../data/repositories.dart';
import '../domain/domain.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = openAppDatabase();
  ref.onDispose(db.close);
  return db;
});

final categoryRepositoryProvider =
    Provider<CategoryRepository>((ref) => CategoryRepository(ref.watch(databaseProvider)));

final taskRepositoryProvider =
    Provider<TaskRepository>((ref) => TaskRepository(ref.watch(databaseProvider)));

final timeLogRepositoryProvider =
    Provider<TimeLogRepository>((ref) => TimeLogRepository(ref.watch(databaseProvider)));

final reviewRepositoryProvider =
    Provider<ReviewRepository>((ref) => ReviewRepository(ref.watch(databaseProvider)));

final deviceIdProvider =
    FutureProvider<String>((ref) => ensureDeviceId(ref.watch(databaseProvider)));

final tasksProvider =
    StreamProvider<List<Task>>((ref) => ref.watch(taskRepositoryProvider).watchTasks());

final categoriesProvider = StreamProvider<List<Category>>(
    (ref) => ref.watch(categoryRepositoryProvider).watchCategories());

final pendingReviewsProvider = StreamProvider<List<ReviewSchedule>>(
    (ref) => ref.watch(reviewRepositoryProvider).watchPending());

final completedReviewsProvider =
    StreamProvider<int>((ref) => ref.watch(reviewRepositoryProvider).watchCompletedCount());

final totalSecondsProvider =
    StreamProvider<int>((ref) => ref.watch(timeLogRepositoryProvider).watchTotalSeconds());

final todaySecondsProvider = StreamProvider<int>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return ref.watch(timeLogRepositoryProvider).watchTotalSecondsSince(startOfDay);
});

final clockProvider = StreamProvider<DateTime>(
    (ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()));
