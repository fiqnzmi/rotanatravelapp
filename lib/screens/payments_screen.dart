import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config_service.dart';
import '../services/payment_service.dart';
import '../services/toyyibpay_service.dart';
import '../services/auth_service.dart';
import 'payment_confirmation_screen.dart';
import 'toyyibpay_checkout_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _svc = PaymentService();
  final _gateway = ToyyibpayService();
  final _auth = AuthService.instance;
  final NumberFormat money =
      NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 2);

  late Future<Map<String, dynamic>> _future;
  final TextEditingController amountC = TextEditingController();
  final TextEditingController notesC = TextEditingController();
  bool _gatewayLoading = false;

  @override
  void initState() {
    super.initState();
    _future = _svc.summary(widget.bookingId);
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _future = _svc.summary(widget.bookingId);
    });
  }

  Future<void> _addPayment() async {
    final amt = double.tryParse(amountC.text) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }
    await _svc.create(
      bookingId: widget.bookingId,
      amount: amt,
      notes: notesC.text,
    );
    if (!mounted) return;
    await _refresh();
    amountC.clear();
    notesC.clear();
  }

  Future<void> _payWithToyyibpay(
    double amountDue,
    Map<String, dynamic> summary,
  ) async {
    if (amountDue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No outstanding balance to pay.')),
      );
      return;
    }
    if (_gatewayLoading) return;

    if (mounted) setState(() => _gatewayLoading = true);
    try {
      final user = await _auth.currentUser() ?? const <String, dynamic>{};
      final name = (user['name'] as String?)?.trim();
      final email = (user['email'] as String?)?.trim();
      if (name == null || name.isEmpty || email == null || email.isEmpty) {
        throw Exception(
          'Please ensure your profile has a name and email before paying online.',
        );
      }

      final description =
          (summary['package_title'] as String?)?.trim().isNotEmpty == true
              ? summary['package_title'] as String
              : 'Rotana Travel Booking';
      final phone = _pickPhone(summary, user);
      final uri = await _gateway.createBill(
        amount: amountDue,
        customerName: name,
        customerEmail: email,
        customerPhone: phone,
        reference: 'BOOK-${widget.bookingId}',
        description: description,
      );

      if (!mounted) return;
      final resultUri = await Navigator.of(context).push<Uri?>(
        MaterialPageRoute(
          builder: (_) => ToyyibpayCheckoutScreen(
            paymentUrl: uri,
            returnUrl: ConfigService.toyyibpayReturnUrl,
            title: 'Toyyibpay',
          ),
        ),
      );

      if (!mounted) return;
      if (resultUri == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toyyibpay window closed.')),
        );
      } else {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentConfirmationScreen(
              resultUri: resultUri,
              amount: amountDue,
              bookingId: widget.bookingId,
            ),
          ),
        );
        await _refresh();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _gatewayLoading = false);
    }
  }

  String? _pickPhone(Map<String, dynamic> summary, Map<String, dynamic> user) {
    final candidates = <String?>[
      (user['phone'] as String?)?.trim(),
      (user['mobile'] as String?)?.trim(),
      (summary['customer_phone'] as String?)?.trim(),
      (summary['phone'] as String?)?.trim(),
      (summary['contact'] as String?)?.trim(),
      summary['customer'] is Map<String, dynamic>
          ? (summary['customer']['phone'] as String?)?.trim()
          : null,
    ];

    for (final c in candidates) {
      if (c != null && c.isNotEmpty) {
        return c;
      }
    }
    return null;
  }

  @override
  void dispose() {
    amountC.dispose();
    notesC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            onPressed: () {
              _refresh();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? const <String, dynamic>{};
          final items =
              (data['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          final total = (data['total'] as num?)?.toDouble() ?? 0;
          final paid = (data['paid'] as num?)?.toDouble() ?? 0;
          final balance = (data['balance'] as num?)?.toDouble() ?? 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Package Total'),
                  trailing: Text(money.format(total)),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Paid'),
                  trailing: Text(money.format(paid)),
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Balance'),
                  trailing: Text(money.format(balance)),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pay Online',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed:
                      _gatewayLoading ? null : () => _payWithToyyibpay(balance, data),
                  icon: _gatewayLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    balance > 0
                        ? 'Pay RM ${balance.toStringAsFixed(2)} with Toyyibpay'
                        : 'Pay with Toyyibpay',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payments',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No payments recorded yet.'),
                  ),
                )
              else
                ...items.map(
                  (p) => Card(
                    child: ListTile(
                      title: Text('${p['method']} • ${p['status']}'),
                      subtitle: Text(p['notes'] ?? ''),
                      trailing: Text(
                        money.format((p['amount'] as num?)?.toDouble() ?? 0),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const Text(
                'Add Payment (Manual Transfer)',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountC,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (MYR)',
                  filled: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesC,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  filled: true,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _addPayment,
                  child: const Text('Record Payment'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
