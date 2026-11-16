
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../utils/assignment_file_helper.dart';

class TeacherCreateAssignmentPage extends StatefulWidget {
  final List<Map<String, dynamic>> classes;

  const TeacherCreateAssignmentPage({
    super.key,
    required this.classes,
  });

  @override
  State<TeacherCreateAssignmentPage> createState() =>
      _TeacherCreateAssignmentPageState();
}

class _TeacherCreateAssignmentPageState
    extends State<TeacherCreateAssignmentPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _linkNameController = TextEditingController();
  final _linkUrlController = TextEditingController();

  String? _selectedClassId;
  DateTime? _dueDate;

  List<PlatformFile> _selectedFiles = [];
  final List<Map<String, dynamic>> _links = [];

  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkNameController.dispose();
    _linkUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(
        const Duration(days: 7),
      ),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (selected != null) {
      setState(() {
        _dueDate = selected;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<void> _pickAttachments() async {
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

    if (url.isEmpty) {
      _showMessage('Masukkan URL terlebih dahulu.');
      return;
    }

    final uri = Uri.tryParse(url);

    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        uri.host.isEmpty) {
      _showMessage('URL harus menggunakan http atau https.');
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedClassId == null) {
      _showMessage('Pilih kelas terlebih dahulu.');
      return;
    }

    final classId = int.tryParse(_selectedClassId!);

    if (classId == null) {
      _showMessage('ID kelas tidak valid.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final multipartFiles =
      await AssignmentFileHelper.toMultipartFiles(
        _selectedFiles,
      );

      final dueAt = _dueDate == null
          ? null
          : DateTime(
        _dueDate!.year,
        _dueDate!.month,
        _dueDate!.day,
        23,
        59,
      ).toIso8601String();

      await ApiService.instance.createAssignment(
        classId: classId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueAt: dueAt,
        files: multipartFiles,
        links: _links,
      );

      if (!mounted) return;

      _showMessage('Tugas berhasil dibuat.');

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal membuat tugas: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 20),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('Buat Tugas'),
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Informasi Tugas'),

            DropdownButtonFormField<String>(
              initialValue: _selectedClassId,
              decoration: const InputDecoration(
                labelText: 'Pilih Kelas',
                prefixIcon: Icon(Icons.groups_outlined),
                border: OutlineInputBorder(),
              ),
              items: widget.classes.map((kelas) {
                final id = kelas['id'].toString();
                final name = kelas['class_name']?.toString() ?? 'Kelas';

                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedClassId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Pilih kelas terlebih dahulu.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas',
                hintText: 'Contoh: Tugas Pemrograman Flutter',
                prefixIcon: Icon(Icons.assignment_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Judul tugas wajib diisi.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Instruksi Tugas',
                hintText: 'Jelaskan instruksi dan ketentuan tugas...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Instruksi tugas wajib diisi.';
                }
                return null;
              },
            ),

            _sectionTitle('Tenggat Pengumpulan'),

            OutlinedButton.icon(
              onPressed: _pickDueDate,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text(
                _dueDate == null
                    ? 'Pilih tanggal tenggat'
                    : _formatDate(_dueDate!),
              ),
            ),

            _sectionTitle('Lampiran File atau Foto'),

            OutlinedButton.icon(
              onPressed: _selectedFiles.length >= 5
                  ? null
                  : _pickAttachments,
              icon: const Icon(Icons.attach_file),
              label: const Text('Pilih File atau Foto'),
            ),

            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...List.generate(_selectedFiles.length, (index) {
                final file = _selectedFiles[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.insert_drive_file_outlined,
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
                      onPressed: () => _removeFile(index),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }),
            ],

            _sectionTitle('Tautan Materi atau Referensi'),

            TextField(
              controller: _linkNameController,
              decoration: const InputDecoration(
                labelText: 'Nama tautan',
                hintText: 'Contoh: Materi Microsoft Teams',
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
                prefixIcon: Icon(Icons.link),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: _addLink,
              icon: const Icon(Icons.add_link),
              label: const Text('Tambahkan Tautan'),
            ),

            if (_links.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...List.generate(_links.length, (index) {
                final link = _links[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.link),
                    title: Text(link['name']),
                    subtitle: Text(
                      link['url'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: () => _removeLink(index),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                    ),
                  ),
                );
              }),
            ],

            const SizedBox(height: 28),

            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAssignment,
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Terbitkan Tugas',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
