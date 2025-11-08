import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../config_service.dart';
import '../services/prayer_times_service.dart';
import '../services/dashboard_service.dart';
import '../utils/json_utils.dart';
import '../utils/error_utils.dart';
import 'trips_screen.dart';
import 'documents_screen.dart';
import 'payments_screen.dart';
import 'package_detail_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _bookingSvc = BookingService();
  final _prayerSvc = PrayerTimesService();
  final _dashboardSvc = DashboardService();

  String? _userName;
  int? _userId;
  bool _loading = true;
  PrayerTimesData? _prayerData;
  Booking? _nextTripBooking;
  Map<String, dynamic>? _nextTripSummary;
  bool _nextTripSummaryLoading = false;
  String? _nextTripSummaryError;
  int? _nextTripSummaryBookingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
        });
      }
      final userFuture = AuthService.instance.currentUser();
      final bookingsFuture = _safeBookings();

      final prayerData = await _fetchPrayerData();

      final user = await userFuture;
      final bookings = await bookingsFuture;

      final nextTrip = _findNextTrip(bookings);
      final int? userId = user != null ? readInt(user['id']) : null;

      if (!mounted) return;
      setState(() {
        _userName = user?['name'] as String?;
        _userId = userId;
        _prayerData = prayerData;
        _nextTripBooking = nextTrip;
        _loading = false;
        if (nextTrip == null) {
          _nextTripSummary = null;
          _nextTripSummaryError = null;
          _nextTripSummaryBookingId = null;
          _nextTripSummaryLoading = false;
        }
      });

      if (nextTrip != null && userId != null) {
        if (_nextTripSummaryBookingId != nextTrip.id) {
          await _loadNextTripSummary(nextTrip.id, userId);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _prayerData = null;
        _userId = null;
        _nextTripBooking = null;
        _nextTripSummary = null;
        _nextTripSummaryError = friendlyError(e);
        _nextTripSummaryLoading = false;
        _nextTripSummaryBookingId = null;
      });
    }
  }


  Future<PrayerTimesData?> _fetchPrayerData() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return await _prayerSvc.fetchToday();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever || permission == LocationPermission.denied) {
        return await _prayerSvc.fetchToday();
      }

      final position = await Geolocator.getCurrentPosition();
      String? city;
      String? country;
      try {
        final placemarks = await geocoding.placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          city = (place.locality?.isNotEmpty ?? false)
              ? place.locality
              : place.subAdministrativeArea;
          country = place.country;
        }
      } catch (_) {
        // ignore reverse geocode failures
      }

      return await _prayerSvc.fetchByCoordinates(
        latitude: position.latitude,
        longitude: position.longitude,
        city: city,
        country: country,
      );
    } catch (_) {
      try {
        return await _prayerSvc.fetchToday();
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<Booking>> _safeBookings() async {
    try {
      return await _bookingSvc.myBookings();
    } catch (_) {
      return [];
    }
  }

  Booking? _findNextTrip(List<Booking> bookings) {
    final active = bookings.where((b) => _isUpcomingStatus(b.status)).toList();
    if (active.isEmpty) return null;
    active.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return active.first;
  }

  Future<void> _loadNextTripSummary(int bookingId, int userId) async {
    setState(() {
      _nextTripSummaryLoading = true;
      _nextTripSummaryError = null;
      _nextTripSummaryBookingId = bookingId;
    });
    try {
      final data = await _dashboardSvc.bookingSummary(bookingId, userId);
      if (!mounted) return;
      setState(() {
        _nextTripSummary = Map<String, dynamic>.from(data);
        _nextTripSummaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _nextTripSummary = null;
        _nextTripSummaryError = friendlyError(e);
        _nextTripSummaryLoading = false;
      });
    }
  }

  Booking? get _nextTrip => _nextTripBooking;

  List<Map<String, dynamic>> _nextTripSteps() {
    final raw = _nextTripSummary?['steps'];
    if (raw is List) {
      final steps = <Map<String, dynamic>>[];
      for (final item in raw) {
        steps.add(_asStringKeyedMap(item));
      }
      return steps;
    }
    return const [];
  }

  ({int completed, int total, double progress}) _nextTripStepProgress() {
    final steps = _nextTripSteps();
    if (steps.isEmpty) {
      return (completed: 0, total: 0, progress: 0.0);
    }
    final completed = steps.where(_stepDone).length;
    final total = steps.length;
    final progress = (completed / total).clamp(0.0, 1.0).toDouble();
    return (completed: completed, total: total, progress: progress);
  }

  Map<String, dynamic> _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      final result = <String, dynamic>{};
      value.forEach((key, dynamic val) {
        result[key.toString()] = val;
      });
      return result;
    }
    return const {};
  }

  DateTime? _extractDateFromMap(Map<String, dynamic> source, List<String> keys) {
    if (source.isEmpty) return null;
    final lookup = keys.map((e) => e.toLowerCase()).toSet();
    for (final entry in source.entries) {
      final key = entry.key.toLowerCase();
      if (!lookup.contains(key)) continue;
      final dt = readDateTimeOrNull(entry.value);
      if (dt != null) return dt;
    }
    return null;
  }

  DateTime? _nextTripDepartureDate() {
    final summary = _nextTripSummary;
    if (summary == null) return null;
    final summaryMap = _asStringKeyedMap(summary);
    DateTime? direct = _extractDateFromMap(summaryMap, const [
      'travel_date',
      'departure_date',
      'departure',
      'start_date',
      'journey_start',
      'depart_at',
      'travel_datetime',
      'departure_datetime',
    ]);
    if (direct != null) return direct;

    final travel = summaryMap['travel'];
    if (travel != null) {
      direct = _extractDateFromMap(
        _asStringKeyedMap(travel),
        const ['date', 'departure', 'travel_date', 'start'],
      );
      if (direct != null) return direct;
    }

    final steps = _nextTripSteps();
    for (final step in steps) {
      final slug = _stepSlug(step);
      if (_slugContains(slug, const ['depart', 'departure', 'travel', 'flight'])) {
        return _stepScheduledAt(step) ?? _stepDueAt(step) ?? _stepCompletedAt(step);
      }
    }
    return null;
  }

  String? _nextTripCountdown() {
    final date = _nextTripDepartureDate();
    if (date == null) return null;
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays >= 2) {
      return '${diff.inDays} days to go';
    }
    if (diff.inDays == 1) {
      return '1 day to go';
    }
    if (!diff.isNegative) {
      if (diff.inHours >= 1) {
        return '${diff.inHours} h to go';
      }
      if (diff.inMinutes >= 1) {
        return '${diff.inMinutes} min to go';
      }
      return 'Departing soon';
    }
    final pastDays = diff.inDays.abs();
    if (pastDays >= 1) {
      return 'Departed $pastDays day${pastDays == 1 ? '' : 's'} ago';
    }
    final pastHours = diff.inHours.abs();
    if (pastHours >= 1) {
      return 'Departed ${pastHours}h ago';
    }
    return 'Departed';
  }

  String? _nextTripDepartureLabel() {
    final date = _nextTripDepartureDate();
    if (date == null) return null;
    final fmt = DateFormat('EEE, dd MMM yyyy');
    return 'Departs ${fmt.format(date)}';
  }

  List<_NextTripChipData> _nextTripChipsData() {
    final steps = _nextTripSteps();
    if (steps.isEmpty) return const [];

    bool paymentSeen = false;
    bool paymentDone = false;
    bool docsSeen = false;
    bool docsDone = false;
    bool briefingSeen = false;
    bool briefingDone = false;

    for (final step in steps) {
      final slug = _stepSlug(step);
      final done = _stepDone(step);
      if (_slugContains(slug, const ['pay', 'payment', 'invoice', 'balance', 'deposit', 'fpx'])) {
        paymentSeen = true;
        paymentDone = done;
      } else if (_slugContains(slug, const ['doc', 'passport', 'visa'])) {
        docsSeen = true;
        docsDone = done;
      } else if (_slugContains(slug, const ['brief', 'briefing', 'meeting', 'orientation'])) {
        briefingSeen = true;
        briefingDone = done;
      }
    }

    final chips = <_NextTripChipData>[];
    if (paymentSeen) {
      chips.add(
        paymentDone
            ? const _NextTripChipData(
                icon: Icons.verified_outlined,
                label: 'Payment cleared',
                background: Color(0xFFE6F6EA),
                iconColor: Color(0xFF1B8730),
                textColor: Color(0xFF1B8730),
              )
            : const _NextTripChipData(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Balance due',
                background: Color(0xFFFFF6E5),
                iconColor: Color(0xFFB35C00),
                textColor: Color(0xFFB35C00),
              ),
      );
    }
    if (docsSeen) {
      chips.add(
        docsDone
            ? const _NextTripChipData(
                icon: Icons.insert_drive_file_outlined,
                label: 'Documents ready',
                background: Color(0xFFE8F1FF),
                iconColor: Color(0xFF0B53B0),
                textColor: Color(0xFF0B53B0),
              )
            : const _NextTripChipData(
                icon: Icons.file_present_outlined,
                label: 'Docs pending',
                background: Color(0xFFFFEFEF),
                iconColor: Color(0xFFB3261E),
                textColor: Color(0xFFB3261E),
              ),
      );
    }
    if (briefingSeen) {
      chips.add(
        briefingDone
            ? const _NextTripChipData(
                icon: Icons.groups_outlined,
                label: 'Briefing completed',
                background: Color(0xFFE8FBEF),
                iconColor: Color(0xFF1B8730),
                textColor: Color(0xFF1B8730),
              )
            : const _NextTripChipData(
                icon: Icons.groups_outlined,
                label: 'Briefing upcoming',
                background: Color(0xFFE7F0FF),
                iconColor: Color(0xFF0B53B0),
                textColor: Color(0xFF0B53B0),
              ),
      );
    }

    return chips;
  }

  List<Widget> _nextTripChipWidgets() {
    final data = _nextTripChipsData();
    if (data.isEmpty) return const [];
    return data
        .map(
          (chip) => _statusChip(
            chip.icon,
            chip.label,
            background: chip.background,
            iconColor: chip.iconColor,
            textColor: chip.textColor,
          ),
        )
        .toList();
  }

  void _showNoNextTripMessage([String action = '']) {
    if (!mounted) return;
    final message = action.isEmpty
        ? 'No upcoming trip yet.'
        : 'No upcoming trip to $action yet.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openNextTripDocuments() {
    final trip = _nextTrip;
    if (trip == null) {
      _showNoNextTripMessage('manage documents');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentsScreen(bookingId: trip.id, title: trip.title),
      ),
    );
  }

  void _openNextTripPayments() {
    final trip = _nextTrip;
    if (trip == null) {
      _showNoNextTripMessage('pay for');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentsScreen(bookingId: trip.id),
      ),
    );
  }

  void _openTrips() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TripsScreen(),
      ),
    );
  }

  Future<void> _retryLoadNextTripSummary() async {
    final trip = _nextTrip;
    final userId = _userId;
    if (trip == null || userId == null) {
      _showNoNextTripMessage();
      return;
    }
    await _loadNextTripSummary(trip.id, userId);
  }

  String _stepSlug(Map<String, dynamic> step) {
    final candidates = [
      step['slug'],
      step['key'],
      step['type'],
      step['action'],
      step['label'],
      step['title'],
      step['name'],
    ];
    final buffer = StringBuffer();
    for (final value in candidates) {
      if (value == null) continue;
      final text = value.toString().trim().toLowerCase();
      if (text.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write('_');
      buffer.write(text);
    }
    return buffer.toString();
  }

  bool _slugContains(String slug, List<String> keywords) {
    if (slug.isEmpty) return false;
    for (final keyword in keywords) {
      if (slug.contains(keyword)) return true;
    }
    return false;
  }

bool _stepDone(Map<String, dynamic> step) {
    final raw = step['done'] ?? step['completed'] ?? step['is_done'] ?? step['status'];
    if (raw is bool) return raw;
    if (raw is num) return raw != 0;
    if (raw is String) {
      final value = raw.trim().toLowerCase();
      if (value.isEmpty) return false;
      return value == 'done' ||
          value == 'completed' ||
          value == 'complete' ||
          value == 'success' ||
          value == '1' ||
          value == 'true';
    }
    return false;
  }

  DateTime? _stepDate(Map<String, dynamic> step, List<String> keys) {
    for (final key in keys) {
      final dt = readDateTimeOrNull(step[key]);
      if (dt != null) return dt;
    }
    return null;
  }

  DateTime? _stepCompletedAt(Map<String, dynamic> step) =>
      _stepDate(step, const ['completed_at', 'completedAt', 'done_at', 'finished_at']);

  DateTime? _stepDueAt(Map<String, dynamic> step) =>
      _stepDate(step, const ['due_date', 'due', 'deadline', 'expected_at']);

  DateTime? _stepScheduledAt(Map<String, dynamic> step) => _stepDate(
        step,
        const [
          'scheduled_at',
          'scheduled_for',
          'start_at',
          'date',
          'event_date',
          'appointment_at',
        ],
      );

  Future<void> _openWhatsApp() async {
    final phone = ConfigService.whatsappNumber.replaceAll('+', '');
    final msg = Uri.encodeComponent(ConfigService.whatsappMessage);
    final uri = Uri.parse('https://wa.me/$phone?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp')));
    }
  }

  Widget _statusChip(
    IconData icon,
    String label, {
    Color? background,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = background ??
        scheme.surfaceVariant.withOpacity(
          theme.brightness == Brightness.dark ? 0.35 : 0.65,
        );
    final iconClr = iconColor ?? scheme.onSurfaceVariant;
    final textClr = textColor ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: iconClr),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: textClr,
          ),
        ),
      ]),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = scheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isDark
                ? scheme.surfaceVariant.withOpacity(0.35)
                : scheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ]),
    );
  }

  Widget _buildNextTripCard(BuildContext context, Booking? nextTrip) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final countdown = _nextTripCountdown();
    final departureLabel = _nextTripDepartureLabel();
    final chips = _nextTripChipWidgets();
    final steps = _nextTripStepProgress();
    final hasSteps = steps.total > 0;
    final summaryError = _nextTripSummaryError;
    final summaryLoading = _nextTripSummaryLoading;

    if (nextTrip == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Next Trip',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (summaryLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'No upcoming trips yet',
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Secure your spot on the next departure and we\'ll keep a countdown here.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _openTrips,
            icon: const Icon(Icons.flight_takeoff_outlined),
            label: const Text('View trips'),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Next Trip',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (summaryLoading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else if (countdown != null)
              Text(
                countdown,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          nextTrip.title,
          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (departureLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            departureLabel,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (summaryError != null && !summaryLoading) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEAEA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD92B2B), width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFD92B2B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'We couldn\'t refresh your trip status.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD92B2B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        summaryError,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                      TextButton.icon(
                        onPressed: _retryLoadNextTripSummary,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try again'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFFD92B2B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: chips,
            ),
          ],
          if (hasSteps) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: steps.progress,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${steps.completed} of ${steps.total} tasks completed',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: summaryLoading ? null : _openNextTripDocuments,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Documents'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: summaryLoading ? null : _openNextTripPayments,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Pay balance'),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: _openTrips,
          icon: const Icon(Icons.map_outlined),
          label: const Text('View full trip timeline'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final helloName = _userName?.isNotEmpty == true ? _userName! : 'Guest';
    final nextTrip = _nextTrip;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: 'Welcome, ',
                              style: Theme.of(context).textTheme.titleLarge,
                              children: [
                                TextSpan(
                                  text: helloName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.notifications_outlined),
                        ),
                        const SizedBox(width: 4),
                        // Account shortcut
                        IconButton(
                          tooltip: 'Account',
                          icon: const Icon(Icons.account_circle_outlined),
                          onPressed: () async {
                            final isLoggedIn =
                                await AuthService.instance.isLoggedIn();
                            if (!mounted) return;
                            if (isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              );
                            } else {
                              _showAuthShortcutSheet(context);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 18,
                              offset: Offset(0, 8))
                        ],
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Sacred Journey Awaits',
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Experience the spiritual journey of a lifetime',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withOpacity(0.6),
                              )),
                          const SizedBox(height: 18),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? scheme.surfaceVariant.withOpacity(0.35)
                                  : scheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.all(14),
                            child: _buildNextTripCard(context, nextTrip),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text('Quick Actions',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _quickAction(
                          icon: Icons.cloud_upload_outlined,
                          label: 'Upload Documents',
                          onTap: _openNextTripDocuments,
                        ),
                        _quickAction(
                          icon: Icons.payments_outlined,
                          label: 'Pay Balance',
                          onTap: _openNextTripPayments,
                        ),
                        _quickAction(
                          icon: Icons.flight_takeoff_outlined,
                          label: 'My Trips',
                          onTap: _openTrips,
                        ),
                        _quickAction(
                          icon: Icons.headset_mic_outlined,
                          label: 'Support',
                          onTap: _openWhatsApp,
                        ),
                      ],
                    ),
                    if (_prayerData != null) ...[
                      const SizedBox(height: 16),
                      _PrayerTimesCard(
                        data: _prayerData!,
                        onRefresh: _load,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  void _showAuthShortcutSheet(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final bottomTheme = Theme.of(sheetContext);
        final mutedColor = bottomTheme.colorScheme.onSurfaceVariant;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 40),
              const SizedBox(height: 8),
              Text(
                'Welcome to Rotana',
                style: bottomTheme.textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Log in to manage trips, payments and documents.',
                textAlign: TextAlign.center,
                style: bottomTheme.textTheme
                    .bodyMedium
                    ?.copyWith(color: mutedColor),
              ),
              const SizedBox(height: 16),

              // Log In
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Log In'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final loggedIn = await Navigator.of(parentContext).push<bool>(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                    if (loggedIn == true && parentContext.mounted) {
                      Navigator.of(parentContext)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
              const SizedBox(height: 10),

              // Sign Up
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Sign Up'),
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    final registered = await Navigator.of(parentContext).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                    if (registered == true && parentContext.mounted) {
                      Navigator.of(parentContext)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _offerCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required num price,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentBackground = scheme.surfaceVariant.withOpacity(
      isDark ? 0.35 : 0.75,
    );
    final formatter =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 14, offset: Offset(0, 8))
          ],
        ),
        child: SizedBox(
          height: 150,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  decoration: BoxDecoration(
                    color: accentBackground,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                    ),
                  ),
                  child: Icon(
                    Icons.landscape_outlined,
                    size: 40,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                flex: 7,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: theme.textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: theme.textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const Spacer(),
                      Text('From ${formatter.format(price)}',
                          style: theme.textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isUpcomingStatus(String status) {
  final upper = status.toUpperCase();
  const archived = {'CANCELLED', 'REJECTED', 'COMPLETED'};
  return !archived.contains(upper);
}
class _NextTripChipData {
  const _NextTripChipData({
    required this.icon,
    required this.label,
    this.background,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String label;
  final Color? background;
  final Color? iconColor;
  final Color? textColor;
}

class _PrayerTimesCard extends StatefulWidget {
  const _PrayerTimesCard({required this.data, this.onRefresh});

  final PrayerTimesData data;
  final Future<void> Function()? onRefresh;

  @override
  State<_PrayerTimesCard> createState() => _PrayerTimesCardState();
}

class _PrayerTimesCardState extends State<_PrayerTimesCard> {
  final List<String> _order = const ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
  late List<_PrayerTime> _prayers;
  _PrayerTime? _nextPrayer;
  Duration _timeRemaining = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _prepareData();
  }

  @override
  void didUpdateWidget(covariant _PrayerTimesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.timings != widget.data.timings ||
        oldWidget.data.city != widget.data.city ||
        oldWidget.data.country != widget.data.country) {
      _prepareData();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _prepareData() {
    _timer?.cancel();
    _prayers = _buildPrayers();
    _updateNextPrayer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  List<_PrayerTime> _buildPrayers() {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    var dayOffset = 0;
    DateTime? lastTime;
    final list = <_PrayerTime>[];
    for (final name in _order) {
      final raw = widget.data.timings[name];
      if (raw == null) continue;
      var dateTime = _parseTime(raw, base.add(Duration(days: dayOffset)));
      if (dateTime == null) continue;
      if (lastTime != null && dateTime.isBefore(lastTime)) {
        dayOffset += 1;
        dateTime = _parseTime(raw, base.add(Duration(days: dayOffset)));
        if (dateTime == null) continue;
      }
      lastTime = dateTime;
      list.add(_PrayerTime(name: name, dateTime: dateTime, raw: raw));
    }
    return list;
  }

  void _updateNextPrayer() {
    if (_prayers.isEmpty) {
      setState(() {
        _nextPrayer = null;
        _timeRemaining = Duration.zero;
      });
      return;
    }
    final now = DateTime.now();
    _PrayerTime next = _prayers.first;
    for (final prayer in _prayers) {
      if (prayer.dateTime.isAfter(now)) {
        next = prayer;
        break;
      }
    }
    if (!next.dateTime.isAfter(now)) {
      next = _prayers.first.copyWith(dateTime: _prayers.first.dateTime.add(const Duration(days: 1)));
    }
    setState(() {
      _nextPrayer = next;
      _timeRemaining = next.dateTime.difference(now).isNegative
          ? Duration.zero
          : next.dateTime.difference(now);
    });
  }

  void _tick() {
    if (!mounted) return;
    if (_nextPrayer == null) {
      _updateNextPrayer();
      return;
    }
    final now = DateTime.now();
    if (!_nextPrayer!.dateTime.isAfter(now)) {
      _prayers = _buildPrayers();
      _updateNextPrayer();
      return;
    }
    final remaining = _nextPrayer!.dateTime.difference(now);
    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  DateTime? _parseTime(String raw, DateTime day) {
    final cleaned = raw.split(' ').first;
    final parts = cleaned.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  IconData _iconForPrayer(String name) {
    switch (name) {
      case 'Fajr':
        return Icons.nightlight_round;
      case 'Sunrise':
        return Icons.wb_sunny_outlined;
      case 'Dhuhr':
        return Icons.wb_sunny;
      case 'Asr':
        return Icons.wb_cloudy_outlined;
      case 'Maghrib':
        return Icons.wb_twilight;
      case 'Isha':
        return Icons.brightness_3_outlined;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = '${widget.data.city}, ${widget.data.country}';
    final nextName = _nextPrayer?.name ?? 'Fajr';
    final remainingText = _formatRemaining(_timeRemaining);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C1053), Color(0xFF3A1852), Color(0xFF02010A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: widget.onRefresh,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_nextPrayer != null) ...[
            Text(
              'Left until $nextName prayer',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              remainingText,
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _prayers.map((p) {
              final isActive = _nextPrayer != null && p.name == _nextPrayer!.name;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_iconForPrayer(p.name),
                          color: isActive ? const Color(0xFFFFD166) : Colors.white70,
                          size: 24),
                      const SizedBox(height: 6),
                      Text(
                        p.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(p.dateTime),
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PrayerTime {
  const _PrayerTime({
    required this.name,
    required this.dateTime,
    required this.raw,
  });

  final String name;
  final DateTime dateTime;
  final String raw;

  _PrayerTime copyWith({DateTime? dateTime}) => _PrayerTime(
        name: name,
        dateTime: dateTime ?? this.dateTime,
        raw: raw,
      );
}
