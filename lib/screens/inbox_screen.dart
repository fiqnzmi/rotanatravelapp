import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox'), actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert))]),
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
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
                setState(() => _future = _load());
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
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    m['type']=='PAYMENT' ? Icons.payments_outlined :
                    m['type']=='DOCS'    ? Icons.insert_drive_file_outlined :
                    m['type']=='BRIEFING'? Icons.record_voice_over_outlined :
                    m['type']=='BOOKING' ? Icons.bookmark_added_outlined :
                    m['type']=='PROMO'   ? Icons.local_offer_outlined :
                                           Icons.notifications_outlined,
                  ),
                  title: Text(m['title'] ?? ''),
                  subtitle: Text(m['body'] ?? ''),
                  trailing: Text(m['created_at'].toString().split(' ').first),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.notifications_none_outlined,
              size: 72, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'Stay updated',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Log in to see your latest travel alerts and updates.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
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
