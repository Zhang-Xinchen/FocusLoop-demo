import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _busy = false;
  String? _authError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _runAuth(
    Future<AuthResponse> Function(GoTrueClient) action,
  ) async {
    setState(() {
      _busy = true;
      _authError = null;
    });
    try {
      await action(ref.read(supabaseClientProvider).auth);
    } on AuthException catch (error) {
      setState(() => _authError = error.message);
    } catch (error) {
      setState(() => _authError = error.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _register() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return _runAuth(
      (auth) => auth.signUp(email: email, password: password),
    );
  }

  Future<void> _signIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    return _runAuth(
      (auth) => auth.signInWithPassword(email: email, password: password),
    );
  }

  Future<void> _signOut() async {
    await ref.read(supabaseClientProvider).auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = ref.watch(isLoggedInProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('版本'),
            trailing: const Text('0.1.0'),
          ),
          ListTile(
            leading: const Icon(Icons.folder_outlined),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_sync_outlined),
            title: const Text('多端同步'),
            subtitle: Text(
              loggedIn ? '已登录，每 5 分钟自动同步' : '登录后数据在所有设备间自动同步',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child:
                loggedIn ? _buildSyncPanel(context) : _buildLoginPanel(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('复习提醒'),
            subtitle: const Text('任务到期时发送本地通知'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: '邮箱',
                prefixIcon: Icon(Icons.mail_outline),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '密码',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
            ),
            if (_authError != null) ...[
              const SizedBox(height: 12),
              Text(
                _authError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _signIn,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('登录'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _register,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('注册'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '每个设备都用同一邮箱密码登录，数据自动互通。',
              style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncPanel(BuildContext context) {
    final sync = ref.watch(syncStatusProvider);
    final email = ref.watch(currentUserProvider).value?.user.email ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(email, overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sync.lastSyncAt == null
                  ? '还没有同步过'
                  : '上次同步：${_formatSyncTime(sync.lastSyncAt!)}',
              style: TextStyle(fontSize: 13, color: Theme.of(context).hintColor),
            ),
            if (sync.error != null) ...[
              const SizedBox(height: 8),
              Text(
                '同步失败：${sync.error}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: sync.syncing
                        ? null
                        : ref.read(syncStatusProvider.notifier).syncNow,
                    icon: sync.syncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(sync.syncing ? '同步中' : '立即同步'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _signOut,
                    icon: const Icon(Icons.logout),
                    label: const Text('退出登录'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.month}月${local.day}日 ${two(local.hour)}:${two(local.minute)}';
  }
}
