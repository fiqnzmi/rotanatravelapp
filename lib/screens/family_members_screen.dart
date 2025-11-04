import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/family_service.dart';
import '../services/auth_service.dart';
import '../utils/json_utils.dart';

Future<bool> showFamilyMemberForm(
  BuildContext context, {
  Map<String, dynamic>? initial,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FamilyMemberFormSheet(initial: initial),
  );
  return result == true;
}

class _FamilyMemberFormSheet extends StatefulWidget {
  const _FamilyMemberFormSheet({this.initial});

  final Map<String, dynamic>? initial;

  @override
  State<_FamilyMemberFormSheet> createState() => _FamilyMemberFormSheetState();
}

class _FamilyMemberFormSheetState extends State<_FamilyMemberFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _svc = FamilyService();

  late final TextEditingController _nameC =
      TextEditingController(text: widget.initial?['full_name']?.toString() ?? '');
  late final TextEditingController _nationalityC =
      TextEditingController(text: widget.initial?['nationality']?.toString() ?? '');
  late final TextEditingController _passportC =
      TextEditingController(text: widget.initial?['passport_no']?.toString() ?? '');
  late final TextEditingController _phoneC =
      TextEditingController(text: widget.initial?['phone']?.toString() ?? '');

  late String _relationship =
      (widget.initial?['relationship'] ?? 'OTHER').toString().toUpperCase();
  late String _gender = (widget.initial?['gender'] ?? '').toString().toLowerCase();
  DateTime? _dob;
  DateTime? _passportIssueDate;
  DateTime? _passportExpiryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dob = _parseDate(widget.initial?['dob']);
    _passportIssueDate = _parseDate(widget.initial?['passport_issue_date']);
    _passportExpiryDate = _parseDate(widget.initial?['passport_expiry_date']);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _nationalityC.dispose();
    _passportC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required DateTime? current,
    required DateTime first,
    required DateTime last,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: first,
      lastDate: last,
    );
    if (picked != null && mounted) {
      onSelected(picked);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null || _passportIssueDate == null || _passportExpiryDate == null) {
      _showSnack('Please select birth date and passport dates.');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final uid = await AuthService.instance.getUserId();
      if (uid == null) {
        throw Exception('Please log in again.');
      }

      final payload = {
        'fullName': _nameC.text.trim(),
        'relationship': _relationship,
        'gender': _gender.isEmpty ? null : _gender,
        'passportNo': _passportC.text.trim(),
        'dob': _formatDate(_dob),
        'passportIssueDate': _formatDate(_passportIssueDate),
        'passportExpiryDate': _formatDate(_passportExpiryDate),
        'nationality': _nationalityC.text.trim(),
        'phone': _phoneC.text.trim(),
      };

      if (widget.initial == null) {
        await _svc.add(
          userId: uid,
          fullName: payload['fullName'] as String,
          relationship: payload['relationship'] as String,
          gender: payload['gender'] as String?,
          passportNo: payload['passportNo'] as String?,
          dob: payload['dob'] as String?,
          passportIssueDate: payload['passportIssueDate'] as String?,
          passportExpiryDate: payload['passportExpiryDate'] as String?,
          nationality: payload['nationality'] as String?,
          phone: payload['phone'] as String?,
        );
      } else {
        await _svc.update(
          id: readInt(widget.initial!['id']),
          userId: uid,
          fullName: payload['fullName'] as String,
          relationship: payload['relationship'] as String,
          gender: payload['gender'] as String?,
          passportNo: payload['passportNo'] as String?,
          dob: payload['dob'] as String?,
          passportIssueDate: payload['passportIssueDate'] as String?,
          passportExpiryDate: payload['passportExpiryDate'] as String?,
          nationality: payload['nationality'] as String?,
          phone: payload['phone'] as String?,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('Failed to save: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    widget.initial == null ? 'Add Family Member' : 'Edit Family Member',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameC,
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
                value: _relationship,
                items: const [
                  DropdownMenuItem(value: 'SPOUSE', child: Text('Spouse')),
                  DropdownMenuItem(value: 'CHILD', child: Text('Child')),
                  DropdownMenuItem(value: 'PARENT', child: Text('Parent')),
                  DropdownMenuItem(value: 'SIBLING', child: Text('Sibling')),
                  DropdownMenuItem(value: 'FRIEND', child: Text('Friend')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: _saving ? null : (value) => setState(() => _relationship = value ?? 'OTHER'),
                decoration: const InputDecoration(
                  labelText: 'Relationship',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: (_gender == 'male' || _gender == 'female') ? _gender : null,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: _saving ? null : (value) => setState(() => _gender = value ?? ''),
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _DateFieldRow(
                label: 'Date of Birth',
                value: _dob,
                onTap: () async {
                  await _pickDate(
                    current: _dob,
                    first: DateTime(1900),
                    last: DateTime.now(),
                    onSelected: (date) => setState(() => _dob = date),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passportC,
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
                      value: _passportIssueDate,
                      onTap: () async {
                        await _pickDate(
                          current: _passportIssueDate,
                          first: DateTime(2000),
                          last: DateTime.now(),
                          onSelected: (date) => setState(() => _passportIssueDate = date),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateFieldRow(
                      label: 'Passport Expiry Date',
                      value: _passportExpiryDate,
                      onTap: () async {
                        await _pickDate(
                          current: _passportExpiryDate,
                          first: _passportIssueDate ?? DateTime.now(),
                          last: DateTime.now().add(const Duration(days: 365 * 10)),
                          onSelected: (date) => setState(() => _passportExpiryDate = date),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalityC,
                decoration: const InputDecoration(
                  labelText: 'Nationality',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(widget.initial == null ? 'Save Member' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(minHeight: 58),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD9DFE8)),
          color: Colors.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
