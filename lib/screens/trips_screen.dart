import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import 'documents_screen.dart';
import 'payments_screen.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});
  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  final _svc = BookingService();
  final _dash = DashboardService();
  late Future<List<Booking>> _future;

  @override
  void initState() { super.initState(); _future = _svc.myBookings(); }

  Widget _stepsBar(List<Map<String, dynamic>> steps) {
    final done = steps.where((s) => s['done'] == true).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Progress: $done of ${steps.length} steps completed', style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      LinearProgressIndicator(value: done / steps.length),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: steps.map((s) {
        final ok = s['done'] == true;
        return Column(children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked, size: 18, color: ok ? Colors.green : Colors.grey),
          const SizedBox(height: 4),
          Text(s['label'], style: const TextStyle(fontSize: 12)),
        ]);
      }).toList()),
    ]);
  }

  Future<void> _openDetails(Booking b) async {
    final uid = await AuthService.instance.getUserId() ?? 0;
    if (!mounted) return;
    final data = await _dash.bookingSummary(b.id, uid);
    if (!mounted) return;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            _stepsBar((data['steps'] as List).cast<Map<String,dynamic>>()),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => DocumentsScreen(bookingId: b.id, title: b.title)));
                }, child: const Text('Document Centre'))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentsScreen(bookingId: b.id)));
                }, child: const Text('Payments'))),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('My Trips'), bottom: const TabBar(tabs: [Tab(text: 'Upcoming'), Tab(text: 'Past')]),
            actions: [IconButton(onPressed: (){}, icon: const Icon(Icons.search))]),
        body: FutureBuilder(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
            final all = (snap.data as List<Booking>);
            final upcoming = all.where((b)=>b.status=='CONFIRMED').toList();
            final past = all.where((b)=>b.status!='CONFIRMED').toList();
            return TabBarView(children: [_list(upcoming), _list(past)]);
          },
        ),
      ),
    );
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
              Text(b.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Departure: —', style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 10),
              FutureBuilder(
                future: AuthService.instance.getUserId().then((uid)=>_dash.bookingSummary(b.id, uid ?? 0)),
                builder: (_, snap) {
                  if (snap.connectionState != ConnectionState.done) return const LinearProgressIndicator(minHeight: 6);
                  if (snap.hasError) return const SizedBox.shrink();
                  final steps = (snap.data!['steps'] as List).cast<Map<String,dynamic>>();
                  return _stepsBar(steps);
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
