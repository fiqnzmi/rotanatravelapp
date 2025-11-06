import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config_service.dart';
import 'api_client.dart';

class DocumentService {
  Uri _u(String p) => Uri.parse('${ConfigService.apiBase}/$p');

  Future<Map<String, dynamic>> upload({
    required int bookingId,
    required int userId,
    required String docType,
    required File file,
    String? label,
  }) async {
    try {
      final req = http.MultipartRequest('POST', _u('upload_document.php'))
        ..fields['booking_id'] = '$bookingId'
        ..fields['user_id'] = '$userId'
        ..fields['doc_type'] = docType;
      if (label != null) req.fields['label'] = label;
      req.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: _detectMimeType(file.path),
      ));

      final streamed = await req.send();
      final res = await http.Response.fromStream(streamed);
      final m = jsonDecode(res.body);
      if (m['success'] == true) return Map<String, dynamic>.from(m['data']);
      throw Exception(m['error'] ?? 'Upload failed');
    } on SocketException catch (_) {
      throw const NoConnectionException();
    } on http.ClientException catch (_) {
      throw const NoConnectionException();
    }
  }

  MediaType _detectMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    if (lower.endsWith('.pdf')) return MediaType('application', 'pdf');
    return MediaType('application', 'octet-stream');
  }
}
