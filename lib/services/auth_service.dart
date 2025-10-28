import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config_service.dart';
import '../utils/json_utils.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _keyUserId = 'user_id';
  static const _keyName = 'user_name';
  static const _keyEmail = 'user_email';
  static const _keyUsername = 'user_username';
  static const _keyPhone = 'user_phone';

  Uri _u(String path) => Uri.parse('${ConfigService.apiBase}/$path');

  Map<String, dynamic> _decodeResponse(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) {
      throw Exception('Empty response from server (status: ${res.statusCode})');
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      throw Exception('Unexpected response type from server');
    } on FormatException {
      throw Exception('Invalid response from server: $body');
    }
  }

  String _resolveDisplayName(
    Map<String, dynamic> user, {
    String fallback = '',
  }) {
    String pick(dynamic value) => value is String ? value.trim() : (value ?? '').toString().trim();
    final name = pick(user['name']);
    if (name.isNotEmpty) return name;
    final username = pick(user['username']);
    if (username.isNotEmpty) return username;
    final email = pick(user['email']);
    if (email.isNotEmpty) return email;
    final trimmedFallback = fallback.trim();
    return trimmedFallback.isNotEmpty ? trimmedFallback : '';
  }

  Future<bool> isLoggedIn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(_keyUserId);
  }

  Future<int?> getUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_keyUserId);
  }

  Future<Map<String, dynamic>?> currentUser() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getInt(_keyUserId);
    if (id == null) return null;
    return {
      'id': id,
      'name': sp.getString(_keyName),
      'username': sp.getString(_keyUsername),
      'email': sp.getString(_keyEmail),
      'phone': sp.getString(_keyPhone),
    };
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyUserId);
    await sp.remove(_keyName);
    await sp.remove(_keyEmail);
    await sp.remove(_keyUsername);
    await sp.remove(_keyPhone);
  }

  Future<void> register({required String username, required String email, required String password}) async {
    final res = await http.post(
      _u('register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    final m = _decodeResponse(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
      final u = Map<String, dynamic>.from(m['data']['user'] as Map);
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_keyUserId, readInt(u['id']));
      await sp.setString(
        _keyName,
        _resolveDisplayName(u, fallback: username),
      );
      await sp.setString(
        _keyUsername,
        (u['username'] as String?)?.trim().isNotEmpty == true ? u['username'].toString().trim() : username,
      );
      await sp.setString(
        _keyEmail,
        (u['email'] as String?)?.trim().isNotEmpty == true ? u['email'].toString().trim() : email,
      );
      final phone = (u['phone'] as String?)?.trim();
      if (phone != null && phone.isNotEmpty) {
        await sp.setString(_keyPhone, phone);
      } else {
        await sp.remove(_keyPhone);
      }
      return;
    }
    throw Exception(m['error'] ?? 'Registration failed');
  }

  Future<void> login({required String identifier, required String password}) async {
    final res = await http.post(
      _u('login.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );
    final m = _decodeResponse(res);
    if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
      final u = Map<String, dynamic>.from(m['data']['user'] as Map);
      final sp = await SharedPreferences.getInstance();
      final existingName = sp.getString(_keyName) ?? '';
      await sp.setInt(_keyUserId, readInt(u['id']));
      await sp.setString(
        _keyName,
        _resolveDisplayName(u, fallback: existingName),
      );
      final username = (u['username'] as String?)?.trim() ?? '';
      final email = (u['email'] as String?)?.trim() ?? '';
      await sp.setString(
        _keyUsername,
        username.isNotEmpty ? username : sp.getString(_keyUsername) ?? '',
      );
      await sp.setString(
        _keyEmail,
        email.isNotEmpty ? email : sp.getString(_keyEmail) ?? '',
      );
      final phone = (u['phone'] as String?)?.trim() ?? '';
      if (phone.isNotEmpty) {
        await sp.setString(_keyPhone, phone);
      } else {
        await sp.remove(_keyPhone);
      }
      return;
    }
    throw Exception(m['error'] ?? 'Login failed');
  }

  // RESET PASSWORD FLOW
  Future<Map<String, dynamic>> requestPasswordReset(String identifier) async {
    final res = await http.post(
      _u('request_password_reset.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier}),
    );
    final m = _decodeResponse(res);
    if (m['success'] == true) return Map<String, dynamic>.from(m['data']);
    throw Exception(m['error'] ?? 'Failed to request reset');
  }

  Future<void> completePasswordReset({
    required String token,
    required String code,
    required String newPassword,
  }) async {
    final res = await http.post(
      _u('reset_password.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'code': code, 'new_password': newPassword}),
    );
    final m = _decodeResponse(res);
    if (m['success'] != true) throw Exception(m['error'] ?? 'Failed to reset password');
  }

  Future<void> updateStoredProfile({
    String? name,
    String? username,
    String? email,
    String? phone,
  }) async {
    final sp = await SharedPreferences.getInstance();
    if (name != null) await sp.setString(_keyName, name);
    if (username != null) await sp.setString(_keyUsername, username);
    if (email != null) await sp.setString(_keyEmail, email);
    if (phone != null) {
      if (phone.isNotEmpty) {
        await sp.setString(_keyPhone, phone);
      } else {
        await sp.remove(_keyPhone);
      }
    }
  }
}
