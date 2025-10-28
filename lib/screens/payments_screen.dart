import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config_service.dart';
import '../utils/json_utils.dart';
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
          return;
        }

        bool recorded = false;
        String? recordError;
        if (resultUri.queryParameters['status_id'] == '1') {
          final billCode = resultUri.queryParameters['billcode'] ?? '';
          final transactionId =
              resultUri.queryParameters['transaction_id'] ?? '';
          try {
            final paymentId = await _svc.create(
              bookingId: widget.bookingId,
              amount: amountDue,
              method: 'FPX',
              notes: billCode.isNotEmpty
                  ? 'Toyyibpay bill $billCode'
                  : 'Toyyibpay payment',
            );
            await _svc.markPaid(
              paymentId,
              txRef: transactionId.isNotEmpty ? transactionId : billCode,
            );
            recorded = true;
          } catch (e) {
            recordError = e.toString();
          }
        }

        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentConfirmationScreen(
              resultUri: resultUri,
              amount: amountDue,
              bookingId: widget.bookingId,
              recordedInSystem: recorded,
              recordError: recordError,
            ),
          ),
        );
        await _refresh();
        if (!recorded && recordError != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment succeeded but was not saved automatically: $recordError',
              ),
            ),
          );
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
          final items = (data['items'] as List? ?? [])
              .whereType<Map<String, dynamic>>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final total = readDouble(data['total']);
          final paid = readDouble(data['paid']);
          final balance = readDouble(data['balance']);

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
                ...items.map((p) {
                  final method = p['method']?.toString() ?? 'Payment';
                  final status = p['status']?.toString() ?? '';
                  final notes = p['notes']?.toString() ?? '';
                  final amount = readDouble(p['amount']);
                  final title = status.isNotEmpty ? '$method - $status' : method;
                  return Card(
                    child: ListTile(
                      title: Text(title),
                      subtitle: Text(notes),
                      trailing: Text(
                        money.format(amount),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
