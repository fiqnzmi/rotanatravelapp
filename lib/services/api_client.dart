// lib/services/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config_service.dart';

class ApiClient {
  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${ConfigService.apiBase}/$path')
          .replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    try {
      final res = await http
          .get(_u(path, query))
          .timeout(const Duration(seconds: 20));

      final body = res.body.isEmpty ? '{}' : res.body;
      final m = jsonDecode(body) as Map<String, dynamic>;

      if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
        return m['data'];
      }
      throw Exception(m['error'] ?? 'HTTP ${res.statusCode}');
    } on SocketException catch (_) {
      throw Exception('Tidak dapat sambung ke server (${ConfigService.apiBase}). '
          'Pastikan XAMPP Apache/MySQL berjalan dan URL betul.');
    } on FormatException catch (_) {
      throw Exception('Respons bukan JSON yang sah dari server.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await http
          .post(
            _u(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      final text = res.body.isEmpty ? '{}' : res.body;
      final m = jsonDecode(text) as Map<String, dynamic>;

      if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
        return m['data'];
      }
      throw Exception(m['error'] ?? 'HTTP ${res.statusCode}');
    } on SocketException catch (_) {
      throw Exception('Tidak dapat sambung ke server (${ConfigService.apiBase}). '
          'Gunakan 10.0.2.2 pada emulator / IP LAN pada telefon.');
    } on FormatException catch (_) {
      throw Exception('Respons bukan JSON yang sah dari server.');
    }
  }
}
