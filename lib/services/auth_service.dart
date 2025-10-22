import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _keyUserId = 'user_id';
  static const _keyName = 'user_name';
  static const _keyEmail = 'user_email';
  static const _keyUsername = 'user_username';

  Uri _u(String path) => Uri.parse('${ConfigService.apiBase}/$path');

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
    };
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyUserId);
    await sp.remove(_keyName);
    await sp.remove(_keyEmail);
    await sp.remove(_keyUsername);
  }

  Future<void> register({required String username, required String email, required String password}) async {
    final res = await http.post(
      _u('register.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    final m = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
      final u = m['data']['user'];
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_keyUserId, u['id']);
      await sp.setString(_keyName, u['name'] ?? username);
      await sp.setString(_keyUsername, u['username'] ?? username);
      await sp.setString(_keyEmail, u['email'] ?? email);
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
    final m = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
      final u = m['data']['user'];
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_keyUserId, u['id']);
      await sp.setString(_keyName, u['name'] ?? '');
      await sp.setString(_keyUsername, u['username'] ?? '');
      await sp.setString(_keyEmail, u['email'] ?? '');
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
    final m = jsonDecode(res.body);
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
    final m = jsonDecode(res.body);
    if (m['success'] != true) throw Exception(m['error'] ?? 'Failed to reset password');
  }
}
