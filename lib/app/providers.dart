import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/database.dart';
import '../data/device_id.dart';
import '../data/repositories.dart';
import '../data/sync_service.dart';
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

final metaRepositoryProvider =
    Provider<MetaRepository>((ref) => MetaRepository(ref.watch(databaseProvider)));

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

final totalSecondsProvider =
    StreamProvider<int>((ref) => ref.watch(timeLogRepositoryProvider).watchTotalSeconds());

final todaySecondsProvider = StreamProvider<int>((ref) {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  return ref.watch(timeLogRepositoryProvider).watchTotalSecondsSince(startOfDay);
});

final clockProvider = StreamProvider<DateTime>(
    (ref) => Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()));

final dailySecondsProvider = StreamProvider<Map<DateTime, int>>(
    (ref) => ref.watch(timeLogRepositoryProvider).watchDailySeconds());

final taskTimeLogsProvider =
    StreamProvider.family<List<TimeLog>, String>((ref, taskId) {
  return ref.watch(timeLogRepositoryProvider).watchLogsForTask(taskId);
});

final supabaseClientProvider =
    Provider<SupabaseClient>((ref) => Supabase.instance.client);

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    client: ref.watch(supabaseClientProvider),
    categories: ref.watch(categoryRepositoryProvider),
    tasks: ref.watch(taskRepositoryProvider),
    timeLogs: ref.watch(timeLogRepositoryProvider),
    reviews: ref.watch(reviewRepositoryProvider),
  );
});

final currentUserProvider = StreamProvider<Session?>((ref) async* {
  final auth = ref.watch(supabaseClientProvider).auth;
  yield auth.currentSession;
  yield* auth.onAuthStateChange.map((state) => state.session);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).value != null;
});

class SyncStatus {
  const SyncStatus({this.syncing = false, this.lastSyncAt, this.error});

  final bool syncing;
  final DateTime? lastSyncAt;
  final String? error;

  SyncStatus copyWith({
    bool? syncing,
    DateTime? lastSyncAt,
    String? error,
  }) {
    return SyncStatus(
      syncing: syncing ?? this.syncing,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: error ?? this.error,
    );
  }
}

final syncStatusProvider =
    StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier(ref);
});

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier(this._ref) : super(const SyncStatus());

  final Ref _ref;

  Future<void> syncNow() async {
    if (state.syncing) {
      return;
    }
    state = state.copyWith(syncing: true, error: null);
    try {
      await _ref.read(syncServiceProvider).syncNow();
      state = state.copyWith(syncing: false, lastSyncAt: DateTime.now());
    } catch (error) {
      state = state.copyWith(syncing: false, error: error.toString());
    }
  }
}

/// Starts the first sync after login and keeps syncing every 5 minutes.
final syncBootstrapProvider = Provider<void>((ref) {
  ref.listen(isLoggedInProvider, (previous, isLoggedIn) {
    if (isLoggedIn == true && previous != true) {
      ref.read(syncStatusProvider.notifier).syncNow();
    }
  });
  final timer = Timer.periodic(const Duration(minutes: 5), (_) {
    ref.read(syncStatusProvider.notifier).syncNow();
  });
  ref.onDispose(timer.cancel);
  return;
});
