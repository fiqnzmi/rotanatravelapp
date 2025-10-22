import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../services/auth_service.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _svc = FamilyService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() { super.initState(); _reload(); }

  Future<void> _reload() async {
    final uid = await AuthService.instance.getUserId() ?? 0;
    setState(() => _future = _svc.list(uid));
  }

  Future<void> _addDialog() async {
    final nameC = TextEditingController();
    String rel = 'OTHER';
    final phoneC = TextEditingController();
    await showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: const Text('Add Family Member'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Full Name')),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            items: const [
              DropdownMenuItem(value:'SPOUSE',child: Text('Spouse')),
              DropdownMenuItem(value:'CHILD',child: Text('Child')),
              DropdownMenuItem(value:'PARENT',child: Text('Parent')),
              DropdownMenuItem(value:'SIBLING',child: Text('Sibling')),
              DropdownMenuItem(value:'FRIEND',child: Text('Friend')),
              DropdownMenuItem(value:'OTHER',child: Text('Other')),
            ],
            value: rel, onChanged: (v)=>rel=v as String,
            decoration: const InputDecoration(labelText: 'Relationship'),
          ),
          const SizedBox(height: 8),
          TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone')),
        ]),
        actions: [
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            final uid = await AuthService.instance.getUserId() ?? 0;
            await _svc.add(userId: uid, fullName: nameC.text, relationship: rel, phone: phoneC.text);
            if (context.mounted) Navigator.pop(context);
          }, child: const Text('Save')),
        ],
      );
    });
    _reload();
  }

  Future<void> _delete(int id) async {
    final uid = await AuthService.instance.getUserId() ?? 0;
    await _svc.delete(id, uid);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Family Members')),
      floatingActionButton: FloatingActionButton(onPressed: _addDialog, child: const Icon(Icons.add)),
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final items = (snap.data as List<Map<String, dynamic>>);
          if (items.isEmpty) return const Center(child: Text('No family members yet'));
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12,12,12,24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final m = items[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(m['full_name']),
                  subtitle: Text(m['relationship']),
                  trailing: IconButton(onPressed: ()=>_delete(m['id']), icon: const Icon(Icons.delete_outline)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
