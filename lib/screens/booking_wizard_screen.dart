import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../models/traveller.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../utils/json_utils.dart';
import 'trips_screen.dart';
import 'login_screen.dart';

class BookingWizardScreen extends StatefulWidget {
  final int packageId;
  final double price;
  final String title;
  const BookingWizardScreen({
    super.key,
    required this.packageId,
    required this.price,
    required this.title,
  });

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  final _svc = BookingService();
  final _family = FamilyService();
  final _formKey = GlobalKey<FormState>();
  final List<Traveller> travellers = [];
  final DateFormat _uiDateFormat = DateFormat('dd/MM/yyyy');
  int adults = 1;
  int children = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _syncTravellers();
  }

  void _syncTravellers() {
    if (adults < 1) adults = 1;
    if (children < 0) children = 0;

    final adultTravellers = travellers.where((t) => !t.isChild).toList();
    final childTravellers = travellers.where((t) => t.isChild).toList();

    while (adultTravellers.length < adults) {
      adultTravellers.add(Traveller(isChild: false));
    }
    while (adultTravellers.length > adults) {
      adultTravellers.removeLast();
    }

    while (childTravellers.length < children) {
      childTravellers.add(Traveller(isChild: true));
    }
    while (childTravellers.length > children) {
      childTravellers.removeLast();
    }

    for (final t in adultTravellers) {
      t.isChild = false;
    }
    for (final t in childTravellers) {
      t.isChild = true;
    }

    travellers
      ..clear()
      ..addAll(adultTravellers)
      ..addAll(childTravellers);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      final proceed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      if (proceed != true) {
        return;
      }
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final missingDates = travellers.any((t) =>
        t.dateOfBirth == null || t.passportIssueDate == null || t.passportExpiryDate == null);
    if (missingDates) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all passport and birth dates.')),
      );
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    final payload = {
      'package_id': widget.packageId,
      'adults': adults,
      'children': children,
      'travellers': travellers.map((t) => t.toJson()).toList(),
    };
    try {
      await _svc.createBooking(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking created!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TripsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text('Booking – ${widget.title}'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Travellers',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please provide details for all travellers',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                _countSelector(
                  label: 'Adults',
                  value: adults,
                  subtitle: '13 years & above',
                  onChanged: (next) {
                    setState(() {
                      adults = next < 1 ? 1 : next;
                      _syncTravellers();
                    });
                  },
                ),
                const SizedBox(height: 12),
                _countSelector(
                  label: 'Children (2-12 years)',
                  value: children,
                  subtitle: 'Optional',
                  onChanged: (next) {
                    setState(() {
                      children = next < 0 ? 0 : next;
                      _syncTravellers();
                    });
                  },
                ),
                const SizedBox(height: 20),
                ...travellers.asMap().entries.map(
                  (entry) => _travellerCard(entry.key, entry.value),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      adults += 1;
                      _syncTravellers();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add Another Traveller'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Continue to Rooms & Add-ons'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _travellerCard(int index, Traveller traveller) {
    final isLead = index == 0 && !traveller.isChild;
    final typeLabel = traveller.isChild ? 'Child' : 'Adult';

    return Container(
      key: ValueKey(traveller),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x15000000), blurRadius: 18, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Traveller ${index + 1}${isLead ? ' (Lead)' : ''}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickSavedForSlot(index),
                icon: const Icon(Icons.person_search, size: 18),
                label: const Text('Use saved'),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: traveller.isChild ? const Color(0xFFEAF4FF) : const Color(0xFFE8F7EF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: traveller.isChild ? const Color(0xFF1769FF) : const Color(0xFF1B8730),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: traveller.fullName,
            decoration: _inputDecoration('Full Name', hint: 'As per passport'),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => traveller.fullName = value,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: traveller.gender,
                  decoration: _inputDecoration('Gender'),
                  items: const [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text('Female'),
                    ),
                  ],
                  onChanged: (value) => setState(() => traveller.gender = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Select gender';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _DateField(
                  label: 'Date of Birth',
                  placeholder: 'dd/mm/yyyy',
                  value: traveller.dateOfBirth,
                  formatter: _uiDateFormat,
                  onTap: () => _pickDate(
                    current: traveller.dateOfBirth,
                    first: DateTime(1950),
                    last: DateTime.now(),
                    suggested: _suggestedDob(traveller),
                    onSelected: (date) => traveller.dateOfBirth = date,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: traveller.passportNo,
            decoration: _inputDecoration('Passport Number'),
            onChanged: (value) => traveller.passportNo = value,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Passport number is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Issue Date',
                  placeholder: 'dd/mm/yyyy',
                  value: traveller.passportIssueDate,
                  formatter: _uiDateFormat,
                  onTap: () => _pickDate(
                    current: traveller.passportIssueDate,
                    first: DateTime(2000),
                    last: DateTime.now(),
                    suggested: traveller.passportIssueDate ?? DateTime.now().subtract(const Duration(days: 365)),
                    onSelected: (date) => traveller.passportIssueDate = date,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _DateField(
                  label: 'Expiry Date',
                  placeholder: 'dd/mm/yyyy',
                  value: traveller.passportExpiryDate,
                  formatter: _uiDateFormat,
                  onTap: () => _pickDate(
                    current: traveller.passportExpiryDate,
                    first: traveller.passportIssueDate ?? DateTime.now(),
                    last: DateTime.now().add(const Duration(days: 365 * 10)),
                    suggested: traveller.passportExpiryDate ?? DateTime.now().add(const Duration(days: 365 * 5)),
                    onSelected: (date) => traveller.passportExpiryDate = date,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DateTime _suggestedDob(Traveller traveller) {
    final now = DateTime.now();
    if (traveller.isChild) {
      return DateTime(now.year - 6, now.month, now.day);
    }
    return DateTime(now.year - 30, now.month, now.day);
  }

  Future<void> _pickDate({
    required DateTime? current,
    required DateTime first,
    required DateTime last,
    required DateTime suggested,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final initial = current ?? suggested;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : initial.isAfter(last)
              ? last
              : initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() => onSelected(picked));
    }
  }

  Future<void> _pickSavedForSlot(int index) async {
    // Must be logged in to access family list
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      final proceed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      if (proceed != true) return;
    }

    final userId = await AuthService.instance.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use saved travellers.')),
      );
      return;
    }

    List<Map<String, dynamic>> family;
    try {
      family = await _family.list(userId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load saved travellers: $e')),
      );
      return;
    }
    if (!mounted) return;
    if (family.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved travellers found. Add in Profile > Family Members.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select saved traveller',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: family.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final f = family[i];
                      final name = (f['full_name'] ?? f['name'] ?? '').toString();
                      final rel = (f['relationship'] ?? '').toString();
                      final gender = (f['gender'] ?? '').toString();
                      final dob = readDateTimeOrNull(f['dob']);
                      final passport = (f['passport_no'] ?? '').toString();
                      final ageYears = dob == null ? null : (DateTime.now().difference(dob).inDays / 365.25).floor();
                      final badge = ageYears == null
                          ? (rel.isNotEmpty ? rel : (gender.isNotEmpty ? gender : ''))
                          : (ageYears < 12 ? 'Child' : 'Adult');
                      return ListTile(
                        title: Text(name.isNotEmpty ? name : 'Unnamed'),
                        subtitle: Text([
                          if (badge.isNotEmpty) badge,
                          if (passport.isNotEmpty) 'Passport: $passport',
                        ].join(' • ')),
                        onTap: () => Navigator.of(ctx).pop(f),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (selected == null) return;

    final current = travellers[index];
    final replacement = _travellerFromFamily(selected, isChildSlot: current.isChild);
    setState(() {
      travellers[index] = replacement; // new object to refresh initialValue fields
    });

    final badge = selected['relationship']?.toString() ?? '';
    if (mounted && badge.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Filled from "$badge" saved traveller.')),
      );
    }
  }

  Traveller _travellerFromFamily(Map<String, dynamic> f, {required bool isChildSlot}) {
    final dob = readDateTimeOrNull(f['dob']);
    final issue = readDateTimeOrNull(f['passport_issue_date']);
    final expiry = readDateTimeOrNull(f['passport_expiry_date']);
    final name = (f['full_name'] ?? f['name'] ?? '').toString();
    final gender = (f['gender'] ?? '').toString().toLowerCase();
    final passport = (f['passport_no'] ?? '').toString();

    return Traveller(
      fullName: name,
      gender: gender.isNotEmpty ? gender : null,
      dateOfBirth: dob,
      passportNo: passport.isNotEmpty ? passport : null,
      passportIssueDate: issue,
      passportExpiryDate: expiry,
      isChild: isChildSlot,
    );
  }

  Widget _countSelector({
    required String label,
    required int value,
    String? subtitle,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black45),
                ),
            ],
          ),
          const Spacer(),
          _roundedIcon(
            icon: Icons.remove,
            onTap: () => onChanged(value - 1),
            enabled: label.startsWith('Adults') ? value > 1 : value > 0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          _roundedIcon(
            icon: Icons.add,
            onTap: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _roundedIcon({required IconData icon, required VoidCallback onTap, bool enabled = true}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF0E8AE8) : const Color(0xFFE4E7EB),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5DDE5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFD5DDE5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0E8AE8), width: 2),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String placeholder;
  final DateTime? value;
  final DateFormat formatter;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.placeholder,
    required this.value,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD5DDE5)),
            ),
            child: Row(
              children: [
                Text(
                  value == null ? placeholder : formatter.format(value!),
                  style: textTheme.bodyMedium?.copyWith(
                    color: value == null ? Colors.black45 : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.black54),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
