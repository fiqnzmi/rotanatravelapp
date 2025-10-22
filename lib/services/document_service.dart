import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config_service.dart';

class DocumentService {
  Uri _u(String p) => Uri.parse('${ConfigService.apiBase}/$p');

  Future<Map<String, dynamic>> upload({
    required int bookingId,
    required int userId,
    required String docType,
    required File file,
    String? label,
  }) async {
    final req = http.MultipartRequest('POST', _u('upload_document.php'))
      ..fields['booking_id'] = '$bookingId'
      ..fields['user_id'] = '$userId'
      ..fields['doc_type'] = docType;
    if (label != null) req.fields['label'] = label;
    req.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final m = jsonDecode(res.body);
    if (m['success'] == true) return Map<String, dynamic>.from(m['data']);
    throw Exception(m['error'] ?? 'Upload failed');
  }
}
