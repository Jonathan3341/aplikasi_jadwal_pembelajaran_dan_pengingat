import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminClassesPage extends StatefulWidget {
  const AdminClassesPage({super.key});

  @override
  State<AdminClassesPage> createState() => _AdminClassesPageState();
}

class _AdminClassesPageState extends State<AdminClassesPage> {
  List<Map<String, dynamic>> _classes = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.instance.fetchClasses();

      if (!mounted) return;

      setState(() {
        _classes = List<Map<String, dynamic>>.from(result);
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showClassForm({Map<String, dynamic>? classData}) async {
    final isEditing = classData != null;

    final nameController = TextEditingController(
      text: classData?['class_name']?.toString() ?? '',
    );

    final majorController = TextEditingController(
      text: classData?['major']?.toString() ?? '',
    );

    final yearController = TextEditingController(
      text: classData?['cohort_year']?.toString() ?? '',
    );

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Ubah Kelas' : 'Tambah Kelas'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kelas',
                      hintText: 'Contoh: IF-2026-A',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama kelas wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: majorController,
                    decoration: const InputDecoration(
                      labelText: 'Jurusan',
                      hintText: 'Contoh: Informatika',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Jurusan wajib diisi';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: yearController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tahun Angkatan',
                      hintText: 'Contoh: 2026',
                    ),
                    validator: (value) {
                      if (value == null || int.tryParse(value.trim()) == null) {
                        return 'Masukkan tahun yang valid';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;

                Navigator.pop(context, {
                  'class_name': nameController.text.trim(),
                  'major': majorController.text.trim(),
                  'cohort_year': int.parse(yearController.text.trim()),
                });
              },
              child: Text(isEditing ? 'Simpan' : 'Buat Kelas'),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
      majorController.dispose();
      yearController.dispose();
    });

    if (result == null) return;

    try {
      if (isEditing) {
        final id = int.parse(classData['id'].toString());

        await ApiService.instance.updateClass(id, result);

        _showMessage('Kelas berhasil diperbarui.');
      } else {
        await ApiService.instance.createClass(result);

        _showMessage('Kelas berhasil ditambahkan.');
      }

      await _loadClasses();
    } catch (error) {
      _showMessage('Gagal menyimpan kelas: $error');
    }
  }

  Future<void> _deleteClass(Map<String, dynamic> classData) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: Text(
          'Apakah kamu yakin ingin menghapus kelas '
          '"${classData['class_name']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final id = int.parse(classData['id'].toString());

      await ApiService.instance.deleteClass(id);

      _showMessage('Kelas berhasil dihapus.');
      await _loadClasses();
    } catch (error) {
      _showMessage('Gagal menghapus kelas: $error');
    }
  }

  Future<void> _showStudents(int classId, String className) async {
    try {
      final result = await ApiService.instance.fetchStudents(classId: classId);

      if (!mounted) return;

      final students = List<Map<String, dynamic>>.from(result);

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text('Murid $className'),
            content: SizedBox(
              width: double.maxFinite,
              child: students.isEmpty
                  ? const Text('Belum ada murid di kelas ini.')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: students.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final student = students[index];

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            student['name']?.toString() ?? 'Tanpa nama',
                          ),
                          subtitle: Text('NIM: ${student['nim'] ?? '-'}'),
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tutup'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await _showAssignStudent(classId, className);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Tambah Murid'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      _showMessage('Gagal mengambil data murid: $error');
    }
  }

  Future<void> _showAssignStudent(int classId, String className) async {
    try {
      final result = await ApiService.instance.fetchStudents(unassigned: true);

      if (!mounted) return;

      final students = List<Map<String, dynamic>>.from(result);

      if (students.isEmpty) {
        _showMessage('Tidak ada murid yang belum memiliki kelas.');
        return;
      }

      String? selectedNim;

      final nim = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Tambah Murid ke Kelas'),
                content: DropdownButtonFormField<String>(
                  value: selectedNim,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Murid',
                    border: OutlineInputBorder(),
                  ),
                  items: students.map((student) {
                    final studentNim = student['nim'].toString();
                    final studentName =
                        student['name']?.toString() ?? 'Tanpa nama';

                    return DropdownMenuItem<String>(
                      value: studentNim,
                      child: Text(
                        '$studentName ($studentNim)',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedNim = value;
                    });
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    onPressed: selectedNim == null
                        ? null
                        : () => Navigator.pop(dialogContext, selectedNim),
                    child: const Text('Tambahkan'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (nim == null) return;

      await ApiService.instance.assignStudentToClass(
        nim: nim,
        classId: classId,
      );

      _showMessage('Murid berhasil dimasukkan ke $className.');

      await _showStudents(classId, className);
      await _loadClasses();
    } catch (error) {
      _showMessage('Gagal memasukkan murid: $error');
    }
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    final id = int.parse(classData['id'].toString());
    final name = classData['class_name']?.toString() ?? '-';
    final major = classData['major']?.toString() ?? '-';
    final year = classData['cohort_year']?.toString() ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.class_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('$major • Angkatan $year'),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showClassForm(classData: classData);
                    } else if (value == 'delete') {
                      _deleteClass(classData);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Ubah Kelas')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus Kelas')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _showStudents(id, name),
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Kelola Murid'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Kelas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showClassForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kelas'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadClasses,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Gagal memuat kelas:\n$_errorMessage',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadClasses,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              )
            : _classes.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.class_outlined, size: 56, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Belum ada kelas.')),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  Text(
                    'Total ${_classes.length} kelas',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._classes.map(_buildClassCard),
                ],
              ),
      ),
    );
  }
}
