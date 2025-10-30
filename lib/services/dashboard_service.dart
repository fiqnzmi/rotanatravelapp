import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../config_service.dart';
import 'api_client.dart';

class DashboardService {
  final _api = ApiClient();

  Future<Map<String, dynamic>> bookingSummary(int bookingId, int userId) async {
    return await _api.get('dashboard_booking_summary.php',
        query: {'booking_id': '$bookingId', 'user_id': '$userId'});
  }

  Future<List<Map<String, dynamic>>> listDocuments(int bookingId, int userId) async {
    final data = await _api.get('list_documents.php',
        query: {'booking_id': '$bookingId', 'user_id': '$userId'});
    return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<List<Map<String, dynamic>>> listNotifications(int userId) async {
    final data = await _api.get('list_notifications.php', query: {'user_id': '$userId'});
    return (data as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> profileOverview(int userId) async {
    return await _api.get('profile_overview.php', query: {'user_id': '$userId'});
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> payload) async {
    final data = await _api.post('update_profile.php', payload);
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<Map<String, dynamic>> uploadProfilePhoto({
    required int userId,
    required File file,
  }) async {
    final uri = Uri.parse('${ConfigService.apiBase}/upload_profile_photo.php');
    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = '$userId';

    final mimeType = _detectMimeType(file.path);
    request.files.add(
      await http.MultipartFile.fromPath(
        'photo',
        file.path,
        filename: p.basename(file.path),
        contentType: mimeType,
      ),
    );

    final response = await request.send();
    final text = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload failed (HTTP ${response.statusCode}): $text');
    }

    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      if (decoded['success'] == true) {
        final data = decoded['data'];
        if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
        return <String, dynamic>{};
      }
      throw Exception(decoded['error'] ?? 'Failed to upload profile photo');
    }

    throw Exception('Unexpected response from server.');
  }

  MediaType _detectMimeType(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return MediaType('image', 'jpeg');
      case '.png':
        return MediaType('image', 'png');
      case '.heic':
        return MediaType('image', 'heic');
      case '.webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
