import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'family_members_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _svc = DashboardService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() { super.initState(); _future = AuthService.instance.getUserId().then((id)=>_svc.profileOverview(id ?? 0)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.settings_outlined))]),
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final m = snap.data as Map<String, dynamic>;
          final user = m['user'] as Map<String, dynamic>;
          final counts = m['counts'] as Map<String, dynamic>;
          final members = (m['family_members'] as List).cast<Map<String, dynamic>>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16,16,16,24),
            children: [
              Row(children: [
                const CircleAvatar(radius: 26, child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user['name'] ?? '-', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(user['email'] ?? '-', style: const TextStyle(color: Colors.black54)),
                ])
              ]),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _stat('Trips Completed', (counts['completed'] ?? '0').toString()),
                    _stat('Upcoming', (counts['upcoming'] ?? '0').toString()),
                    _stat('Family Members', (counts['family_members'] ?? '0').toString()),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Saved Travellers'),
                subtitle: Text('${members.length} traveller(s)'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyMembersScreen())),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await AuthService.instance.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginScreen(onAuthSuccess: () {})),
                    (_) => false,
                  );
                },
              ),
              const SizedBox(height: 18),
              const Center(child: Text('Rotana Travel & Tours\nVersion 2.1.0', textAlign: TextAlign.center)),
            ],
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.black54)),
    ]);
  }
}
