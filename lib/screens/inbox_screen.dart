import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _svc = DashboardService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() { super.initState(); _future = AuthService.instance.getUserId().then((id)=>_svc.listNotifications(id ?? 0)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox'), actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.more_vert))]),
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = (snap.data as List<Map<String, dynamic>>);
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
