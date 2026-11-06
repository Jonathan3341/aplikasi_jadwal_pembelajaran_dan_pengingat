
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminUnassignedStudentsPage extends StatefulWidget {
  const AdminUnassignedStudentsPage({super.key});

  @override
  State<AdminUnassignedStudentsPage> createState() =>
      _AdminUnassignedStudentsPageState();
}

class _AdminUnassignedStudentsPageState
    extends State<AdminUnassignedStudentsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _classes = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final keyword = _searchController.text.trim();

      final results = await Future.wait([
        ApiService.instance.fetchClasses(),
        ApiService.instance.fetchStudents(
          unassigned: true,
          search: keyword.isEmpty ? null : keyword,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _classes = List<Map<String, dynamic>>.from(results[0]);
        _students = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _searchStudents() async {
    await _loadData();
  }

  List<Map<String, dynamic>> _eligibleClasses(
      Map<String, dynamic> student,
      ) {
    final studentMajor =
        student['major']?.toString().trim().toLowerCase() ?? '';

    if (studentMajor.isEmpty) return [];

    return _classes.where((item) {
      final classMajor =
          item['major']?.toString().trim().toLowerCase() ?? '';

      return classMajor == studentMajor;
    }).toList();
  }

  Future<void> _assignStudent(
      Map<String, dynamic> student,
      ) async {
    final nim = student['nim']?.toString() ?? '';
    final name = student['name']?.toString() ?? 'Mahasiswa';

    if (nim.isEmpty) {
      _showMessage('NIM mahasiswa tidak ditemukan.');
      return;
    }

    final eligibleClasses = _eligibleClasses(student);

    if (eligibleClasses.isEmpty) {
      _showMessage(
        'Belum ada kelas dengan jurusan yang sesuai dengan mahasiswa ini.',
      );
      return;
    }

    int? selectedClassId;

    final classId = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tempatkan Mahasiswa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nama: $name'),
                  const SizedBox(height: 4),
                  Text('NIM: $nim'),
                  const SizedBox(height: 4),
                  Text(
                    'Jurusan: ${student['major'] ?? '-'}',
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    initialValue: selectedClassId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Kelas',
                      border: OutlineInputBorder(),
                    ),
                    items: eligibleClasses.map((item) {
                      final id = int.parse(item['id'].toString());
                      final className =
                          item['class_name']?.toString() ?? '-';
                      final year =
                          item['cohort_year']?.toString() ?? '-';

                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text('$className ($year)'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedClassId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pilihan kelas dibatasi berdasarkan jurusan mahasiswa.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: selectedClassId == null
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                      selectedClassId,
                    );
                  },
                  child: const Text('Tempatkan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (classId == null) return;

    try {
      await ApiService.instance.assignStudentToClass(
        nim: nim,
        classId: classId,
      );

      if (!mounted) return;

      _showMessage('$name berhasil dimasukkan ke kelas.');

      await _loadData();
    } catch (error) {
      _showMessage('Gagal menempatkan mahasiswa: $error');
    }
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final name = student['name']?.toString() ?? 'Tanpa nama';
    final nim = student['nim']?.toString() ?? '-';
    final email = student['email']?.toString() ?? '-';
    final major = student['major']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFE5D0),
                  child: Icon(
                    Icons.person_outline,
                    color: Color(0xFFFF7A00),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow('NIM', nim),
            const SizedBox(height: 6),
            _infoRow('Email', email),
            const SizedBox(height: 6),
            _infoRow('Jurusan', major),
            const SizedBox(height: 12),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _assignStudent(student),
                icon: const Icon(Icons.school_outlined),
                label: const Text('Tempatkan ke Kelas'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 75,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        const Text(': '),
        Expanded(child: Text(value)),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.trim().isNotEmpty;

    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(
          hasSearch
              ? Icons.search_off
              : Icons.people_outline,
          size: 60,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            hasSearch
                ? 'Mahasiswa tidak ditemukan.'
                : 'Semua mahasiswa sudah memiliki kelas.',
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahasiswa Tanpa Kelas'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchStudents(),
              decoration: InputDecoration(
                hintText: 'Cari nama, NIM, atau jurusan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _searchStudents,
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Cari',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : _errorMessage != null
                  ? ListView(
                children: [
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Gagal memuat mahasiswa:\n$_errorMessage',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              )
                  : _students.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  24,
                ),
                children: [
                  Text(
                    '${_students.length} mahasiswa belum memiliki kelas',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const SizedBox(height: 14),
                  ..._students.map(_buildStudentCard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
