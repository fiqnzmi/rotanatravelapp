import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/package_detail.dart';
import '../models/package_review.dart';
import '../services/api_client.dart' show NoConnectionException;
import '../utils/error_utils.dart';
import '../widgets/no_connection_view.dart';
import 'booking_wizard_screen.dart';
import 'login_screen.dart';
import '../services/booking_service.dart';
import '../services/package_review_service.dart';

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
  late final TabController _tabs;
  late PackageDetail _detail;
  double? _ratingAvg;
  int? _ratingCount;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _detail = widget.detail;
    _ratingAvg = widget.detail.ratingAvg;
    _ratingCount = widget.detail.ratingCount;
  }

  @override
  void didUpdateWidget(covariant _Body oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail.id != widget.detail.id) {
      _detail = widget.detail;
      _ratingAvg = widget.detail.ratingAvg;
      _ratingCount = widget.detail.ratingCount;
    }
  }

  void _handleReviewSummary(double? avg, int count) {
    if (!mounted) return;
    setState(() {
      _ratingAvg = avg;
      _ratingCount = count;
    });
  }

  Widget _topIconButton({required IconData icon, required VoidCallback onTap}) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      splashRadius: 22,
    );
  }

  Future<void> _sharePackage(PackageDetail detail) async {
    final formatter = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    final summary = '${detail.title} • ${detail.durationDays ?? 0}-day itinerary\n'
        'From ${formatter.format(detail.price)}\n\n'
        '${detail.description}'.trim();
    await Clipboard.setData(ClipboardData(text: summary));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Package details copied. Paste it anywhere to share!')),
    );
  }

  Future<void> _showPackageOptions(PackageDetail detail) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outline.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.copy_all_outlined),
                title: const Text('Copy package description'),
                subtitle: const Text('Great for sharing in chats'),
                onTap: () async {
                  final text = '${detail.title}\n\n${detail.description}'.trim();
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Description copied.')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.confirmation_number_outlined),
                title: const Text('Copy package ID'),
                subtitle: Text('ID #${detail.id}'),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: 'Package #${detail.id}'));
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Package ID copied.')),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final p = _detail;
    final currentAvg = _ratingAvg ?? p.ratingAvg;
    final currentCount = _ratingCount ?? p.ratingCount;
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
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      padding: EdgeInsets.zero,
                      splashRadius: 22,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _topIconButton(icon: Icons.share_outlined, onTap: () => _sharePackage(p)),
                        const SizedBox(width: 4),
                        _topIconButton(icon: Icons.more_vert, onTap: () => _showPackageOptions(p)),
                      ],
                    ),
                  ),
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
                  Text(
                    '${(currentAvg ?? 0).toStringAsFixed(1)} ${currentCount != null ? '($currentCount)' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
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
              height: 420,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _InclusionsTab(items: p.inclusions),
                  _ItineraryTab(items: p.itinerary),
                  _FaqsTab(items: p.faqs),
                  _ReviewsTab(
                    packageId: p.id,
                    ratingAvg: currentAvg,
                    ratingCount: currentCount,
                    onSummaryChanged: _handleReviewSummary,
                  ),
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

  String? _availabilityLabel(int totalRooms) {
    if ((dep.note ?? '').trim().isNotEmpty) return dep.note;
    if (totalRooms <= 0) return null;
    if (totalRooms <= 2) {
      final plural = totalRooms > 1 ? 'rooms' : 'room';
      return 'Only $totalRooms $plural left!';
    }
    return '$totalRooms rooms available';
  }

  Color _availabilityColor(ColorScheme scheme, int totalRooms) {
    if ((dep.note ?? '').trim().isNotEmpty) {
      return scheme.error;
    }
    if (totalRooms <= 2) return scheme.error;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;
    final date = dep.date.isNotEmpty ? DateTime.tryParse(dep.date) : null;
    final totalRooms = dep.tiers.fold<int>(0, (sum, tier) => sum + (tier.roomsLeft ?? 0));
    final availability = _availabilityLabel(totalRooms);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  date == null ? 'TBA' : DateFormat('MMMM d, yyyy').format(date),
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (availability != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _availabilityColor(scheme, totalRooms).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    availability,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _availabilityColor(scheme, totalRooms),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (dep.tiers.isEmpty)
            Text(
              'Room types will be announced soon.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            )
          else
            Column(
              children: dep.tiers.map((tier) {
                final roomsLeft = tier.roomsLeft ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier.name,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (roomsLeft > 0)
                              Text(
                                '$roomsLeft room${roomsLeft > 1 ? 's' : ''} left',
                                style: theme.textTheme.bodySmall?.copyWith(color: muted),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        money.format(tier.price),
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Select your room type on the next step.')),
                );
              },
              child: const Text('Book Now'),
            ),
          ),
        ],
      ),
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

typedef _ReviewSummaryCallback = void Function(double? avg, int count);

class _ReviewsTab extends StatefulWidget {
  final int packageId;
  final double? ratingAvg;
  final int? ratingCount;
  final _ReviewSummaryCallback onSummaryChanged;
  const _ReviewsTab({
    required this.packageId,
    this.ratingAvg,
    this.ratingCount,
    required this.onSummaryChanged,
  });

  @override
  State<_ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<_ReviewsTab> {
  final _reviews = PackageReviewService();
  late Future<PackageReviewsPage> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant _ReviewsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packageId != widget.packageId) {
      _future = _load();
    }
  }

  Future<PackageReviewsPage> _load() async {
    final page = await _reviews.listReviews(widget.packageId);
    if (mounted) {
      widget.onSummaryChanged(page.ratingAvg, page.ratingCount);
    }
    return page;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _handleWriteReview(PackageReviewsPage page) async {
    if (!mounted) return;
    if (!page.eligibility.isLoggedIn) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please log in to leave a review.')));
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    final result = await _openReviewSheet(page);
    if (result == null) return;
    try {
      final response = await _reviews.submitReview(
        packageId: widget.packageId,
        rating: result.rating,
        comment: result.comment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Review saved.')));
      widget.onSummaryChanged(response.ratingAvg, response.ratingCount);
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to submit review: ${friendlyError(e)}')));
    }
  }

  Future<_ReviewFormResult?> _openReviewSheet(PackageReviewsPage page) async {
    final controller = TextEditingController(text: page.myReview?.comment ?? '');
    var currentRating = page.myReview?.rating ?? 5;
    final result = await showModalBottomSheet<_ReviewFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        page.myReview == null ? 'Write a review' : 'Update your review',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < currentRating ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFB800),
                        ),
                        onPressed: () => setSheetState(() => currentRating = index + 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Share your experience with other travelers',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(
                        _ReviewFormResult(
                          rating: currentRating,
                          comment: controller.text.trim(),
                        ),
                      );
                    },
                    child: Text(page.myReview == null ? 'Submit review' : 'Save changes'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    controller.dispose();
    return result;
  }

  Widget _buildSummaryCard(BuildContext context, PackageReviewsPage page) {
    final theme = Theme.of(context);
    final displayAvg = (page.ratingAvg ?? widget.ratingAvg ?? 0).toStringAsFixed(1);
    final count = page.ratingCount;
    final subtitle = count == 1 ? '1 review' : '$count reviews';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.surfaceVariant.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Average rating', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              displayAvg,
              style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Text(subtitle, style: theme.textTheme.bodyMedium),
          ],
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageReviewsPage>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final message = friendlyError(error ?? 'Failed to load reviews');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _reload, child: const Text('Retry')),
              ],
            ),
          );
        }
        final page = snapshot.data!;
        final reviews = page.items;
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Traveler Reviews', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
                ],
              ),
              _buildSummaryCard(context, page),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _handleWriteReview(page),
                  icon: Icon(page.myReview == null ? Icons.rate_review_outlined : Icons.edit_outlined),
                  label: Text(page.myReview == null ? 'Write a review' : 'Update your review'),
                ),
              ),
              if (!page.eligibility.hasBooking)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Booked travelers get a Verified badge on their reviews.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              const SizedBox(height: 12),
              Expanded(
                child: reviews.isEmpty
                    ? const Center(child: Text('No reviews yet.\nBe the first to share your experience!', textAlign: TextAlign.center))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 12),
                        physics: const BouncingScrollPhysics(),
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 18),
                        itemBuilder: (context, index) => _ReviewTile(review: reviews[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewFormResult {
  final int rating;
  final String comment;
  _ReviewFormResult({required this.rating, required this.comment});
}

class _ReviewTile extends StatelessWidget {
  final PackageReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = review.createdAt != null ? DateFormat('MMM d, yyyy').format(review.createdAt!) : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primaryContainer,
          backgroundImage: review.reviewerPhoto != null ? NetworkImage(review.reviewerPhoto!) : null,
          child: review.reviewerPhoto == null
              ? Text(review.reviewerInitials, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      review.reviewerName,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StarDisplay(rating: review.rating),
                ],
              ),
              if (created != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    created,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              if (review.comment != null && review.comment!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(review.comment!, style: theme.textTheme.bodyMedium),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StarDisplay extends StatelessWidget {
  final int rating;
  const _StarDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: const Color(0xFFFFB800),
        ),
      ),
    );
  }
}
