import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config_service.dart';

class ApiClient {
  Uri _u(String path, [Map<String, String>? query]) =>
      Uri.parse('${ConfigService.apiBase}/$path').replace(queryParameters: query);

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final res = await http.get(_u(path, query));
    final m = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
      return m['data'];
    }
    throw Exception(m['error'] ?? 'Request failed');
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(_u(path),
        headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    final m = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300 && m['success'] == true) {
      return m['data'];
    }
    throw Exception(m['error'] ?? 'Request failed');
  }
}
