import 'dart:typed_data';

import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';
import 'student_submit_assignment_page.dart';

class StudentAssignmentDetailPage extends StatefulWidget {
  final int assignmentId;

  const StudentAssignmentDetailPage({
    super.key,
    required this.assignmentId,
  });

  @override
  State<StudentAssignmentDetailPage> createState() =>
      _StudentAssignmentDetailPageState();
}

class _StudentAssignmentDetailPageState
    extends State<StudentAssignmentDetailPage> {
  Map<String, dynamic>? _assignment;
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _submission;
  bool _isLoadingSubmission = true;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _loadMySubmission();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.instance
          .fetchAssignmentDetail(widget.assignmentId);

      if (!mounted) return;

      setState(() {
        _assignment = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMySubmission() async {
    try {
      final submissions =
      await ApiService.instance.fetchMySubmissions();

      final submission = submissions.cast<Map<String, dynamic>?>().firstWhere(
            (item) =>
        int.tryParse(item?['assignment_id']?.toString() ?? '') ==
            widget.assignmentId,
        orElse: () => null,
      );

      if (!mounted) return;

      setState(() {
        _submission = submission;
        _isLoadingSubmission = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingSubmission = false;
      });

      _showMessage('Gagal memuat status pengumpulan: $e');
    }
  }

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tidak ada tenggat';
    }

    final date = DateTime.tryParse(value)?.toLocal();

    if (date == null) return 'Tanggal tidak valid';

    const months = [
      'Januari', 'Februari', 'Maret', 'April',
      'Mei', 'Juni', 'Juli', 'Agustus',
      'September', 'Oktober', 'November', 'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showMessage('Tautan tidak valid.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showMessage('Tidak dapat membuka tautan.');
      }
    } catch (e) {
      _showMessage('Gagal membuka tautan: $e');
    }
  }


  Future<void> _downloadAttachment(
      Map<String, dynamic> attachment,
      ) async {
    final id = int.tryParse(
      attachment['id']?.toString() ?? '',
    );

    if (id == null) {
      _showMessage('ID lampiran tidak valid.');
      return;
    }

    try {
      final bytes = await ApiService.instance
          .downloadAssignmentAttachment(id);

      if (bytes.isEmpty) {
        _showMessage('File lampiran kosong.');
        return;
      }

      var fileName =
          attachment['original_name']?.toString() ?? 'lampiran';

      fileName = fileName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();

      if (fileName.isEmpty) {
        fileName = 'lampiran';
      }

      await FlutterFileSaver().writeFileAsBytes(
        fileName: fileName,
        bytes: Uint8List.fromList(bytes),
      );

      _showMessage('File berhasil disimpan: $fileName');
    } catch (e) {
      _showMessage('Gagal menyimpan lampiran: $e');
    }
  }


  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildAttachments(List attachments) {
    if (attachments.isEmpty) {
      return const Text(
        'Tidak ada lampiran.',
        style: TextStyle(color: Colors.grey),
      );
    }

    return Column(
      children: attachments.map<Widget>((item) {
        final attachment =
        Map<String, dynamic>.from(item);

        final type = attachment['attachment_type']?.toString();
        final name =
            attachment['original_name']?.toString() ??
                'Lampiran';

        final url = attachment['url']?.toString();

        final isLink = type == 'link';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isLink
                ? Icons.link
                : type == 'photo'
                ? Icons.image_outlined
                : Icons.insert_drive_file_outlined,
            color: const Color(0xFFFF7A00),
          ),
          title: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            isLink ? 'Tautan' : 'Lampiran file',
          ),
          trailing: IconButton(
            icon: Icon(
              isLink ? Icons.open_in_new : Icons.download,
            ),
            onPressed: isLink
                ? () => _openLink(url ?? '')
                : () => _downloadAttachment(attachment),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Detail Tugas'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF7A00),
        ),
      )
          : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 44,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      )
          : _assignment == null
          ? const Center(
        child: Text('Tugas tidak ditemukan.'),
      )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final assignment = _assignment!;

    final attachments =
    assignment['attachments'] is List
        ? assignment['attachments'] as List
        : [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection(
          title: assignment['title']?.toString() ??
              'Tanpa judul',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment['class_name']?.toString() ??
                    'Kelas',
                style: const TextStyle(
                  color: Color(0xFFFF7A00),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Instruksi Guru',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                assignment['description']?.toString() ??
                    'Tidak ada instruksi.',
              ),
            ],
          ),
        ),
        _buildSection(
          title: 'Informasi Tenggat',
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFFFF7A00),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _formatDate(
                    assignment['due_at']?.toString(),
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildSection(
          title: 'Lampiran dari Guru',
          child: _buildAttachments(attachments),
        ),

        _buildSubmissionStatus(),

        if (_submission?['status'] != 'graded')
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isLoadingSubmission
                  ? null
                  : () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentSubmitAssignmentPage(
                      assignmentId: widget.assignmentId,
                      assignmentTitle:
                      assignment['title']?.toString() ??
                          'Tugas',
                    ),
                  ),
                );

                if (result == true) {
                  await _loadMySubmission();
                }
              },
              icon: const Icon(Icons.upload_file),
              label: Text(
                _submission == null
                    ? 'Kumpulkan Tugas'
                    : 'Kumpulkan Ulang',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionStatus() {
    if (_isLoadingSubmission) {
      return _buildSection(
        title: 'Status Pengumpulan',
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_submission == null) {
      return _buildSection(
        title: 'Status Pengumpulan',
        child: const Row(
          children: [
            Icon(Icons.pending_outlined, color: Colors.orange),
            SizedBox(width: 10),
            Text('Belum mengumpulkan tugas.'),
          ],
        ),
      );
    }

    final status = _submission!['status']?.toString() ?? 'submitted';
    final isGraded = status == 'graded';
    final grade = _submission!['grade'];
    final feedback = _submission!['feedback']?.toString();

    return _buildSection(
      title: 'Status Pengumpulan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isGraded ? Icons.check_circle : Icons.hourglass_top,
                color: isGraded ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 10),
              Text(
                isGraded ? 'Sudah dinilai' : 'Sudah dikumpulkan',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (isGraded) ...[
            const SizedBox(height: 16),
            const Text(
              'Nilai',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              grade == null ? 'Belum tersedia' : '$grade / 100',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7A00),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Catatan Guru',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              feedback == null || feedback.isEmpty
                  ? 'Tidak ada catatan dari Guru.'
                  : feedback,
            ),
          ],
        ],
      ),
    );
  }
}
