import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ConfigService {
  // Match your XAMPP folder name exactly
  static const String _folder = 'rotanatravelapi/api';
  static const bool _useRemoteServer = true;
  static const String _remoteBase =
      'https://ruangprojek.com/rotanatravel/rotanatravelapi/api';
  static const String _remoteAssetBase =
      'https://ruangprojek.com/rotanatravel';

  static String get apiBase {
    if (_useRemoteServer) return _remoteBase;
    if (kIsWeb) return 'http://localhost/$_folder';
    if (Platform.isAndroid) return 'http://10.0.2.2/$_folder'; // Android emulator
    if (Platform.isIOS) return 'http://localhost/$_folder'; // iOS simulator
    return 'http://127.0.0.1/$_folder'; // desktop dev
  }

  static String get assetBase {
    if (_useRemoteServer) return _remoteAssetBase;
    final base = apiBase;
    return _stripApiSuffix(base);
  }

  static String? resolveAssetUrl(String? path) {
    if (path == null) return null;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final normalized = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
    final base = assetBase.endsWith('/')
        ? assetBase
        : '$assetBase/';
    return '$base$normalized';
  }

  static String _stripApiSuffix(String value) {
    if (value.endsWith('/api')) return value.substring(0, value.length - 4);
    if (value.endsWith('/api/')) return value.substring(0, value.length - 5);
    return value;
  }

  // WhatsApp Support
  static const String whatsappNumber = '+601137136259';
  static const String whatsappMessage =
      'Hi Admin, I need Support team.';

  // Toyyibpay configuration
  static const bool toyyibpayUseSandbox = true;
  static const String toyyibpayCategoryCode = 'b53b766t';
  static const String _toyyibpaySecretKeyDefault =
      'iyme8tsr-a0ry-4xzk-k91s-mn9arik030pa';
  static String get toyyibpaySecretKey => const String.fromEnvironment(
        'TOYYIBPAY_SECRET',
        defaultValue: _toyyibpaySecretKeyDefault,
      );
  static String get toyyibpayHost => const String.fromEnvironment(
        'TOYYIBPAY_HOST',
        defaultValue:
            toyyibpayUseSandbox ? 'dev.toyyibpay.com' : 'toyyibpay.com',
      );
  static String get toyyibpayBaseUrl => 'https://$toyyibpayHost';
  static String get toyyibpayReturnUrl => const String.fromEnvironment(
        'TOYYIBPAY_RETURN_URL',
        defaultValue: 'https://example.com/payment-return',
      );
  static String get toyyibpayCallbackUrl => const String.fromEnvironment(
        'TOYYIBPAY_CALLBACK_URL',
        defaultValue: 'https://example.com/payment-callback',
      );
}
