import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config_service.dart';
import 'api_client.dart';
import '../utils/json_utils.dart';

class PaymentService {
  Uri _u(String path) => Uri.parse('${ConfigService.apiBase}/$path');

  Future<Map<String, dynamic>> summary(int bookingId) async {
    try {
      final res = await http.get(_u('list_payments.php?booking_id=$bookingId'));
      final m = jsonDecode(res.body);
      if (m['success'] == true) return Map<String, dynamic>.from(m['data']);
      throw Exception(m['error'] ?? 'Failed to load payments');
    } on SocketException catch (_) {
      throw const NoConnectionException();
    }
  }

  Future<int> create({
    required int bookingId,
    required double amount,
    String method = 'TRANSFER',
    String? notes,
  }) async {
    try {
      final res = await http.post(
        _u('create_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'booking_id': bookingId, 'amount': amount, 'method': method, 'notes': notes}),
      );
      final m = jsonDecode(res.body);
      if (m['success'] == true) return readInt(m['data']['id']);
      throw Exception(m['error'] ?? 'Failed to create payment');
    } on SocketException catch (_) {
      throw const NoConnectionException();
    }
  }

  Future<void> markPaid(int paymentId, {String? txRef}) async {
    try {
      final res = await http.post(
        _u('mark_payment_paid.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'payment_id': paymentId, 'transaction_ref': txRef ?? ''}),
      );
      final m = jsonDecode(res.body);
      if (m['success'] != true) throw Exception(m['error'] ?? 'Failed to mark paid');
    } on SocketException catch (_) {
      throw const NoConnectionException();
    }
  }
}
