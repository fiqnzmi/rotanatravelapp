import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart' show NoConnectionException;
import '../services/booking_service.dart';
import '../models/package_detail.dart';
import '../utils/error_utils.dart';
import '../widgets/no_connection_view.dart';
import 'booking_wizard_screen.dart';

class PackageDetailScreen extends StatefulWidget {
  final int packageId;
  const PackageDetailScreen({super.key, required this.packageId});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> with TickerProviderStateMixin {
  final _svc = BookingService();
  late Future<PackageDetail> _future;

  @override
  void initState() { super.initState(); _future = _load(); }

  Future<PackageDetail> _load() async {
    final data = await _svc.fetchPackageDetail(widget.packageId);
    return PackageDetail.fromJson(data);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<PackageDetail>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              final error = snap.error;
              if (error is NoConnectionException) {
                return Center(child: NoConnectionView(onRetry: _reload));
              }
              return Center(child: Text('Error: ${friendlyError(error ?? 'Unknown error')}'));
            }
            final p = snap.data!;
            return _Body(detail: p);
          },
        ),
      ),
    );
  }
}

class _Body extends StatefulWidget {
  final PackageDetail detail;
  const _Body({required this.detail});
  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = widget.detail;
    final money = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 92),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                  Expanded(
                    child: Text(p.title, textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
                  IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: (p.images.isNotEmpty)
                      ? PageView(children: p.images.map((u) => Image.network(u, fit: BoxFit.cover)).toList())
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(
                                Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.75,
                              ),
                          child: Center(
                            child: Text(
                              'Premium Umrah Package Gallery',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                  const SizedBox(width: 4),
                  Text('${(p.ratingAvg ?? 0).toStringAsFixed(1)} ${p.ratingCount != null ? '(${p.ratingCount})' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Icon(Icons.event_outlined, size: 18, color: muted),
                  const SizedBox(width: 6),
                  Text(
                    '${p.durationDays ?? 0} days',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.place_outlined, size: 18, color: muted),
                  const SizedBox(width: 6),
                  Text(
                    p.cities ?? '-',
                    style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
                  ),
                ]),
                const SizedBox(height: 14),
                Text('From ${money.format(p.price)}',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Available Departures',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 8),
            ...p.departures.map((d) => _DepartureCard(dep: d)).toList(),
            const SizedBox(height: 8),
            TabBar(
              controller: _tabs,
              isScrollable: true,
              labelPadding: const EdgeInsets.symmetric(horizontal: 18),
              tabs: const [Tab(text: 'Inclusions'), Tab(text: 'Itinerary'), Tab(text: 'FAQs'), Tab(text: 'Reviews')],
            ),
            SizedBox(
              height: 360,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InclusionsTab(items: p.inclusions),
                  _ItineraryTab(items: p.itinerary),
                  _FaqsTab(items: p.faqs),
                  const _ReviewsTab(),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
        Positioned(
          left: 16, right: 16, bottom: 16,
          child: SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingWizardScreen(packageId: p.id, price: p.price, title: p.title),
                ),
              ),
              child: const Text('Book This Package'),
            ),
          ),
        ),
      ],
    );
  }
}

class _DepartureCard extends StatelessWidget {
  final Departure dep;
  const _DepartureCard({required this.dep});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    Widget priceRow(DepartureTier t) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.name, style: theme.textTheme.bodySmall?.copyWith(color: muted)),
          const SizedBox(height: 4),
          Text(money.format(t.price), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
        ]);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 8))],
      ),
      child: Column(children: [
        Row(children: [
          Text(DateFormat('MMMM d, yyyy').format(DateTime.parse(dep.date)),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const Spacer(),
          if ((dep.note ?? '').isNotEmpty)
            Text(
              dep.note!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (dep.tiers.isNotEmpty) ...[
            Expanded(child: priceRow(dep.tiers[0])),
            if (dep.tiers.length > 1) Expanded(child: priceRow(dep.tiers[1])),
            if (dep.tiers.length > 2) Expanded(child: priceRow(dep.tiers[2])),
          ],
          const SizedBox(width: 12),
          FilledButton(onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select on booking step'))); },
              child: const Text('Select')),
        ]),
      ]),
    );
  }
}

class _InclusionsTab extends StatelessWidget {
  final List<String> items;
  const _InclusionsTab({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No inclusions provided'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(items[i])),
        ],
      ),
    );
  }
}

class _ItineraryTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _ItineraryTab({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No itinerary available'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (_, i) {
        final m = items[i];
        return ListTile(
          leading: CircleAvatar(child: Text('${m['day'] ?? i + 1}')),
          title: Text(m['title'] ?? 'Day ${i + 1}'),
          subtitle: Text(m['desc'] ?? ''),
        );
      },
    );
  }
}

class _FaqsTab extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _FaqsTab({required this.items});
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const Center(child: Text('No FAQs added'));
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final m = items[i];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m['q'] ?? '-', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(m['a'] ?? ''),
        ]);
      },
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Reviews coming soon'));
}
