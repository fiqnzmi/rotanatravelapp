import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config_service.dart';

class ToyyibpayBill {
  ToyyibpayBill({
    required this.paymentUrl,
    required this.paymentId,
    required this.billCode,
    required this.amount,
  });

  final Uri paymentUrl;
  final int paymentId;
  final String billCode;
  final double amount;
}

class ToyyibpayService {
  ToyyibpayService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _endpoint(String path) =>
      Uri.parse('${ConfigService.apiBase}/$path');

  Future<ToyyibpayBill> createBill({
    required int bookingId,
    required double amount,
    String? description,
    String? customerPhone,
  }) async {
    final body = {
      'booking_id': bookingId,
      'amount': amount,
      if (description != null && description.isNotEmpty)
        'bill_description': description,
      if (customerPhone != null && customerPhone.isNotEmpty)
        'customer_phone': customerPhone,
      if (ConfigService.toyyibpayReturnUrl.isNotEmpty)
        'return_url': ConfigService.toyyibpayReturnUrl,
      if (ConfigService.toyyibpayCallbackUrl.isNotEmpty)
        'callback_url': ConfigService.toyyibpayCallbackUrl,
    };

    final res = await _client.post(
      _endpoint('toyyibpay_create_bill.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    final decoded = jsonDecode(res.body);
    if (res.statusCode >= 200 &&
        res.statusCode < 300 &&
        decoded is Map<String, dynamic> &&
        decoded['success'] == true) {
      final data = Map<String, dynamic>.from(decoded['data'] as Map);
      final url = data['payment_url']?.toString();
      final billCode = data['bill_code']?.toString() ?? '';
      final paymentId = int.tryParse(data['payment_id'].toString()) ?? 0;
      final amt = double.tryParse(data['amount'].toString()) ?? amount;
      if (url != null && url.isNotEmpty && paymentId > 0) {
        return ToyyibpayBill(
          paymentUrl: Uri.parse(url),
          paymentId: paymentId,
          billCode: billCode,
          amount: amt,
        );
      }
      throw Exception('Toyyibpay bill response missing payment URL.');
    }

    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'] ?? decoded['message'];
      final debug = decoded['debug'];
      if (debug != null) {
        return Future.error(
          Exception('$error (debug: ${jsonEncode(debug)})'),
        );
      }
      throw Exception(error ?? 'Toyyibpay bill request failed (HTTP ${res.statusCode})');
    }

    throw Exception('Toyyibpay bill request failed (HTTP ${res.statusCode})');
  }
}
