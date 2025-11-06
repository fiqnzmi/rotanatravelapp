import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

class PrivacySettings {
  final bool twoFactor;
  final bool biometricLogin;
  final bool trustedDevices;
  final bool personalizedRecommendations;

  const PrivacySettings({
    required this.twoFactor,
    required this.biometricLogin,
    required this.trustedDevices,
    required this.personalizedRecommendations,
  });

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    bool readBool(String key, bool fallback) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final lower = value.toLowerCase();
        if (['1', 'true', 'yes', 'y', 'on'].contains(lower)) return true;
        if (['0', 'false', 'no', 'n', 'off'].contains(lower)) return false;
      }
      return fallback;
    }

    return PrivacySettings(
      twoFactor: readBool('two_factor', false),
      biometricLogin: readBool('biometric_login', false),
      trustedDevices: readBool('trusted_devices', true),
      personalizedRecommendations: readBool('personalized_recommendations', true),
    );
  }

  Map<String, dynamic> toJson() => {
        'two_factor': twoFactor,
        'biometric_login': biometricLogin,
        'trusted_devices': trustedDevices,
        'personalized_recommendations': personalizedRecommendations,
      };
}

class PrivacyService {
  final _api = ApiClient();

  Future<PrivacySettings> fetch(int userId) async {
    final data = await _api.post('get_privacy_settings.php', {'user_id': userId});
    if (data is Map<String, dynamic>) {
      return PrivacySettings.fromJson(data);
    }
    return PrivacySettings.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<PrivacySettings> update(
    int userId, {
    bool? twoFactor,
    bool? biometricLogin,
    bool? trustedDevices,
    bool? personalizedRecommendations,
  }) async {
    final payload = <String, dynamic>{
      'user_id': userId,
    };
    if (twoFactor != null) payload['two_factor'] = twoFactor;
    if (biometricLogin != null) payload['biometric_login'] = biometricLogin;
    if (trustedDevices != null) payload['trusted_devices'] = trustedDevices;
    if (personalizedRecommendations != null) {
      payload['personalized_recommendations'] = personalizedRecommendations;
    }

    final data = await _api.post('update_privacy_settings.php', payload);
    return PrivacySettings.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.post('change_password.php', {
      'user_id': userId,
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<String> downloadUserData(int userId) async {
    final data =
        await _api.post('download_user_data.php', {'user_id': userId});
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/rotana_user_data_${DateTime.now().millisecondsSinceEpoch}.json');
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(data));
    return file.path;
  }

  Future<void> deleteAccount({required int userId, required String password}) async {
    await _api.post('delete_account.php', {
      'user_id': userId,
      'password': password,
    });
  }
}
