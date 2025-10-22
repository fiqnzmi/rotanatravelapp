import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../models/booking.dart';
import '../config_service.dart';
import 'trips_screen.dart';
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
  String? _userName;
  List<Booking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await AuthService.instance.currentUser();
      final bookings = await _safeBookings();
      setState(() {
        _userName = user?['name'] as String?;
        _bookings = bookings;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<List<Booking>> _safeBookings() async {
    try {
      return await _bookingSvc.myBookings();
    } catch (_) {
      return [];
    }
  }

  Booking? get _nextTrip {
    final confirmed = _bookings.where((b) => b.status == 'CONFIRMED').toList();
    if (confirmed.isEmpty) return null;
    confirmed.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return confirmed.first;
  }

  double get _progress => 0.35; // placeholder
  String? get _daysToGo => _nextTrip == null ? null : '30 days to go';

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

  Widget _statusChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFE9EDF2), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _quickAction(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
              color: const Color(0xFFE9EDF2), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final helloName = _userName?.isNotEmpty == true ? _userName! : 'Guest';
    final nextTrip = _nextTrip;

    return Scaffold(
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
                        // <-- ACCOUNT SHORTCUT BUTTON -->
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
                                    builder: (_) => const ProfileScreen()),
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
                        color: Theme.of(context).colorScheme.surface,
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('Experience the spiritual journey of a lifetime',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.black54)),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(16)),
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text('Next Trip',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700)),
                                      const Spacer(),
                                      if (_daysToGo != null)
                                        Text(_daysToGo!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                    color: Colors.black54)),
                                    ]),
                                    const SizedBox(height: 8),
                                    Text(nextTrip?.title ?? '—',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 12),
                                    Wrap(spacing: 10, runSpacing: 8, children: [
                                      _statusChip(
                                          Icons.verified_outlined, 'Paid'),
                                      _statusChip(
                                          Icons.insert_drive_file_outlined,
                                          'Docs Missing'),
                                      _statusChip(
                                          Icons
                                              .account_balance_wallet_outlined,
                                          'Balance Due'),
                                    ]),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                          value: _progress, minHeight: 10),
                                    ),
                                  ]),
                            ),
                          ]),
                    ),
                    const SizedBox(height: 18),
                    Text('Quick Actions',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _quickAction(
                              icon: Icons.cloud_upload_outlined,
                              label: 'Upload Documents',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Open a booking → Documents')));
                              }),
                          _quickAction(
                              icon: Icons.payments_outlined,
                              label: 'Pay Balance',
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Open a booking → Payments')));
                              }),
                          _quickAction(
                              icon: Icons.flight_takeoff_outlined,
                              label: 'My Trips',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const TripsScreen()))),
                          _quickAction(
                              icon: Icons.headset_mic_outlined,
                              label: 'Support',
                              onTap: _openWhatsApp),
                        ]),
                    const SizedBox(height: 22),
                    Row(children: [
                      Text('Special Offers',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      TextButton(onPressed: () {}, child: const Text('View All')),
                    ]),
                    const SizedBox(height: 8),
                    _offerCard(context,
                        title: 'Umrah Package Promo',
                        subtitle: 'Early Bird — save up to RM 2,000',
                        price: 4990,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PackageDetailScreen(packageId: 1)))),
                    const SizedBox(height: 12),
                    _offerCard(context,
                        title: 'Hajj Premium',
                        subtitle: 'Limited seats — new season',
                        price: 22990,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PackageDetailScreen(packageId: 1)))),
                  ],
                ),
              ),
      ),
    );
  }

  void _showAuthShortcutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_circle_outlined, size: 40),
              const SizedBox(height: 8),
              Text('Welcome to Rotana',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Log in to manage trips, payments and documents.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Log In
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Log In'),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          onAuthSuccess: () =>
                              Navigator.popUntil(context, (r) => r.isFirst),
                        ),
                      ),
                    );
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
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue as Guest'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _offerCard(BuildContext context,
      {required String title,
      required String subtitle,
      required num price,
      required VoidCallback onTap}) {
    final formatter =
        NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
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
                  decoration: const BoxDecoration(
                    color: Color(0xFFE9EDF2),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        bottomLeft: Radius.circular(18)),
                  ),
                  child: const Icon(Icons.landscape_outlined, size: 40),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.black54)),
                        const Spacer(),
                        Text('From ${formatter.format(price)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                      ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}