import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_client.dart' show NoConnectionException;
import '../services/package_service.dart';
import '../models/package.dart';
import 'package_detail_screen.dart';
import '../utils/error_utils.dart';
import '../widgets/premium.dart';
import '../widgets/premium_chip.dart';
import '../widgets/no_connection_view.dart';


class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});
  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final _svc = PackageService();
  late Future<List<TravelPackage>> _future;

  @override
  void initState() { super.initState(); _future = _svc.listPackages(); }

  void _reload() {
    if (!mounted) return;
    setState(() { _future = _svc.listPackages(); });
  }

  String _subtitle(TravelPackage p) {
    final parts = <String>[];
    if ((p.durationDays ?? 0) > 0) parts.add('${p.durationDays} days');
    if ((p.cities ?? '').isNotEmpty) parts.add(p.cities!);
    if ((p.hotelStars ?? 0) > 0) parts.add('${p.hotelStars}-star hotels');
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Packages'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
        ],
      ),
      body: FutureBuilder<List<TravelPackage>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) {
            final err = snap.error;
            if (err is NoConnectionException) {
              return Center(child: NoConnectionView(onRetry: _reload));
            }
            return Center(child: Text('Error: ${friendlyError(err ?? 'Unknown error')}'));
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('No packages available'));

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _chip(context, 'All Months', selected: true), const SizedBox(width: 8),
                  _chip(context, 'Price Range'), const SizedBox(width: 8),
                  _chip(context, 'Room Size'), const SizedBox(width: 8),
                ]),
              ),
              const SizedBox(height: 12),
              ...items.map((p) {
                final subtitle = _subtitle(p);
                final rating = p.ratingAvg ?? 4.5;
                final price = money.format(p.price);
                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x15000000), blurRadius: 18, offset: Offset(0, 8))],
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: (p.coverImage != null)
                            ? Image.network(p.coverImage!, fit: BoxFit.cover)
                            : Container(
                                color: scheme.surfaceVariant.withOpacity(0.6),
                                child: Icon(Icons.image_outlined, size: 48, color: scheme.onSurfaceVariant),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text(p.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                          const SizedBox(width: 4),
                          Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 4),
                        if (subtitle.isNotEmpty)
                          Text(
                            subtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        const SizedBox(height: 12),
                        if ((p.hotelStars ?? 0) >= 5) ...[const PremiumChip(), const SizedBox(height: 12)],
                        Row(children: [
                          Expanded(
                            child: Text('From $price per person',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.push(
                              context, MaterialPageRoute(builder: (_) => PackageDetailScreen(packageId: p.id))),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text('View Details'),
                          ),
                        ]),
                      ]),
                    ),
                  ]),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(BuildContext context, String label, {bool selected = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? scheme.primary : scheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? scheme.onPrimary : scheme.onSurface,
        ),
      ),
    );
  }
}
