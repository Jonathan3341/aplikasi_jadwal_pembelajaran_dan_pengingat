
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/assignment_file_helper.dart';

class StudentSubmitAssignmentPage extends StatefulWidget {
  final int assignmentId;
  final String assignmentTitle;

  const StudentSubmitAssignmentPage({
    super.key,
    required this.assignmentId,
    required this.assignmentTitle,
  });

  @override
  State<StudentSubmitAssignmentPage> createState() =>
      _StudentSubmitAssignmentPageState();
}

class _StudentSubmitAssignmentPageState
    extends State<StudentSubmitAssignmentPage> {
  final TextEditingController _linkNameController =
  TextEditingController();

  final TextEditingController _linkUrlController =
  TextEditingController();

  final List<PlatformFile> _selectedFiles = [];
  final List<Map<String, dynamic>> _links = [];

  bool _isSubmitting = false;

  @override
  void dispose() {
    _linkNameController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final files = await AssignmentFileHelper.pickFiles(
        existingFiles: _selectedFiles,
      );

      if (!mounted || files.isEmpty) return;

      setState(() {
        _selectedFiles.addAll(files);
      });
    } catch (e) {
      _showMessage(e.toString());
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
  }

  void _addLink() {
    final name = _linkNameController.text.trim();
    final url = _linkUrlController.text.trim();

    final uri = Uri.tryParse(url);

    if (url.isEmpty ||
        uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      _showMessage('Masukkan tautan HTTP atau HTTPS yang valid.');
      return;
    }

    if (_links.length + _selectedFiles.length >= 5) {
      _showMessage('Maksimal 5 lampiran.');
      return;
    }

    setState(() {
      _links.add({
        'name': name.isEmpty ? url : name,
        'url': url,
      });

      _linkNameController.clear();
      _linkUrlController.clear();
    });
  }

  void _removeLink(int index) {
    setState(() {
      _links.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_selectedFiles.isEmpty && _links.isEmpty) {
      _showMessage('Tambahkan file, foto, atau tautan jawaban.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final multipartFiles =
      await AssignmentFileHelper.toMultipartFiles(
        _selectedFiles,
      );

      await ApiService.instance.submitAssignment(
        assignmentId: widget.assignmentId,
        files: multipartFiles,
        links: _links,
      );

      if (!mounted) return;

      _showMessage('Jawaban berhasil dikumpulkan.');

      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('Gagal mengumpulkan tugas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
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
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Kumpulkan Tugas'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Tugas',
            Text(
              widget.assignmentTitle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          _buildSection(
            'File atau Foto Jawaban',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maksimal 5 lampiran, masing-masing maksimal 10 MB.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickFiles,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pilih File'),
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...List.generate(_selectedFiles.length, (index) {
                    final file = _selectedFiles[index];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.insert_drive_file_outlined,
                        color: Color(0xFFFF7A00),
                      ),
                      title: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${((file.lengthSync() ?? 0) / 1024).toStringAsFixed(1)} KB',
                      ),
                      trailing: IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _removeFile(index),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          _buildSection(
            'Tautan Jawaban',
            Column(
              children: [
                TextField(
                  controller: _linkNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama tautan (opsional)',
                    hintText: 'Contoh: Jawaban Google Drive',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _linkUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _isSubmitting ? null : _addLink,
                    icon: const Icon(Icons.add_link),
                    label: const Text('Tambah Tautan'),
                  ),
                ),
                if (_links.isNotEmpty) ...[
                  const Divider(),
                  ...List.generate(_links.length, (index) {
                    final link = _links[index];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.link,
                        color: Color(0xFFFF7A00),
                      ),
                      title: Text(link['name'].toString()),
                      subtitle: Text(
                        link['url'].toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _removeLink(index),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7A00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.send),
              label: Text(
                _isSubmitting
                    ? 'Mengirim Jawaban...'
                    : 'Kumpulkan Jawaban',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
