import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/package.dart';
import '../services/api_client.dart' show NoConnectionException;
import '../services/package_service.dart';
import '../utils/error_utils.dart';
import '../widgets/no_connection_view.dart';
import '../widgets/premium_chip.dart';
import 'package_detail_screen.dart';

class PackagesScreen extends StatefulWidget {
  const PackagesScreen({super.key});

  @override
  State<PackagesScreen> createState() => _PackagesScreenState();
}

class _PackagesScreenState extends State<PackagesScreen> {
  final _svc = PackageService();

  List<TravelPackage> _packages = const [];
  bool _loading = true;
  Object? _error;

  _MonthOption? _selectedMonth;
  RangeValues? _selectedPriceRange;
  String? _selectedRoomSize;

  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  Future<void> _fetchPackages() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _svc.listPackages();
      if (!mounted) return;
      setState(() {
        _packages = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _packages = const [];
        _loading = false;
      });
    }
  }

  bool get _canUseFilters => !_loading && _packages.isNotEmpty;
  bool get _hasActiveFilters =>
      _selectedMonth != null || _selectedPriceRange != null || _selectedRoomSize != null;

  void _reload() => _fetchPackages();

  String _subtitle(TravelPackage p) {
    final parts = <String>[];
    if ((p.durationDays ?? 0) > 0) parts.add('${p.durationDays} days');
    if ((p.cities ?? '').isNotEmpty) parts.add(p.cities!);
    if ((p.hotelStars ?? 0) > 0) parts.add('${p.hotelStars}-star hotels');
    return parts.join(' • ');
  }

  void _openPackage(TravelPackage pkg) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PackageDetailScreen(packageId: pkg.id)),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  NumberFormat _moneyFormatter() =>
      NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

  void _openSearch() {
    if (!_canUseFilters) {
      _showSnack('Packages are still loading. Please try again in a moment.');
      return;
    }
    showSearch<void>(
      context: context,
      delegate: _PackageSearchDelegate(
        packages: _packages,
        money: _moneyFormatter(),
        onSelect: _openPackage,
      ),
    );
  }

  void _openFilterPanel() {
    if (!_canUseFilters) {
      _showSnack('Load packages before opening filters.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month_outlined),
              title: const Text('Travel month'),
              subtitle: Text(_selectedMonth?.label ?? 'All months'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickMonth();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Price range'),
              subtitle: Text(_priceLabel(_moneyFormatter())),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPriceRange();
              },
            ),
            ListTile(
              leading: const Icon(Icons.meeting_room_outlined),
              title: const Text('Room size / tier'),
              subtitle: Text(_selectedRoomSize ?? 'Any room size'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickRoomSize();
              },
            ),
            if (_hasActiveFilters)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _clearFilters();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset filters'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedMonth = null;
      _selectedPriceRange = null;
      _selectedRoomSize = null;
    });
  }

  Future<void> _pickMonth() async {
    final options = _monthOptions(_packages);
    if (options.isEmpty) {
      _showSnack('Departure dates are not available yet.');
      return;
    }
    final optionMap = {for (final opt in options) opt.key: opt};
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All months'),
              trailing: _selectedMonth == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(ctx).pop(''),
            ),
            const Divider(height: 0),
            ...options.map(
              (opt) => ListTile(
                title: Text(opt.label),
                trailing: _selectedMonth?.key == opt.key ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(opt.key),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _selectedMonth = result.isEmpty ? null : optionMap[result];
    });
  }

  Future<void> _pickRoomSize() async {
    final options = _roomSizeOptions(_packages);
    if (options.isEmpty) {
      _showSnack('Room size data is not available for these packages yet.');
      return;
    }
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Any room size'),
              trailing: _selectedRoomSize == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(ctx).pop(''),
            ),
            const Divider(height: 0),
            ...options.map(
              (name) => ListTile(
                title: Text(name),
                trailing: _selectedRoomSize == name ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(ctx).pop(name),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _selectedRoomSize = result.isEmpty ? null : result;
    });
  }

  Future<void> _pickPriceRange() async {
    final bounds = _priceBounds(_packages);
    if (bounds == null) {
      _showSnack('Price data is not available yet.');
      return;
    }
    if ((bounds.max - bounds.min).abs() < 1) {
      _showSnack('All packages currently start at ${_moneyFormatter().format(bounds.min)}.');
      return;
    }
    final currency = _moneyFormatter();
    RangeValues current = _selectedPriceRange ?? RangeValues(bounds.min, bounds.max);
    final result = await showModalBottomSheet<RangeValues>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${currency.format(current.start)} - ${currency.format(current.end)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  RangeSlider(
                    values: current,
                    min: bounds.min,
                    max: bounds.max,
                    divisions: 20,
                    labels: RangeLabels(
                      currency.format(current.start),
                      currency.format(current.end),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        current = RangeValues(
                          val.start.clamp(bounds.min, bounds.max),
                          val.end.clamp(bounds.min, bounds.max),
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(RangeValues(bounds.min, bounds.max)),
                        child: const Text('Clear'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(current),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.start <= bounds.min && result.end >= bounds.max) {
        _selectedPriceRange = null;
      } else {
        _selectedPriceRange = RangeValues(
          result.start.roundToDouble(),
          result.end.roundToDouble(),
        );
      }
    });
  }

  List<TravelPackage> _applyFilters(List<TravelPackage> source) {
    final monthFormatter = DateFormat('yyyy-MM');
    return source.where((pkg) {
      if (_selectedMonth != null) {
        final matchesMonth = pkg.departures.any((dep) {
          final dt = DateTime.tryParse(dep.date);
          if (dt == null) return false;
          return monthFormatter.format(dt) == _selectedMonth!.key;
        });
        if (!matchesMonth) return false;
      }
      if (_selectedRoomSize != null) {
        final matchesRoom = pkg.departures.any(
          (dep) => dep.tiers.any(
            (tier) => tier.name.toLowerCase() == _selectedRoomSize!.toLowerCase(),
          ),
        );
        if (!matchesRoom) return false;
      }
      if (_selectedPriceRange != null && !_isPriceInRange(pkg, _selectedPriceRange!)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool _isPriceInRange(TravelPackage pkg, RangeValues range) {
    final start = range.start;
    final end = range.end;
    bool within(double price) => price >= start && price <= end;
    if (within(pkg.price)) return true;
    for (final dep in pkg.departures) {
      for (final tier in dep.tiers) {
        if (within(tier.price)) return true;
      }
    }
    return false;
  }

  List<_MonthOption> _monthOptions(List<TravelPackage> packages) {
    final keyFmt = DateFormat('yyyy-MM');
    final labelFmt = DateFormat('MMM yyyy');
    final map = <String, _MonthOption>{};
    for (final pkg in packages) {
      for (final dep in pkg.departures) {
        final dt = DateTime.tryParse(dep.date);
        if (dt == null) continue;
        final key = keyFmt.format(dt);
        map.putIfAbsent(key, () => _MonthOption(key: key, label: labelFmt.format(dt)));
      }
    }
    final list = map.values.toList()..sort((a, b) => a.key.compareTo(b.key));
    return list;
  }

  List<String> _roomSizeOptions(List<TravelPackage> packages) {
    final set = <String>{};
    for (final pkg in packages) {
      for (final dep in pkg.departures) {
        for (final tier in dep.tiers) {
          final trimmed = tier.name.trim();
          if (trimmed.isNotEmpty) set.add(trimmed);
        }
      }
    }
    final list = set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  _PriceBounds? _priceBounds(List<TravelPackage> packages) {
    double? min;
    double? max;
    void consider(double value) {
      min = (min == null) ? value : (value < min! ? value : min);
      max = (max == null) ? value : (value > max! ? value : max);
    }

    for (final pkg in packages) {
      consider(pkg.price);
      for (final dep in pkg.departures) {
        for (final tier in dep.tiers) {
          consider(tier.price);
        }
      }
    }
    if (min == null || max == null) return null;
    return _PriceBounds(min: min!, max: max!);
  }

  String _priceLabel(NumberFormat money) {
    if (_selectedPriceRange == null) return 'Price Range';
    return '${money.format(_selectedPriceRange!.start)} - ${money.format(_selectedPriceRange!.end)}';
  }

  Widget _buildFilterHeader(BuildContext context, NumberFormat money) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _chip(
                context,
                _selectedMonth?.label ?? 'All Months',
                selected: _selectedMonth != null,
                onTap: _canUseFilters ? _pickMonth : null,
              ),
              const SizedBox(width: 8),
              _chip(
                context,
                _priceLabel(money),
                selected: _selectedPriceRange != null,
                onTap: _canUseFilters ? _pickPriceRange : null,
              ),
              const SizedBox(width: 8),
              _chip(
                context,
                _selectedRoomSize ?? 'Room Size',
                selected: _selectedRoomSize != null,
                onTap: _canUseFilters ? _pickRoomSize : null,
              ),
            ],
          ),
        ),
        if (_hasActiveFilters)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear filters'),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final money = _moneyFormatter();

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      if (_error is NoConnectionException) {
        body = Center(child: NoConnectionView(onRetry: _reload));
      } else {
        body = Center(child: Text('Error: ${friendlyError(_error!)}'));
      }
    } else if (_packages.isEmpty) {
      body = const Center(child: Text('No packages available'));
    } else {
      final filtered = _applyFilters(_packages);
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _buildFilterHeader(context, money),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No packages match the selected filters.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (_hasActiveFilters)
                    TextButton(onPressed: _clearFilters, child: const Text('Reset filters')),
                ],
              ),
            )
          else
            ...filtered.map((p) {
              final subtitle = _subtitle(p);
              final rating = p.ratingAvg ?? 4.5;
              final price = money.format(p.price);
              return Container(
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x15000000), blurRadius: 18, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: (p.coverImage != null)
                            ? Image.network(p.coverImage!, fit: BoxFit.cover)
                            : Container(
                                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                child: Icon(
                                  Icons.image_outlined,
                                  size: 48,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.title,
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                              const SizedBox(width: 4),
                              Text(rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          const SizedBox(height: 12),
                          if ((p.hotelStars ?? 0) >= 5) ...[
                            const PremiumChip(),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'From $price per person',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              FilledButton(
                                onPressed: () => _openPackage(p),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text('View Details'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Packages'),
        actions: [
          IconButton(
            onPressed: _canUseFilters ? _openSearch : null,
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: _canUseFilters ? _openFilterPanel : null,
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: body,
    );
  }

  Widget _chip(BuildContext context, String label, {bool selected = false, VoidCallback? onTap}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surfaceContainerHighest.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _PackageSearchDelegate extends SearchDelegate<void> {
  _PackageSearchDelegate({
    required this.packages,
    required this.money,
    required this.onSelect,
  });

  final List<TravelPackage> packages;
  final NumberFormat money;
  final ValueChanged<TravelPackage> onSelect;

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

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    final q = query.trim().toLowerCase();
    final results = q.isEmpty
        ? packages
        : packages.where((pkg) {
            final title = pkg.title.toLowerCase();
            final city = (pkg.cities ?? '').toLowerCase();
            return title.contains(q) || city.contains(q);
          }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('No packages match your search.'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final pkg = results[index];
        final info = [
          if ((pkg.cities ?? '').isNotEmpty) pkg.cities,
          if (pkg.durationDays != null) '${pkg.durationDays} days',
        ].whereType<String>().join(' • ');
        return ListTile(
          title: Text(pkg.title),
          subtitle: info.isEmpty ? null : Text(info),
          trailing: Text(money.format(pkg.price)),
          onTap: () {
            close(context, null);
            onSelect(pkg);
          },
        );
      },
    );
  }
}

class _MonthOption {
  const _MonthOption({required this.key, required this.label});
  final String key;
  final String label;
}

class _PriceBounds {
  const _PriceBounds({required this.min, required this.max});
  final double min;
  final double max;
}
