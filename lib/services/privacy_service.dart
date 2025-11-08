import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'api_client.dart';

class PrivacyService {
  final _api = ApiClient();

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
