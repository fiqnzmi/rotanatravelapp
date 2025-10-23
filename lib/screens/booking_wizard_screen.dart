import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../models/traveller.dart';
import 'trips_screen.dart';

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
                _StepIndicator(currentStep: 0, labels: const ['Travellers', 'Rooms', 'Payment', 'Confirm']),
                const SizedBox(height: 24),
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

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _StepIndicator({required this.currentStep, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index != 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: isCompleted ? const Color(0xFF0E8AE8) : const Color(0xFFE0E6EF),
                      ),
                    ),
                  _StepCircle(
                    index: index + 1,
                    active: isActive,
                    completed: isCompleted,
                  ),
                  if (index != labels.length - 1)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index < currentStep ? const Color(0xFF0E8AE8) : const Color(0xFFE0E6EF),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? const Color(0xFF0E8AE8) : Colors.black54,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int index;
  final bool active;
  final bool completed;

  const _StepCircle({
    required this.index,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    Color background;
    Color textColor;
    if (completed) {
      background = const Color(0xFF0E8AE8);
      textColor = Colors.white;
    } else if (active) {
      background = const Color(0xFF0E8AE8);
      textColor = Colors.white;
    } else {
      background = Colors.white;
      textColor = Colors.black54;
    }
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: completed || active ? const Color(0xFF0E8AE8) : const Color(0xFFE0E6EF)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
