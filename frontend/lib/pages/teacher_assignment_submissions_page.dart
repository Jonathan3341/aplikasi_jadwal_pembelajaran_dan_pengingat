import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';

import '../services/api_service.dart';

class TeacherAssignmentSubmissionsPage extends StatefulWidget {
  final int assignmentId;
  final String assignmentTitle;

  const TeacherAssignmentSubmissionsPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<TeacherAssignmentSubmissionsPage> createState() =>
      _TeacherAssignmentSubmissionsPageState();
}

class _TeacherAssignmentSubmissionsPageState
    extends State<TeacherAssignmentSubmissionsPage> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _submissions = [];

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }


  Future<void> _loadSubmissions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.instance
          .fetchAssignmentSubmissions(widget.assignmentId);

      if (!mounted) return;

      setState(() {
        _submissions = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }


  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      _showMessage('Tautan tidak valid.');
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
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
          .downloadSubmissionAttachment(id);

      if (bytes.isEmpty) {
        _showMessage('File lampiran kosong.');
        return;
      }

      var fileName =
          attachment['original_name']?.toString() ?? 'jawaban';

      fileName = fileName
          .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
          .trim();

      if (fileName.isEmpty) {
        fileName = 'jawaban';
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

  Future<void> _showGradeDialog(
      Map<String, dynamic> submission,
      ) async {
    final submissionId = int.tryParse(
      submission['id']?.toString() ?? '',
    );

    if (submissionId == null) {
      _showMessage('ID pengumpulan tidak valid.');
      return;
    }

    final gradeController = TextEditingController(
      text: submission['grade']?.toString() ?? '',
    );

    final feedbackController = TextEditingController(
      text: submission['feedback']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Berikan Penilaian'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: gradeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Nilai',
                      hintText: '0–100',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final grade = double.tryParse(
                        value?.trim() ?? '',
                      );

                      if (grade == null ||
                          grade < 0 ||
                          grade > 100) {
                        return 'Masukkan nilai antara 0–100.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Guru',
                      hintText: 'Berikan masukan untuk Murid...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Kirim Nilai'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      gradeController.dispose();
      feedbackController.dispose();
      return;
    }

    if (confirmed != true) {
      gradeController.dispose();
      feedbackController.dispose();
      return;
    }

    try {
      await ApiService.instance.gradeSubmission(
        submissionId: submissionId,
        grade: double.parse(gradeController.text.trim()),
        feedback: feedbackController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('Penilaian berhasil dikirim.');
      await _loadSubmissions();
    } catch (e) {
      _showMessage('Gagal mengirim penilaian: $e');
    } finally {
      gradeController.dispose();
      feedbackController.dispose();
    }
  }

  Widget _buildAttachments(List attachments) {
    if (attachments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Tidak ada lampiran jawaban.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: attachments.map<Widget>((item) {
        final attachment = Map<String, dynamic>.from(item);
        final type = attachment['attachment_type']?.toString();
        final name =
            attachment['original_name']?.toString() ?? 'Lampiran';
        final url = attachment['url']?.toString() ?? '';
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
          subtitle: Text(isLink ? 'Tautan jawaban' : 'File jawaban'),
          trailing: IconButton(
            tooltip: isLink ? 'Buka tautan' : 'Ambil file',
            icon: Icon(
              isLink ? Icons.open_in_new : Icons.download,
            ),
            onPressed: isLink
                ? () => _openLink(url)
                : () => _downloadAttachment(attachment),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmissionCard(
      Map<String, dynamic> submission,
      ) {
    final studentName =
        submission['student_name']?.toString() ?? 'Murid';
    final studentNim =
        submission['student_nim']?.toString() ?? '-';
    final status =
        submission['status']?.toString() ?? 'submitted';
    final isGraded = status == 'graded';

    final attachments = submission['attachments'] is List
        ? submission['attachments'] as List
        : [];

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE2CC),
                  child: Icon(
                    Icons.person_outline,
                    color: Color(0xFFFF7A00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'NIM: $studentNim',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isGraded
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isGraded ? 'Dinilai' : 'Perlu dinilai',
                    style: TextStyle(
                      color: isGraded
                          ? Colors.green.shade700
                          : Colors.orange.shade800,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Lampiran Jawaban (${attachments.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildAttachments(attachments),
            if (isGraded) ...[
              const Divider(),
              Text(
                'Nilai: ${submission['grade'] ?? '-'} / 100',
                style: const TextStyle(
                  color: Color(0xFFFF7A00),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if ((submission['feedback']?.toString() ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Catatan: ${submission['feedback']}',
                  ),
                ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showGradeDialog(submission),
                icon: const Icon(Icons.rate_review_outlined),
                label: Text(
                  isGraded ? 'Ubah Penilaian' : 'Beri Nilai',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final submittedCount = _submissions.length;
    final gradedCount = _submissions
        .where((item) => item['status'] == 'graded')
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Pengumpulan Tugas'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSubmissions,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 44,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSubmissions,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadSubmissions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.assignmentTitle,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    'Dikumpulkan',
                    submittedCount.toString(),
                    Icons.assignment_turned_in_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStat(
                    'Sudah Dinilai',
                    gradedCount.toString(),
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Daftar Pengumpulan',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_submissions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 54,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text('Belum ada Murid yang mengumpulkan.'),
                  ],
                ),
              )
            else
              ..._submissions.map(_buildSubmissionCard),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF7A00)),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
