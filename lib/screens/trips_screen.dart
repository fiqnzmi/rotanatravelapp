import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/api_client.dart' show NoConnectionException;
import '../services/booking_service.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../utils/json_utils.dart';
import '../utils/error_utils.dart';
import '../models/booking.dart';
import '../widgets/no_connection_view.dart';
import 'documents_screen.dart';
import 'payments_screen.dart';
import 'login_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _svc = BookingService();
  final _dash = DashboardService();
  late Future<_TripsResult> _future;
  List<Booking> _cachedBookings = const [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_TripsResult> _load() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      setState(() => _cachedBookings = const []);
      return const _TripsResult(loggedIn: false, bookings: []);
    }
    final bookings = await _svc.myBookings();
    _cachedBookings = bookings;
    return _TripsResult(loggedIn: true, bookings: bookings);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Widget _stepsBar(BuildContext context, List<Map<String, dynamic>> steps) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final done = steps.where((s) => s['done'] == true).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        'Progress: $done of ${steps.length} steps completed',
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      LinearProgressIndicator(
        value: steps.isEmpty ? 0 : done / steps.length,
        backgroundColor: scheme.surfaceVariant.withOpacity(0.6),
        valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
        minHeight: 6,
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: steps.map((s) {
        final ok = s['done'] == true;
        return Column(children: [
          Icon(
            ok ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: ok ? scheme.primary : scheme.outlineVariant,
          ),
          const SizedBox(height: 4),
          Text(
            s['label'],
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ]);
      }).toList()),
    ]);
  }

  Future<void> _openDetails(Booking b) async {
    final uid = await AuthService.instance.getUserId() ?? 0;
    if (!mounted) return;
    Map<String, dynamic> summary;
    try {
      final data = await _dash.bookingSummary(b.id, uid);
      summary = Map<String, dynamic>.from(data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load booking details: ${friendlyError(e)}')),
      );
      return;
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) => _BookingDetailSheet(
        booking: b,
        summary: summary,
        onOpenDocuments: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentsScreen(bookingId: b.id, title: b.title),
            ),
          );
        },
        onOpenPayments: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentsScreen(bookingId: b.id),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: scheme.background,
        appBar: AppBar(
          title: const Text('My Trips'),
          bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')]),
          actions: [
            IconButton(
              tooltip: 'Search trips',
              onPressed: _openSearch,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: FutureBuilder(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final error = snap.error;
              if (error is NoConnectionException) {
                return Center(child: NoConnectionView(onRetry: _reload));
              }
              return Center(child: Text('Error: ${friendlyError(error ?? 'Unknown error')}'));
            }
            final result = snap.data as _TripsResult;
            if (!result.loggedIn) {
              return _TripsLoginPrompt(onLogin: () async {
                final loggedIn = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
                if (loggedIn == true && mounted) {
                  _reload();
                }
              });
            }
            final all = result.bookings;
            final upcoming = all.where((b) => _isUpcomingStatus(b.status)).toList();
            final past = all.where((b) => !_isUpcomingStatus(b.status)).toList();
            return TabBarView(children: [_list(upcoming), _list(past)]);
          },
        ),
      ),
    );
  }

  Future<void> _openSearch() async {
    final loggedIn = await AuthService.instance.isLoggedIn();
    if (!loggedIn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (ok == true) {
        _reload();
      }
      return;
    }
    if (_cachedBookings.isEmpty) {
      _cachedBookings = await _svc.myBookings();
    }
    final result = await showSearch<Booking?>(
      context: context,
      delegate: _TripSearchDelegate(_cachedBookings),
    );
    if (result != null) {
      _openDetails(result);
    }
  }

  Widget _list(List<Booking> items) {
    if (items.isEmpty) return const Center(child: Text('No trips here'));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = items[i];
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      b.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _statusPill(b.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Departure: —',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              FutureBuilder(
                future: AuthService.instance.getUserId().then((uid)=>_dash.bookingSummary(b.id, uid ?? 0)),
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator(minHeight: 6);
                  if (snap.hasError) {
                    final error = snap.error;
                    if (error is NoConnectionException) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          NoConnectionException.defaultMessage,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  final steps = (snap.data!['steps'] as List).cast<Map<String,dynamic>>();
                  return _stepsBar(context, steps);
                },
              ),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight,
                child: OutlinedButton(onPressed: ()=>_openDetails(b), child: const Text('View Details'))),
            ]),
          ),
        );
      },
    );
  }

}

String _stepLabel(Map<String, dynamic> step) {
  final candidates = [
    step['label'],
    step['title'],
    step['name'],
    step['step'],
  ];
  for (final value in candidates) {
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return 'Step';
}

String _stepSlug(Map<String, dynamic> step) {
  final parts = <String>[];
  for (final key in ['slug', 'key', 'type', 'action', 'step', 'label', 'title', 'name']) {
    final value = step[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) parts.add(text.toLowerCase());
  }
  if (parts.isEmpty) return '';
  final joined = parts.join('_');
  return joined.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
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

bool _isUpcomingStatus(String status) {
  final upper = status.toUpperCase();
  const archived = {'CANCELLED', 'REJECTED', 'COMPLETED'};
  return !archived.contains(upper);
}

Widget _statusPill(String status) {
  final upper = status.toUpperCase();
  Color bg;
  switch (upper) {
    case 'CONFIRMED':
      bg = Colors.green.shade600;
      break;
    case 'READY_FOR_REVIEW':
      bg = Colors.blue.shade600;
      break;
    case 'CANCELLED':
    case 'REJECTED':
      bg = Colors.red.shade700;
      break;
    default:
      bg = Colors.orange.shade700;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
    child: Text(
      upper.replaceAll('_', ' '),
      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
    ),
  );
}

DateTime? _stepDate(Map<String, dynamic> step, List<String> keys) {
  for (final key in keys) {
    final value = step[key];
    final dt = readDateTimeOrNull(value);
    if (dt != null) return dt;
  }
  return null;
}

DateTime? _stepCompletedAt(Map<String, dynamic> step) =>
    _stepDate(step, ['completed_at', 'completedAt', 'done_at', 'finished_at']);

DateTime? _stepDueAt(Map<String, dynamic> step) =>
    _stepDate(step, ['due_date', 'due', 'deadline', 'expected_at']);

DateTime? _stepScheduledAt(Map<String, dynamic> step) => _stepDate(
    step,
    [
      'scheduled_at',
      'scheduled_for',
      'start_at',
      'date',
      'event_date',
      'appointment_at'
    ]);

String _prettyStatus(String input) {
  final text = input.replaceAll('_', ' ').trim();
  if (text.isEmpty) return '';
  return text
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

String _stepStatusText(Map<String, dynamic> step, bool done) {
  final raw = step['status'];
  if (raw is String && raw.trim().isNotEmpty) {
    return _prettyStatus(raw);
  }
  if (done) return 'Completed';
  return 'Pending';
}

String? _stepNotes(Map<String, dynamic> step) {
  final candidates = [
    step['notes'],
    step['description'],
    step['details'],
    step['message'],
    step['instruction'],
    step['instructions'],
    step['remark'],
    step['remarks'],
  ];
  for (final value in candidates) {
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return null;
}

bool _slugContains(String slug, List<String> keywords) {
  if (slug.isEmpty) return false;
  return keywords.any((k) => slug.contains(k));
}

IconData _iconForSlug(String slug, bool done) {
  if (_slugContains(slug, ['doc', 'passport', 'visa'])) {
    return Icons.description_outlined;
  }
  if (_slugContains(slug, ['pay', 'payment', 'invoice', 'balance', 'deposit', 'fpx'])) {
    return Icons.payments_outlined;
  }
  if (_slugContains(slug, ['brief', 'briefing', 'meeting', 'orientation'])) {
    return Icons.groups_outlined;
  }
  if (_slugContains(slug, ['travel', 'flight', 'depart', 'departure'])) {
    return Icons.flight_takeoff_outlined;
  }
  return done ? Icons.check_circle_outline : Icons.flag_outlined;
}

String? _defaultActionLabel(String slug, bool done) {
  if (_slugContains(slug, ['doc', 'passport', 'visa'])) {
    return done ? 'View documents' : 'Upload documents';
  }
  if (_slugContains(slug, ['pay', 'payment', 'invoice', 'balance', 'deposit', 'fpx'])) {
    return done ? 'View payment' : 'Pay now';
  }
  if (_slugContains(slug, ['brief', 'briefing', 'meeting', 'orientation'])) {
    return 'View briefing';
  }
  return null;
}

class _BookingDetailSheet extends StatelessWidget {
  const _BookingDetailSheet({
    required this.booking,
    required this.summary,
    required this.onOpenDocuments,
    required this.onOpenPayments,
  });

  final Booking booking;
  final Map<String, dynamic> summary;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenPayments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final steps = (summary['steps'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final created =
        readDateTimeOrNull(summary['created_at']) ?? booking.createdAt;
    final travelDate = readDateTimeOrNull(
      summary['travel_date'] ?? summary['departure_date'] ?? summary['start_date'],
    );
    final fmt = DateFormat('dd MMM yyyy');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                booking.title,
                style: theme
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Booking #${booking.id} • Created ${fmt.format(created)}',
                style: theme
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: muted),
              ),
              if (travelDate != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Travel date: ${fmt.format(travelDate)}',
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: muted),
                ),
              ],
              const SizedBox(height: 18),
              _BookingTimeline(
                steps: steps,
                onOpenDocuments: onOpenDocuments,
                onOpenPayments: onOpenPayments,
                onOpenBriefing: (step) => _showBriefing(context, step),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick actions',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpenDocuments,
                    icon: const Icon(Icons.description_outlined),
                    label: const Text('Documents'),
                  ),
                  FilledButton.icon(
                    onPressed: onOpenPayments,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Pay balance'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBriefing(BuildContext context, Map<String, dynamic> step) {
    final briefing = summary['briefing'] is Map
        ? Map<String, dynamic>.from(summary['briefing'] as Map)
        : const <String, dynamic>{};
    final scheduled = _stepScheduledAt(step) ??
        _stepDueAt(step) ??
        _stepDate(briefing, [
          'scheduled_at',
          'scheduled_for',
          'meeting_time',
          'meeting_at',
        ]);
    final location = (step['location'] ??
            briefing['location'] ??
            briefing['venue'] ??
            briefing['address'] ??
            '')
        .toString()
        .trim();
    final notes = _stepNotes(step) ??
        (briefing['notes'] ??
                briefing['details'] ??
                briefing['description'] ??
                '')
            .toString()
            .trim();
    final fmt = DateFormat('dd MMM yyyy • h:mm a');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Travel briefing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (scheduled != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.access_time, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fmt.format(scheduled),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (location.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (notes.isNotEmpty)
              Text(
                notes,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
              )
            else
              Text(
                'Your travel consultant will share the briefing details soon.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _BookingTimeline extends StatelessWidget {
  const _BookingTimeline({
    required this.steps,
    this.onOpenDocuments,
    this.onOpenPayments,
    this.onOpenBriefing,
  });

  final List<Map<String, dynamic>> steps;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenPayments;
  final void Function(Map<String, dynamic> step)? onOpenBriefing;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(
                Theme.of(context).brightness == Brightness.dark ? 0.25 : 0.65,
              ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'We\'ll update your booking timeline as soon as new actions are available.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;
        return _TimelineItem(
          step: step,
          isLast: isLast,
          onOpenDocuments: onOpenDocuments,
          onOpenPayments: onOpenPayments,
          onOpenBriefing: onOpenBriefing,
        );
      }),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.step,
    required this.isLast,
    this.onOpenDocuments,
    this.onOpenPayments,
    this.onOpenBriefing,
  });

  final Map<String, dynamic> step;
  final bool isLast;
  final VoidCallback? onOpenDocuments;
  final VoidCallback? onOpenPayments;
  final void Function(Map<String, dynamic> step)? onOpenBriefing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final successColor = const Color(0xFF1B8730);
    final successContainer = scheme.secondaryContainer;
    final pendingContainer = scheme.secondary.withOpacity(
      theme.brightness == Brightness.dark ? 0.35 : 0.15,
    );
    final timelineSurface = theme.cardColor;
    final slug = _stepSlug(step);
    final done = _stepDone(step);
    final statusText = _stepStatusText(step, done);
    final notes = _stepNotes(step);
    final completed = _stepCompletedAt(step);
    final due = _stepDueAt(step);
    final scheduled = _stepScheduledAt(step);
    final fmt = DateFormat('dd MMM yyyy');

    String? dateLabel;
    Color? dateColor;
    if (completed != null) {
      dateLabel = 'Completed ${fmt.format(completed)}';
      dateColor = const Color(0xFF1B8730);
    } else if (due != null && !done) {
      dateLabel = 'Due ${fmt.format(due)}';
      dateColor = const Color(0xFFB35C00);
    } else if (scheduled != null) {
      dateLabel = fmt.format(scheduled);
      dateColor = muted;
    }

    final actionLabelRaw = step['action_label'] ??
        step['cta'] ??
        step['button'] ??
        step['button_label'];
    String? actionLabel;
    if (actionLabelRaw is String && actionLabelRaw.trim().isNotEmpty) {
      actionLabel = actionLabelRaw.trim();
    } else {
      actionLabel = _defaultActionLabel(slug, done);
    }

    final actionCallback = _resolveAction(
      slug: slug,
      step: step,
      onOpenDocuments: onOpenDocuments,
      onOpenPayments: onOpenPayments,
      onOpenBriefing: onOpenBriefing,
    );

    final icon = _iconForSlug(slug, done);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: done ? successColor : timelineSurface,
                  border: Border.all(
                    color: done
                        ? successColor
                        : scheme.outlineVariant,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: scheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: timelineSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: done
                      ? successColor.withOpacity(0.45)
                      : scheme.outlineVariant,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x07000000),
                    blurRadius: 12,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        icon,
                        size: 24,
                        color: done ? successColor : scheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stepLabel(step),
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: done ? successContainer : pendingContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: done ? successColor : scheme.primary,
                                    ),
                                  ),
                                ),
                                if (dateLabel != null) ...[
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      dateLabel,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: dateColor ?? muted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (notes != null && notes.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      notes,
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                    ),
                  ],
                  if (actionCallback != null && actionLabel != null) ...[
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: actionCallback,
                      child: Text(actionLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback? _resolveAction({
    required String slug,
    required Map<String, dynamic> step,
    VoidCallback? onOpenDocuments,
    VoidCallback? onOpenPayments,
    void Function(Map<String, dynamic> step)? onOpenBriefing,
  }) {
    if (_slugContains(slug, ['doc', 'passport', 'visa'])) {
      return onOpenDocuments;
    }
    if (_slugContains(slug, ['pay', 'payment', 'invoice', 'balance', 'deposit', 'fpx'])) {
      return onOpenPayments;
    }
    if (_slugContains(slug, ['brief', 'briefing', 'meeting', 'orientation'])) {
      if (onOpenBriefing == null) return null;
      return () => onOpenBriefing(step);
    }
    final action = step['action']?.toString().toLowerCase() ?? '';
    if (action.contains('document') && onOpenDocuments != null) return onOpenDocuments;
    if (action.contains('payment') && onOpenPayments != null) return onOpenPayments;
    if (action.contains('brief') && onOpenBriefing != null) {
      return () => onOpenBriefing(step);
    }
    return null;
  }
}

class _TripsResult {
  final bool loggedIn;
  final List<Booking> bookings;
  const _TripsResult({required this.loggedIn, required this.bookings});
}

class _TripsLoginPrompt extends StatelessWidget {
  const _TripsLoginPrompt({required this.onLogin});
  final Future<void> Function() onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.flight_takeoff_outlined, size: 72, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            'Log in to view your trips',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Save bookings, track progress, and manage documents once you sign in.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
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

class _TripSearchDelegate extends SearchDelegate<Booking?> {
  _TripSearchDelegate(this.bookings);
  final List<Booking> bookings;

  List<Booking> _results(String query) {
    if (query.trim().isEmpty) return bookings;
    final lower = query.toLowerCase();
    return bookings.where((b) {
      return b.title.toLowerCase().contains(lower) ||
          (b.status.toLowerCase().contains(lower));
    }).toList();
  }

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = _results(query);
    if (filtered.isEmpty) {
      return const Center(child: Text('No trips match your search.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final b = filtered[i];
        return ListTile(
          title: Text(b.title),
          subtitle: Text('Status: ${b.status}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => close(context, b),
        );
      },
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );
}
