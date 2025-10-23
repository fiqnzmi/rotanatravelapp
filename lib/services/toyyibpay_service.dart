import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config_service.dart';

class ToyyibpayService {
  ToyyibpayService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri get _createBillUri =>
      Uri.parse('${ConfigService.toyyibpayBaseUrl}/index.php/api/createBill');

  Future<Uri> createBill({
    required double amount,
    required String customerName,
    required String customerEmail,
    String? customerPhone,
    String? reference,
    String? description,
  }) async {
    final sen = (amount * 100).round();
    if (sen <= 0) {
      throw ArgumentError('Amount must be greater than zero.');
    }

    final phone = _normalisePhone(customerPhone);
    final body = <String, String>{
      'userSecretKey': ConfigService.toyyibpaySecretKey,
      'categoryCode': ConfigService.toyyibpayCategoryCode,
      'billName': reference?.isNotEmpty == true
          ? 'Booking $reference'
          : 'Rotana Travel Booking',
      'billDescription': description?.isNotEmpty == true
          ? description!
          : 'Booking payment',
      'billAmount': sen.toString(),
      'billReturnUrl': ConfigService.toyyibpayReturnUrl,
      'billCallbackUrl': ConfigService.toyyibpayCallbackUrl,
      'billTo': customerName,
      'billEmail': customerEmail,
      'billPhone': phone,
      'billPayorInfo': '1',
      'billPaymentChannel': '2',
      'billChargeToCustomer': '1',
      'billPriceSetting': '1',
      if (reference != null && reference.isNotEmpty)
        'billExternalReferenceNo': reference,
    };

    final res = await _client.post(
      _createBillUri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception('Toyyibpay error (HTTP ${res.statusCode})');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        final link = first['BillpaymentLink'] ??
            first['billpaymentLink'] ??
            first['Url'];
        if (link is String && link.isNotEmpty) {
          return Uri.parse(link);
        }
        final code = first['BillCode'] ?? first['billCode'];
        if (code is String && code.isNotEmpty) {
          return Uri.parse('${ConfigService.toyyibpayBaseUrl}/$code');
        }
        if (first['msg'] is String) {
          throw Exception(first['msg']);
        }
      }
    } else if (decoded is Map<String, dynamic>) {
      final message = decoded['msg'] ?? decoded['message'] ?? decoded['error'];
      if (message is String) {
        throw Exception(message);
      }
    }
    throw Exception('Failed to create Toyyibpay bill: ${res.body}');
  }

  String _normalisePhone(String? phone) {
    final digits = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isNotEmpty) return digits;
    // Toyyibpay rejects empty phone numbers; fall back to a placeholder.
    return '0000000000';
  }
}
