
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'student_assignment_detail_page.dart';

class StudentAssignmentsPage extends StatefulWidget {
  const StudentAssignmentsPage({super.key});

  @override
  State<StudentAssignmentsPage> createState() =>
      _StudentAssignmentsPageState();
}

class _StudentAssignmentsPageState
    extends State<StudentAssignmentsPage> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _assignments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignments();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result =
      await ApiService.instance.fetchAssignments();

      if (!mounted) return;

      setState(() {
        _assignments = result;
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

  String _formatDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tidak ada tenggat';
    }

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Tanggal tidak valid';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildAssignmentCard(Map<String, dynamic> assignment) {
    final title = assignment['title']?.toString() ?? 'Tanpa judul';
    final description =
        assignment['description']?.toString() ?? '';
    final className =
        assignment['class_name']?.toString() ?? 'Kelas';
    final dueAt = assignment['due_at']?.toString();

    final attachments =
    assignment['attachments'] is List
        ? assignment['attachments'] as List
        : [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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
              builder: (_) => StudentAssignmentDetailPage(
                assignmentId: assignmentId,
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      className,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (attachments.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          size: 15,
                          color: Colors.grey,
                        ),
                        Text(
                          '${attachments.length}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tenggat: ${_formatDate(dueAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Lihat detail',
                    style: TextStyle(
                      color: Color(0xFFFF7A00),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFFFF7A00),
                    size: 18,
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
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadAssignments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
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
              const Text(
                'Gagal memuat tugas.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadAssignments,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      )
          : _assignments.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 56,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'Belum ada tugas.',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tugas dari Guru akan muncul di sini.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadAssignments,
        color: const Color(0xFFFF7A00),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${_assignments.length} tugas tersedia',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
            ..._assignments.map(_buildAssignmentCard),
          ],
        ),
      ),
    );
  }
}
