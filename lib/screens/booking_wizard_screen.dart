import 'package:flutter/material.dart';
import '../services/booking_service.dart';
import '../models/traveller.dart';
import 'trips_screen.dart';

class BookingWizardScreen extends StatefulWidget {
  final int packageId;
  final double price;
  final String title;
  const BookingWizardScreen({super.key, required this.packageId, required this.price, required this.title});

  @override
  State<BookingWizardScreen> createState() => _BookingWizardScreenState();
}

class _BookingWizardScreenState extends State<BookingWizardScreen> {
  final _svc = BookingService();
  int adults = 1;
  int children = 0;
  final List<Traveller> travellers = [Traveller(fullName: '')];

  Future<void> _submit() async {
    if (travellers.any((t) => t.fullName.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill traveller names')));
      return;
    }
    final payload = {
      'package_id': widget.packageId,
      'adults': adults,
      'children': children,
      'travellers': travellers.map((t) => t.toJson()).toList(),
    };
    try {
      await _svc.createBooking(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking created!')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TripsScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book: ${widget.title}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Party Size', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _stepper('Adults', adults, onChanged: (v) => setState(() => adults = v))),
              const SizedBox(width: 12),
              Expanded(child: _stepper('Children', children, onChanged: (v) => setState(() => children = v))),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Travellers', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ...travellers.asMap().entries.map((e) => _travellerTile(e.key, e.value)).toList(),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => setState(() => travellers.add(Traveller(fullName: ''))),
            icon: const Icon(Icons.person_add_alt_1), label: const Text('Add Traveller'),
          ),
          const SizedBox(height: 22),
          SizedBox(height: 52, child: FilledButton(onPressed: _submit, child: const Text('Submit Booking'))),
        ],
      ),
    );
  }

  Widget _stepper(String label, int value, {required ValueChanged<int> onChanged}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Row(children: [
        Text(label),
        const Spacer(),
        IconButton(onPressed: () => onChanged((value - 1).clamp(0, 99)), icon: const Icon(Icons.remove_circle_outline)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(onPressed: () => onChanged((value + 1).clamp(0, 99)), icon: const Icon(Icons.add_circle_outline)),
      ]),
    );
  }

  Widget _travellerTile(int i, Traveller t) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Full Name', filled: true),
            onChanged: (v) => t.fullName = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Passport No', filled: true),
            onChanged: (v) => t.passportNo = v,
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', filled: true),
            onChanged: (v) => t.dob = v,
          ),
        ]),
      ),
    );
  }
}
