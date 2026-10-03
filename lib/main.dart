import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/notification_bootstrap.dart';
import 'data/sync_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SyncConfig.supabaseUrl,
    anonKey: SyncConfig.supabaseAnonKey,
  );
  runApp(const ProviderScope(child: FocusLoopApp()));
}

class FocusLoopApp extends ConsumerWidget {
  const FocusLoopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    ref.watch(notificationBootstrapProvider);
    ref.watch(syncBootstrapProvider);
    return MaterialApp.router(
      title: 'FocusLoop',
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      routerConfig: router,
    );
  }
}
