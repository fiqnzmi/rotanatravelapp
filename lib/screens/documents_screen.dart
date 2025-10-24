import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import '../services/dashboard_service.dart';
import '../services/auth_service.dart';
import '../services/document_service.dart';

class DocumentsScreen extends StatefulWidget {
  final int bookingId;
  final String title;
  const DocumentsScreen({super.key, required this.bookingId, required this.title});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _svc = DashboardService();
  final _docSvc = DocumentService();
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() { super.initState(); _future = _load(); }

  Future<Map<String, dynamic>> _load() async {
    final uid = await AuthService.instance.getUserId() ?? 0;
    final summary = await _svc.bookingSummary(widget.bookingId, uid);
    List<Map<String, dynamic>> docs = const [];
    String? docsError;
    try {
      docs = await _svc.listDocuments(widget.bookingId, uid);
    } catch (e) {
      docsError = e.toString();
    }
    return {'summary': summary, 'docs': docs, 'docsError': docsError};
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'ACTIVE':
      case 'COMPLETE':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickAndUpload(String docType) async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.single.path!);
    final uid = await AuthService.instance.getUserId() ?? 0;
    await _docSvc.upload(
      bookingId: widget.bookingId,
      userId: uid,
      docType: docType,
      file: file,
      label: docType,
    );
    setState(() { _future = _load(); });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          final m = snap.data as Map<String, dynamic>;
          final summary = m['summary'] as Map<String, dynamic>;
          final steps = (summary['steps'] as List).cast<Map<String, dynamic>>();
          final docs = (m['docs'] as List).cast<Map<String, dynamic>>();
          final docsError = m['docsError'] as String?;
          final done = steps.where((s)=>s['done']==true).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0,8))]
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Document Status', style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Progress', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(value: done/steps.length),
                  const SizedBox(height: 4),
                  Text('$done of ${steps.length} completed', style: const TextStyle(color: Colors.black54)),
                ]),
              ),
              const SizedBox(height: 16),
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No documents available yet.',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ...docs.map((d){
                final color = _statusColor(d['status'] ?? 'REQUIRED');
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(
                          d['status']=='REJECTED' ? Icons.cancel :
                          d['status']=='PENDING' ? Icons.timelapse :
                          d['status']=='COMPLETE' || d['status']=='ACTIVE' ? Icons.check_circle :
                          Icons.radio_button_unchecked,
                          color: color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(d['label'] ?? d['doc_type'], style: const TextStyle(fontWeight: FontWeight.w700))),
                        Text(d['status'] ?? '-', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 6),
                      if (d['file_name']!=null) Text(d['file_name'], style: const TextStyle(color: Colors.black54)),
                      if ((d['remarks']??'').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(d['remarks'], style: const TextStyle(color: Colors.redAccent)),
                      ],
                      const SizedBox(height: 8),
                      Row(children: [
                        OutlinedButton.icon(
                          onPressed: () => _pickAndUpload(d['doc_type']),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _pickAndUpload(d['doc_type']),
                          icon: const Icon(Icons.attach_file),
                          label: const Text('Files'),
                        ),
                        const Spacer(),
                        if (d['status']=='REJECTED') FilledButton(onPressed: () => _pickAndUpload(d['doc_type']), child: const Text('Re-upload')),
                      ]),
                    ]),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(12)),
                child: const Text('Upload Guidelines:\n• JPG, PNG, PDF (max 5MB)\n• Clear & readable\n• Valid ≥ 6 months'),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.support_agent_outlined),
                  title: const Text('Need Help?'),
                  subtitle: const Text('Contact our support team'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: (){},
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
