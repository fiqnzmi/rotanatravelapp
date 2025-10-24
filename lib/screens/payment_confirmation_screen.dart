import 'package:flutter/material.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  const PaymentConfirmationScreen({
    super.key,
    required this.resultUri,
    required this.amount,
    required this.bookingId,
  });

  final Uri resultUri;
  final double amount;
  final int bookingId;

  bool get _isSuccess => resultUri.queryParameters['status_id'] == '1';

  @override
  Widget build(BuildContext context) {
    final status = resultUri.queryParameters['status_id'] ?? '-';
    final message = resultUri.queryParameters['msg'] ?? '';
    final billCode = resultUri.queryParameters['billcode'] ?? '-';
    final transactionId = resultUri.queryParameters['transaction_id'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Icon(
              _isSuccess ? Icons.check_circle : Icons.error_outline,
              size: 82,
              color: _isSuccess ? Colors.green : Colors.redAccent,
            ),
            const SizedBox(height: 24),
            Text(
              _isSuccess ? 'Payment Successful' : 'Payment Status: $status',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            _infoTile('Booking ID', '#$bookingId'),
            _infoTile('Amount', 'RM ${amount.toStringAsFixed(2)}'),
            _infoTile('Toyyibpay Bill', billCode),
            _infoTile('Transaction ID', transactionId),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(_isSuccess ? 'Done' : 'Back to Payments'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
