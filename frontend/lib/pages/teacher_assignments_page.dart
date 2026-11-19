
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'teacher_create_assignment_page.dart';
import 'teacher_assignment_submissions_page.dart';

class TeacherAssignmentsPage extends StatefulWidget {
  const TeacherAssignmentsPage({super.key});

  @override
  State<TeacherAssignmentsPage> createState() =>
      _TeacherAssignmentsPageState();
}

class _TeacherAssignmentsPageState extends State<TeacherAssignmentsPage> {
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _classes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Membuka halaman pembuatan tugas.
  Future<void> _openCreateAssignment() async {
    if (_classes.isEmpty) {
      _showMessage('Belum ada kelas pada jadwal mengajar kamu.');
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherCreateAssignmentPage(
          classes: _classes,
        ),
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  // Menampilkan pesan.
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Mengedit judul dan instruksi tugas.
  Future<void> _editAssignment(
      Map<String, dynamic> assignment,
      ) async {
    final assignmentId = int.tryParse(
      assignment['id']?.toString() ?? '',
    );

    if (assignmentId == null) {
      _showMessage('ID tugas tidak valid.');
      return;
    }

    final titleController = TextEditingController(
      text: assignment['title']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: assignment['description']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    bool? confirmed;
    String newTitle = '';
    String newDescription = '';

    try {
      confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit Tugas'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Judul Tugas',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan judul tugas',
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
                      const Text(
                        'Instruksi Tugas',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan instruksi tugas',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext, false);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7A00),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      );

      // Ambil nilai sebelum controller di-dispose.
      if (confirmed == true) {
        newTitle = titleController.text.trim();
        newDescription = descriptionController.text.trim();
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }

    if (confirmed != true || !mounted) return;

    try {
      final updatedAssignment =
      await ApiService.instance.updateAssignment(
        id: assignmentId,
        title: newTitle,
        description: newDescription,
      );

      if (!mounted) return;

      setState(() {
        final index = _assignments.indexWhere(
              (item) => item['id'].toString() == assignmentId.toString(),
        );

        if (index != -1) {
          _assignments[index] = updatedAssignment;
        }
      });

      _showMessage('Tugas berhasil diperbarui.');
    } catch (e) {
      if (!mounted) return;

      _showMessage('Gagal memperbarui tugas: $e');
    }
  }

  // Mengambil daftar tugas dan kelas yang diajar Guru.
  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final assignments =
      await ApiService.instance.fetchAssignments();

      final schedules =
      await ApiService.instance.fetchSchedules();

      // Mengambil kelas unik berdasarkan jadwal mengajar Guru.
      final classMap = <String, Map<String, dynamic>>{};

      for (final schedule in schedules) {
        final classId = schedule['class_id'];

        if (classId == null) continue;

        final key = classId.toString();

        classMap[key] = {
          'id': classId,
          'class_name': schedule['class_name'] ?? 'Kelas',
          'major': schedule['major'] ?? '',
          'cohort_year': schedule['cohort_year'],
        };
      }

      if (!mounted) return;

      setState(() {
        _assignments = assignments;
        _classes = classMap.values.toList();
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

  // Mengubah format tanggal tenggat tugas.
  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Tidak ada tenggat';
    }

    final date = DateTime.tryParse(value.toString());

    if (date == null) return value.toString();

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year}';
  }

  // Membuat kartu tugas.
  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final className =
        assignment['class_name']?.toString() ?? 'Kelas';

    final status =
        assignment['status']?.toString() ?? 'published';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          final assignmentId = int.tryParse(
            assignment['id']?.toString() ?? '',
          );

          if (assignmentId == null) {
            _showMessage('ID tugas tidak valid.');
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TeacherAssignmentSubmissionsPage(
                assignmentId: assignmentId,
                assignmentTitle:
                assignment['title']?.toString() ?? 'Tugas',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFFFF7A00),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      assignment['title']?.toString() ??
                          'Tanpa judul',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'published'
                          ? Colors.green.shade50
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == 'published'
                          ? 'Diterbitkan'
                          : 'Diarsipkan',
                      style: TextStyle(
                        fontSize: 11,
                        color: status == 'published'
                            ? Colors.green.shade700
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Tombol edit tugas.
                  IconButton(
                    onPressed: () => _editAssignment(assignment),
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFFFF7A00),
                    ),
                    tooltip: 'Edit tugas',
                  ),

                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                assignment['description']?.toString() ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 18,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      className,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(assignment['due_at']),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Tugas Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateAssignment,
        backgroundColor: const Color(0xFFFF7A00),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Tugas'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gagal memuat tugas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Tugas',
                    _assignments.length.toString(),
                    Icons.assignment_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Kelas Mengajar',
                    _classes.length.toString(),
                    Icons.groups_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Daftar Tugas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_assignments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada tugas',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Tugas yang kamu buat akan muncul di sini.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._assignments.map(_buildAssignmentCard),
          ],
        ),
      ),
    );
  }

  // Membuat kartu statistik.
  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFFFF7A00),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
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
