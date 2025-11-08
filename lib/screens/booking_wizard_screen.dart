import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../models/traveller.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/dashboard_service.dart';
import '../utils/error_utils.dart';
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
  final _dashboard = DashboardService();
  final _formKey = GlobalKey<FormState>();
  final List<Traveller> travellers = [];
  final DateFormat _uiDateFormat = DateFormat('dd/MM/yyyy');
  int adults = 1;
  int children = 0;
  int rooms = 1;
  bool _submitting = false;
  Map<String, dynamic>? _profileCache;
  List<Map<String, dynamic>> _familyCache = const [];

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
    final userId = await _ensureLoggedIn();
    if (userId == null) return;

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
      'rooms': rooms,
      'user_id': userId,
      'travellers': travellers.map((t) => t.toJson()).toList(),
    };
    try {
      await _svc.createBooking(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request submitted! Our staff will confirm it soon.'),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TripsScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create booking: ${friendlyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                Text(
                  'Add Travellers',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Please provide details for all travellers',
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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
                const SizedBox(height: 12),
                _countSelector(
                  label: 'Rooms',
                  value: rooms,
                  subtitle: 'Number of rooms needed',
                  onChanged: (next) {
                    setState(() {
                      rooms = next < 1 ? 1 : next;
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
                    foregroundColor: scheme.primary,
                    side: BorderSide(color: scheme.primary, width: 1.4),
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

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final badgeColor = scheme.surfaceVariant.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.8,
    );
    final badgeTextColor = traveller.isChild ? scheme.primary : scheme.secondary;

    return Container(
      key: ValueKey(traveller),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: () => _pickSavedForSlot(index),
                icon: const Icon(Icons.person_search, size: 18),
                label: const Text('Use saved'),
                style: TextButton.styleFrom(foregroundColor: scheme.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  typeLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: traveller.useAccountDetails,
                      onChanged: (value) => _toggleUseAccountDetails(index, value ?? false),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: GestureDetector(
                        onTap: () => _toggleUseAccountDetails(index, !traveller.useAccountDetails),
                        child: Text(
                          'Use my account info',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _clearTraveller(index),
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: scheme.error),
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

  Traveller _blankTravellerFor(Traveller traveller) {
    return Traveller(isChild: traveller.isChild);
  }

  void _clearTraveller(int index) {
    final current = travellers[index];
    setState(() {
      travellers[index] = _blankTravellerFor(current);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Traveller ${index + 1} cleared.')),
    );
  }

  Future<void> _toggleUseAccountDetails(int index, bool enabled) async {
    final current = travellers[index];
    if (!enabled) {
      setState(() {
        travellers[index] = _blankTravellerFor(current);
      });
      return;
    }

    final userId = await _ensureLoggedIn();
    if (userId == null) return;
    try {
      final user = await _loadProfileUser(userId);
      final seed = _travellerFromProfile(user);
      if (seed == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update your profile with passport details to use this option.')),
        );
        return;
      }
      final merged = _mergeTraveller(current, seed).copyWith(useAccountDetails: true);
      setState(() {
        for (var i = 0; i < travellers.length; i++) {
          final slotTraveller = travellers[i];
          if (i == index) {
            travellers[i] = merged;
          } else if (slotTraveller.useAccountDetails) {
            travellers[i] = _blankTravellerFor(slotTraveller);
          }
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Traveller ${index + 1} updated from your account.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to use account info: ${friendlyError(e)}')),
      );
    }
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
      family = await _loadFamilyList(userId, force: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load saved travellers: ${friendlyError(e)}')),
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
    final replacement = _travellerFromFamily(selected, isChildSlot: current.isChild)
        .copyWith(useAccountDetails: false);
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
    final seed = _travellerFromFamilyRecord(f);
    if (seed == null) {
      return Traveller(isChild: isChildSlot);
    }
    return Traveller(
      fullName: seed.fullName,
      gender: seed.gender,
      dateOfBirth: seed.dateOfBirth,
      passportNo: seed.passportNo,
      passportIssueDate: seed.passportIssueDate,
      passportExpiryDate: seed.passportExpiryDate,
      isChild: isChildSlot,
      familyMemberId: seed.familyMemberId,
      useAccountDetails: false,
    );
  }

  Traveller _mergeTraveller(Traveller current, Traveller? seed) {
    if (seed == null) return current;
    return Traveller(
      fullName: current.fullName.isNotEmpty ? current.fullName : seed.fullName,
      gender: current.gender ?? seed.gender,
      dateOfBirth: current.dateOfBirth ?? seed.dateOfBirth,
      passportNo: current.passportNo ?? seed.passportNo,
      passportIssueDate: current.passportIssueDate ?? seed.passportIssueDate,
      passportExpiryDate: current.passportExpiryDate ?? seed.passportExpiryDate,
      isChild: current.isChild,
      familyMemberId: current.familyMemberId ?? seed.familyMemberId,
      useAccountDetails: current.useAccountDetails || seed.useAccountDetails,
    );
  }

  bool _isChild(DateTime? dob) {
    if (dob == null) return false;
    final years = DateTime.now().difference(dob).inDays / 365.25;
    return years < 12;
  }

  Traveller? _travellerFromProfile(Map<String, dynamic> user) {
    final name = (user['name'] ?? user['full_name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final dob = readDateTimeOrNull(user['dob'] ?? user['date_of_birth']);
    final genderRaw = (user['gender'] ?? '').toString().toLowerCase();
    final gender = (genderRaw == 'male' || genderRaw == 'female') ? genderRaw : null;
    final passport = (user['passport_no'] ?? user['passport'] ?? '').toString();
    final issue = readDateTimeOrNull(user['passport_issue_date']);
    final expiry = readDateTimeOrNull(user['passport_expiry_date']);
    return Traveller(
      fullName: name,
      gender: gender,
      dateOfBirth: dob,
      passportNo: passport.isNotEmpty ? passport : null,
      passportIssueDate: issue,
      passportExpiryDate: expiry,
      isChild: _isChild(dob),
      useAccountDetails: true,
    );
  }

  Traveller? _travellerFromFamilyRecord(Map<String, dynamic> f) {
    final name = (f['full_name'] ?? f['name'] ?? '').toString().trim();
    if (name.isEmpty) return null;
    final dob = readDateTimeOrNull(f['dob']);
    final issue = readDateTimeOrNull(f['passport_issue_date']);
    final expiry = readDateTimeOrNull(f['passport_expiry_date']);
    final genderRaw = (f['gender'] ?? '').toString().toLowerCase();
    final gender = (genderRaw == 'male' || genderRaw == 'female') ? genderRaw : null;
    final passport = (f['passport_no'] ?? '').toString();
    final relationship = (f['relationship'] ?? '').toString().toLowerCase();
    var isChild = _isChild(dob);
    if (dob == null && relationship.contains('child')) {
      isChild = true;
    }
    return Traveller(
      fullName: name,
      gender: gender,
      dateOfBirth: dob,
      passportNo: passport.isNotEmpty ? passport : null,
      passportIssueDate: issue,
      passportExpiryDate: expiry,
      isChild: isChild,
      familyMemberId: readIntOrNull(f['id']),
    );
  }

  Future<Map<String, dynamic>> _loadProfileUser(int userId) async {
    if (_profileCache == null) {
      _profileCache = await _dashboard.profileOverview(userId);
    }
    final user = _profileCache?['user'];
    return Map<String, dynamic>.from(user as Map? ?? const {});
  }

  Future<List<Map<String, dynamic>>> _loadFamilyList(int userId, {bool force = false}) async {
    if (force || _familyCache.isEmpty) {
      _familyCache = await _family.list(userId);
    }
    return _familyCache;
  }

  Future<int?> _ensureLoggedIn() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      final proceed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
      if (proceed != true) {
        return null;
      }
    }
    return await AuthService.instance.getUserId();
  }

  Widget _countSelector({
    required String label,
    required int value,
    String? subtitle,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant.withOpacity(0.6)),
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
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? scheme.primary
              : scheme.surfaceVariant.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.35 : 1),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Icon(icon, color: enabled ? scheme.onPrimary : scheme.onSurfaceVariant, size: 20),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fillColor = theme.inputDecorationTheme.fillColor ??
        (theme.brightness == Brightness.dark
            ? scheme.surfaceVariant.withOpacity(0.55)
            : scheme.surface);
    final borderColor = scheme.outlineVariant;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 2),
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final fillColor = theme.inputDecorationTheme.fillColor ??
        (theme.brightness == Brightness.dark
            ? scheme.surfaceVariant.withOpacity(0.55)
            : scheme.surface);
    final borderColor = scheme.outlineVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Text(
                  value == null ? placeholder : formatter.format(value!),
                  style: textTheme.bodyMedium?.copyWith(
                    color: value == null
                        ? scheme.onSurfaceVariant.withOpacity(0.6)
                        : scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.calendar_today_outlined, size: 18, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
