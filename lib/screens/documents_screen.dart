import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_client.dart' show NoConnectionException;
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/document_service.dart';
import '../utils/error_utils.dart';
import '../widgets/no_connection_view.dart';

class DocumentsScreen extends StatefulWidget {
  final int bookingId;
  final String title;
  const DocumentsScreen({super.key, required this.bookingId, required this.title});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _dashboard = DashboardService();
  final _documentService = DocumentService();
  final _imagePicker = ImagePicker();
  final Set<String> _uploading = <String>{};
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final uid = await AuthService.instance.getUserId() ?? 0;
    final summary = await _dashboard.bookingSummary(widget.bookingId, uid);
    List<Map<String, dynamic>> docs = const [];
    String? docsError;
    try {
      docs = await _dashboard.listDocuments(widget.bookingId, uid);
    } catch (e) {
      docsError = friendlyError(e);
    }
    return {
      'summary': summary,
      'docs': docs,
      'docsError': docsError,
    };
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = _load();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'ACTIVE':
      case 'COMPLETE':
      case 'APPROVED':
        return Colors.green;
      case 'PENDING':
      case 'UNDER_REVIEW':
        return Colors.orange;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return '-';
    final lower = status.toLowerCase();
    return lower.split('_').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }

  Future<void> _uploadDocument({
    required String docType,
    required Future<File?> Function() pickFile,
  }) async {
    final file = await pickFile();
    if (file == null) return;

    const maxSize = 5 * 1024 * 1024; // 5MB
    if (await file.length() > maxSize) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File exceeds 5MB limit. Please choose a smaller file.')),
      );
      return;
    }

    final userId = await AuthService.instance.getUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload documents.')),
      );
      return;
    }

    setState(() {
      _uploading.add(docType);
    });
    try {
      final result = await _documentService.upload(
        bookingId: widget.bookingId,
        userId: userId,
        docType: docType,
        file: file,
        label: docType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded ${result['label'] ?? docType}. Pending review.')),
      );
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${friendlyError(e)}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploading.remove(docType);
        });
      }
    }
  }

  Future<File?> _pickFromFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf'],
      withData: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.single;
    if (file.size != null && file.size > 5 * 1024 * 1024) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File exceeds 5MB limit.')), 
      );
      return null;
    }
    final path = file.path;
    if (path == null) return null;
    return File(path);
  }

  Future<File?> _captureWithCamera() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (image == null) return null;
    return File(image.path);
  }

  Future<void> _openDocument(String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document not available yet.')),
      );
      return;
    }
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open document.')),
      );
    }
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final docType = (doc['doc_type'] ?? '').toString();
    final status = (doc['status'] ?? 'REQUIRED').toString().toUpperCase();
    final label = (doc['label'] ?? docType).toString();
    final color = _statusColor(status);
    final uploading = _uploading.contains(docType);
    final fileName = (doc['file_name'] ?? '').toString();
    final fileUrl = (doc['file_url'] ?? '').toString();
    final hasFile = fileUrl.isNotEmpty;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status == 'REJECTED'
                      ? Icons.cancel
                      : status == 'PENDING'
                          ? Icons.timelapse
                          : status == 'ACTIVE' || status == 'COMPLETE' || status == 'APPROVED'
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _formatStatus(status),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (fileName.isNotEmpty)
              Text(
                fileName,
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
            if ((doc['remarks'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(doc['remarks'].toString(), style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () => _uploadDocument(docType: docType, pickFile: _captureWithCamera),
                  icon: uploading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(uploading ? 'Uploading…' : 'Camera'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: uploading
                      ? null
                      : () => _uploadDocument(docType: docType, pickFile: _pickFromFiles),
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Files'),
                ),
                const Spacer(),
                if (hasFile)
                  TextButton.icon(
                    onPressed: () => _openDocument(fileUrl),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View'),
                  ),
                if (status == 'REJECTED')
                  FilledButton(
                    onPressed: uploading
                        ? null
                        : () => _uploadDocument(docType: docType, pickFile: _pickFromFiles),
                    child: const Text('Re-upload'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            if (error is NoConnectionException) {
              return Center(child: NoConnectionView(onRetry: _reload));
            }
            return Center(child: Text('Error: ${friendlyError(error ?? 'Unknown error')}'));
          }

          final data = snapshot.data as Map<String, dynamic>;
          final summary = Map<String, dynamic>.from(data['summary'] as Map);
          final docs = (data['docs'] as List).cast<Map<String, dynamic>>();
          final docsError = data['docsError'] as String?;

          final steps = (summary['steps'] as List).cast<Map<String, dynamic>>();
          final completed = steps.where((s) => s['done'] == true).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Document Status', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text('Progress', style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: steps.isEmpty ? 0 : completed / steps.length),
                    const SizedBox(height: 4),
                    Text(
                      '$completed of ${steps.length} completed',
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text('Required Documents', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              if (docsError != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDB4C4C)),
                  ),
                  child: Text(
                    'Unable to load documents from server. Please try again later.\n$docsError',
                    style: const TextStyle(color: Color(0xFF8B1E1E)),
                  ),
                ),
              if (docs.isEmpty && docsError == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No documents available yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ...docs.map(_buildDocumentCard),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Upload Guidelines:\n• JPG, PNG, PDF (max 5MB)\n• Clear & readable\n• Valid ≥ 6 months',
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('Need help?'),
                  subtitle: const Text('Contact our support team'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
