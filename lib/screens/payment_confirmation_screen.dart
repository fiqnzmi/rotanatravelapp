import 'package:flutter/material.dart';

class PaymentConfirmationScreen extends StatelessWidget {
  const PaymentConfirmationScreen({
    super.key,
    required this.resultUri,
    required this.amount,
    required this.bookingId,
    this.recordedInSystem = false,
    this.recordError,
  });

  final Uri resultUri;
  final double amount;
  final int bookingId;
  final bool recordedInSystem;
  final String? recordError;

  bool get _isSuccess => resultUri.queryParameters['status_id'] == '1';

  @override
  Widget build(BuildContext context) {
    final status = resultUri.queryParameters['status_id'] ?? '-';
    final message = resultUri.queryParameters['msg'] ?? '';
    final billCode = resultUri.queryParameters['billcode'] ?? '-';
    final transactionId = resultUri.queryParameters['transaction_id'] ?? '-';
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = scheme.onSurfaceVariant;

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
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            if (_isSuccess)
              _recordingStatus(context),
            if (_isSuccess) const SizedBox(height: 24),
            _infoTile(context, 'Booking ID', '#$bookingId'),
            _infoTile(context, 'Amount', 'RM ${amount.toStringAsFixed(2)}'),
            _infoTile(context, 'Toyyibpay Bill', billCode),
            _infoTile(context, 'Transaction ID', transactionId),
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

  Widget _recordingStatus(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (recordedInSystem) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: scheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment recorded in Rotana system.',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    if (recordError != null && recordError!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: scheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Payment succeeded at Toyyibpay but could not be saved automatically.\n$recordError',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _infoTile(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
