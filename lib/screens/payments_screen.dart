import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';

class PaymentsScreen extends StatefulWidget {
  final int bookingId;
  const PaymentsScreen({super.key, required this.bookingId});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final _svc = PaymentService();
  late Future<Map<String, dynamic>> _future;
  final money = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 2);

  final amountC = TextEditingController();
  final notesC = TextEditingController();

  @override
  void initState() { super.initState(); _future = _svc.summary(widget.bookingId); }

  Future<void> _addPayment() async {
    final amt = double.tryParse(amountC.text) ?? 0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount'))); return;
    }
    await _svc.create(bookingId: widget.bookingId, amount: amt, notes: notesC.text);
    setState(() => _future = _svc.summary(widget.bookingId));
    amountC.clear(); notesC.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments')),
      body: FutureBuilder(
        future: _future,
        builder: (_, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final m = snap.data as Map<String, dynamic>;
          final items = (m['items'] as List).cast<Map<String, dynamic>>();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16,16,16,24),
            children: [
              Card(child: ListTile(title: const Text('Package Total'), trailing: Text(money.format(m['total'])))),
              Card(child: ListTile(title: const Text('Paid'), trailing: Text(money.format(m['paid'])))),
              Card(child: ListTile(title: const Text('Balance'), trailing: Text(money.format(m['balance'])))),
              const SizedBox(height: 16),
              const Text('Payments', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              ...items.map((p) => Card(
                child: ListTile(
                  title: Text('${p['method']} • ${p['status']}'),
                  subtitle: Text(p['notes'] ?? ''),
                  trailing: Text(money.format(p['amount'])),
                ),
              )),
              const SizedBox(height: 16),
              const Text('Add Payment (Manual Transfer)', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              TextField(controller: amountC, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount (MYR)', filled: true)),
              const SizedBox(height: 8),
              TextField(controller: notesC, decoration: const InputDecoration(labelText: 'Notes (optional)', filled: true)),
              const SizedBox(height: 10),
              SizedBox(height: 48, child: FilledButton(onPressed: _addPayment, child: const Text('Record Payment'))),
            ],
          );
        },
      ),
    );
  }
}
