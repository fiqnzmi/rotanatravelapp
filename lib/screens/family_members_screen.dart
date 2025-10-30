import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/family_service.dart';
import '../services/auth_service.dart';
import '../utils/json_utils.dart';

Future<bool> showFamilyMemberForm(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final svc = FamilyService();
  final formKey = GlobalKey<FormState>();
  final nameC = TextEditingController(text: initial?['full_name']?.toString() ?? '');
  final nationalityC = TextEditingController(text: initial?['nationality']?.toString() ?? '');
  final passportC = TextEditingController(text: initial?['passport_no']?.toString() ?? '');
  final phoneC = TextEditingController(text: initial?['phone']?.toString() ?? '');
  String relationship = (initial?['relationship'] ?? 'OTHER').toString().toUpperCase();
  String gender = (initial?['gender'] ?? '').toString().toLowerCase();
  DateTime? dob = _parseDate(initial?['dob']);
  DateTime? passportIssueDate = _parseDate(initial?['passport_issue_date']);
  DateTime? passportExpiryDate = _parseDate(initial?['passport_expiry_date']);

  bool? result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      bool saving = false;

      Future<void> pickDate({
        required DateTime? current,
        required DateTime first,
        required DateTime last,
        required ValueChanged<DateTime> onSelected,
      }) async {
        final picked = await showDatePicker(
          context: sheetContext,
          initialDate: current ?? DateTime.now(),
          firstDate: first,
          lastDate: last,
        );
        if (picked != null) {
          onSelected(picked);
        }
      }

      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          initial == null ? 'Add Family Member' : 'Edit Family Member',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: saving ? null : () => Navigator.of(sheetContext).pop(false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameC,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: relationship,
                      items: const [
                        DropdownMenuItem(value: 'SPOUSE', child: Text('Spouse')),
                        DropdownMenuItem(value: 'CHILD', child: Text('Child')),
                        DropdownMenuItem(value: 'PARENT', child: Text('Parent')),
                        DropdownMenuItem(value: 'SIBLING', child: Text('Sibling')),
                        DropdownMenuItem(value: 'FRIEND', child: Text('Friend')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      ],
                      onChanged: saving ? null : (value) => setModalState(() => relationship = value ?? 'OTHER'),
                      decoration: const InputDecoration(
                        labelText: 'Relationship',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: (gender == 'male' || gender == 'female') ? gender : null,
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(value: 'female', child: Text('Female')),
                      ],
                      onChanged: saving ? null : (value) => setModalState(() => gender = value ?? ''),
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DateFieldRow(
                      label: 'Date of Birth',
                      value: dob,
                      onTap: () async {
                        await pickDate(
                          current: dob,
                          first: DateTime(1900),
                          last: DateTime.now(),
                          onSelected: (date) => setModalState(() => dob = date),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passportC,
                      decoration: const InputDecoration(
                        labelText: 'Passport Number',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Passport number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _DateFieldRow(
                            label: 'Passport Issue Date',
                            value: passportIssueDate,
                            onTap: () async {
                              await pickDate(
                                current: passportIssueDate,
                                first: DateTime(2000),
                                last: DateTime.now(),
                                onSelected: (date) =>
                                    setModalState(() => passportIssueDate = date),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateFieldRow(
                            label: 'Passport Expiry Date',
                            value: passportExpiryDate,
                            onTap: () async {
                              await pickDate(
                                current: passportExpiryDate,
                                first: passportIssueDate ?? DateTime.now(),
                                last: DateTime.now().add(const Duration(days: 365 * 10)),
                                onSelected: (date) =>
                                    setModalState(() => passportExpiryDate = date),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nationalityC,
                      decoration: const InputDecoration(
                        labelText: 'Nationality',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneC,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              if (dob == null ||
                                  passportIssueDate == null ||
                                  passportExpiryDate == null) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please select birth date and passport dates.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setModalState(() => saving = true);
                              try {
                                final uid = await AuthService.instance.getUserId();
                                if (uid == null) {
                                  throw Exception('Please log in again.');
                                }

                                if (initial == null) {
                                  await svc.add(
                                    userId: uid,
                                    fullName: nameC.text.trim(),
                                    relationship: relationship,
                                    gender: gender.isEmpty ? null : gender,
                                    passportNo: passportC.text.trim(),
                                    dob: _formatDate(dob),
                                    passportIssueDate: _formatDate(passportIssueDate),
                                    passportExpiryDate: _formatDate(passportExpiryDate),
                                    nationality: nationalityC.text.trim(),
                                    phone: phoneC.text.trim(),
                                  );
                                } else {
                                  await svc.update(
                                    id: readInt(initial['id']),
                                    userId: uid,
                                    fullName: nameC.text.trim(),
                                    relationship: relationship,
                                    gender: gender.isEmpty ? null : gender,
                                    passportNo: passportC.text.trim(),
                                    dob: _formatDate(dob),
                                    passportIssueDate: _formatDate(passportIssueDate),
                                    passportExpiryDate: _formatDate(passportExpiryDate),
                                    nationality: nationalityC.text.trim(),
                                    phone: phoneC.text.trim(),
                                  );
                                }

                                if (context.mounted) {
                                  Navigator.of(sheetContext).pop(true);
                                }
                              } catch (e) {
                                setModalState(() => saving = false);
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('Failed to save: $e')),
                                );
                              }
                            },
                      child: saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(initial == null ? 'Save Member' : 'Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );

  nameC.dispose();
  nationalityC.dispose();
  passportC.dispose();
  phoneC.dispose();

  return result == true;
}

String? _formatDate(DateTime? date) {
  if (date == null) return null;
  return DateFormat('yyyy-MM-dd').format(date);
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

class _DateFieldRow extends StatelessWidget {
  const _DateFieldRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9DFE8)),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value == null ? 'Select date' : formatter.format(value!),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: value == null ? Colors.black45 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

  Future<void> _openForm({Map<String, dynamic>? member}) async {
    final saved = await showFamilyMemberForm(context, initial: member);
    if (saved && mounted) {
      _reload();
    }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
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
                  onTap: () => _openForm(member: Map<String, dynamic>.from(m)),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFECEFF4),
                    child: Text(
                      (m['full_name'] ?? '?').toString().isNotEmpty
                          ? m['full_name'].toString()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  title: Text(m['full_name'] ?? 'Traveller'),
                  subtitle: Text(_buildMemberSubtitle(m)),
                  trailing: IconButton(
                    onPressed: () => _delete(m['id']),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _buildMemberSubtitle(Map<String, dynamic> member) {
    final parts = <String>[];
    final relationship = (member['relationship'] ?? '').toString();
    if (relationship.isNotEmpty) parts.add(relationship);
    final nationality = (member['nationality'] ?? '').toString();
    if (nationality.isNotEmpty) parts.add(nationality);
    final passport = (member['passport_no'] ?? '').toString();
    if (passport.isNotEmpty) parts.add('Passport: $passport');
    final dob = _parseDate(member['dob']);
    if (dob != null) {
      parts.add('DOB: ${DateFormat('dd/MM/yyyy').format(dob)}');
    }
    return parts.isEmpty ? 'No additional info' : parts.join(' • ');
  }
}
