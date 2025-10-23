import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ConfigService {
  // Match your XAMPP folder name exactly
  static const String _folder = 'rotanatravelapi/api';

  static String get apiBase {
    if (kIsWeb) return 'http://localhost/$_folder';
    if (Platform.isAndroid) return 'http://10.0.2.2/$_folder'; // Android emulator
    if (Platform.isIOS) return 'http://localhost/$_folder'; // iOS simulator
    return 'http://127.0.0.1/$_folder'; // desktop dev
  }

  // WhatsApp Support
  static const String whatsappNumber = '+60123456789';
  static const String whatsappMessage =
      'Hi Rotana, I need help with my booking.';

  // Toyyibpay configuration
  static const bool toyyibpayUseSandbox = true;
  static const String toyyibpayCategoryCode = '1pqcbh5e';
  static const String _toyyibpaySecretKeyDefault =
      '6snobie9-a2hm-vdpp-9xa3-wv69aioimh6d';
  static String get toyyibpaySecretKey => const String.fromEnvironment(
        'TOYYIBPAY_SECRET',
        defaultValue: _toyyibpaySecretKeyDefault,
      );
  static String get toyyibpayBaseUrl =>
      toyyibpayUseSandbox ? 'https://dev.toyyibpay.com' : 'https://toyyibpay.com';
  static String get toyyibpayReturnUrl => const String.fromEnvironment(
        'TOYYIBPAY_RETURN_URL',
        defaultValue: 'https://example.com/payment-return',
      );
  static String get toyyibpayCallbackUrl => const String.fromEnvironment(
        'TOYYIBPAY_CALLBACK_URL',
        defaultValue: 'https://example.com/payment-callback',
      );
}
