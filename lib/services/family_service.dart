import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../config_service.dart';
import 'api_client.dart';
import '../utils/json_utils.dart';

class FamilyService {
  Uri _u(String p) => Uri.parse('${ConfigService.apiBase}/$p');

  Future<List<Map<String, dynamic>>> list(int userId) async {
    try {
      final res = await http.get(_u('list_family_members.php?user_id=$userId'));
      final m = jsonDecode(res.body);
      if (m['success'] == true) {
        return (m['data'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      throw Exception(m['error'] ?? 'Failed to load family members');
    } on SocketException catch (_) {
      throw const NoConnectionException();
    }
  }

  Future<int> add({
    required int userId,
    required String fullName,
    String relationship = 'OTHER',
    String? gender,
    String? passportNo,
    String? dob,
    String? passportIssueDate,
    String? passportExpiryDate,
    String? nationality,
    String? phone,
  }) async {
    try {
      final res = await http.post(
        _u('add_family_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'full_name': fullName,
          'relationship': relationship,
          'gender': gender,
          'passport_no': passportNo,
          'dob': dob,
          'passport_issue_date': passportIssueDate,
          'passport_expiry_date': passportExpiryDate,
          'nationality': nationality,
          'phone': phone,
        }),
      );
      final m = jsonDecode(res.body);
      if (m['success'] == true) return readInt(m['data']['id']);
      throw Exception(m['error'] ?? 'Failed to add family member');
    } on SocketException catch (_) {
      throw const NoConnectionException();
    }
  }

  Future<void> update({
    required int id,
    required int userId,
    required String fullName,
    String relationship = 'OTHER',
    String? gender,
    String? passportNo,
    String? dob,
    String? passportIssueDate,
    String? passportExpiryDate,
    String? nationality,
    String? phone,
  }) async {
    try {
      final res = await http.post(
        _u('update_family_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id': id,
          'user_id': userId,
          'full_name': fullName,
          'relationship': relationship,
          'gender': gender,
          'passport_no': passportNo,
          'dob': dob,
          'passport_issue_date': passportIssueDate,
          'passport_expiry_date': passportExpiryDate,
          'nationality': nationality,
          'phone': phone,
        }),
      );
      final m = jsonDecode(res.body);
      if (m['success'] != true) {
        throw Exception(m['error'] ?? 'Failed to update family member');
      }
    } on SocketException catch (_) {
      throw const NoConnectionException();
    }
  }

  Future<void> delete(int id, int userId) async {
    try {
      final res = await http.post(
        _u('delete_family_member.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id, 'user_id': userId}),
      );
      final m = jsonDecode(res.body);
      if (m['success'] != true) throw Exception(m['error'] ?? 'Failed to delete family member');
    } on SocketException catch (_) {
      throw const NoConnectionException();
    }
  }
}
