import 'package:flutter/material.dart';
import '../services/api_client.dart' show NoConnectionException;
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../utils/error_utils.dart';
import '../widgets/no_connection_view.dart';
import 'login_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _svc = DashboardService();
  late Future<_InboxResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_InboxResult> _load() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      return const _InboxResult(loggedIn: false, notifications: []);
    }
    final id = await AuthService.instance.getUserId();
    if (id == null) {
      return const _InboxResult(loggedIn: false, notifications: []);
    }
    final data = await _svc.listNotifications(id);
    return _InboxResult(loggedIn: true, notifications: data);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(title: const Text('Inbox'), actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert))]),
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            final error = snap.error;
            if (error is NoConnectionException) {
              return Center(child: NoConnectionView(onRetry: _reload));
            }
            return Center(child: Text('Error: ${friendlyError(error ?? 'Unknown error')}'));
          }
          final result = snap.data as _InboxResult;
          if (!result.loggedIn) {
            return _InboxLoginPrompt(onLogin: () async {
              final loggedIn = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
              if (loggedIn == true && mounted) {
                _reload();
              }
            });
          }
          final items = result.notifications;
          if (items.isEmpty) return const Center(child: Text('No messages'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = items[i];
              final type = (m['type'] ?? '').toString().toUpperCase();
              final iconData = type == 'PAYMENT'
                  ? Icons.payments_outlined
                  : type == 'DOCS'
                      ? Icons.insert_drive_file_outlined
                      : type == 'BRIEFING'
                          ? Icons.record_voice_over_outlined
                          : type == 'BOOKING'
                              ? Icons.bookmark_added_outlined
                              : type == 'PROMO'
                                  ? Icons.local_offer_outlined
                                  : Icons.notifications_outlined;
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(iconData, color: scheme.primary),
                  title: Text(m['title'] ?? '', style: theme.textTheme.titleMedium),
                  subtitle: Text(
                    m['body'] ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  trailing: Text(
                    m['created_at'].toString().split(' ').first,
                    style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InboxResult {
  final bool loggedIn;
  final List<Map<String, dynamic>> notifications;
  const _InboxResult({required this.loggedIn, required this.notifications});
}

class _InboxLoginPrompt extends StatelessWidget {
  const _InboxLoginPrompt({required this.onLogin});
  final Future<void> Function() onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 72, color: scheme.onSurfaceVariant),
          const SizedBox(height: 20),
          Text(
            'Stay updated',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Log in to see your latest travel alerts and updates.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () { onLogin(); },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }
}
