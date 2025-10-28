import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ConfigService {
  // Local development folder (e.g. htdocs/rotanatravelapi/api)
  static const String _localFolder = 'rotanatravelapi/api';

  static const bool _useRemoteServerDefault = true;
  static const String _remoteRootDefault = 'https://ruangprojek.com/rotanatravel';
  static const String _remoteApiPathDefault = 'rotanatravelapi/api';
  static const String _remoteAssetBaseDefault = 'https://ruangprojek.com/rotanatravel';

  static bool get _useRemoteServer => const bool.fromEnvironment(
        'USE_REMOTE_SERVER',
        defaultValue: _useRemoteServerDefault,
      );

  static String get _remoteRoot => const String.fromEnvironment(
        'REMOTE_ROOT',
        defaultValue: _remoteRootDefault,
      );

  static String get _remoteApiPath => const String.fromEnvironment(
        'REMOTE_API_PATH',
        defaultValue: _remoteApiPathDefault,
      );

  static String get _remoteAssetBase => const String.fromEnvironment(
        'REMOTE_ASSET_BASE',
        defaultValue: _remoteAssetBaseDefault,
      );

  static String get _remoteBase => _joinUrl(_remoteRoot, _remoteApiPath);

  static String get apiBase {
    if (_useRemoteServer) return _remoteBase;
    if (kIsWeb) return 'http://localhost/${_localFolder}';
    if (Platform.isAndroid) {
      // Android emulator points to host machine via 10.0.2.2
      return 'http://10.0.2.2/${_localFolder}';
    }
    if (Platform.isIOS) return 'http://localhost/${_localFolder}';
    return 'http://127.0.0.1/${_localFolder}';
  }

  static String get assetBase {
    if (_useRemoteServer) return _remoteAssetBase;
    final base = apiBase;
    return _stripApiSuffix(base);
  }

  static String? resolveAssetUrl(String? path) {
    if (path == null) return null;
    var trimmed = path.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }

    if (lower.startsWith('file://')) {
      // Handle paths like file:///uploads/xyz.jpg from the API by stripping the scheme.
      trimmed = trimmed.substring(trimmed.indexOf('://') + 3);
      while (trimmed.startsWith('/')) {
        trimmed = trimmed.substring(1);
      }
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

  static String _joinUrl(String base, String path) {
    final normalizedBase =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final normalizedPath =
        path.startsWith('/') ? path.substring(1) : path;
    if (normalizedPath.isEmpty) {
      return normalizedBase;
    }
    return '$normalizedBase/$normalizedPath';
  }

  // WhatsApp Support
  static const String whatsappNumber = '+601137136259';
  static const String whatsappMessage =
      'Hi Admin, I need Support team.';

  // Toyyibpay configuration
  static const bool toyyibpayUseSandbox = false;
  static const String toyyibpayCategoryCode = '1pqcbh5e';
  static const String _toyyibpaySecretKeyDefault =
      '6snobie9-a2hm-vdpp-9xa3-wv69aioimh6d';
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
