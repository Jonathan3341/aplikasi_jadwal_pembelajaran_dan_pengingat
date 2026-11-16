
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> classes = [];

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }



  Future<void> _loadClasses() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final schedules = await ApiService.instance.fetchSchedules();

      final Map<String, Map<String, dynamic>> uniqueClasses = {};

      for (final schedule in schedules) {
        final classId = schedule['class_id'];

        if (classId == null) continue;

        uniqueClasses[classId.toString()] = {
          'class_id': classId,
          'class_name': schedule['class_name'] ?? 'Kelas',
          'major': schedule['major'] ?? '-',
          'cohort_year': schedule['cohort_year'] ?? '-',
        };
      }

      final result = uniqueClasses.values.toList();

      result.sort((a, b) {
        return a['class_name']
            .toString()
            .compareTo(b['class_name'].toString());
      });

      if (!mounted) return;

      setState(() {
        classes = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal memuat daftar kelas: $e';
        isLoading = false;
      });
    }
  }

  // Menyimpan daftar murid berdasarkan ID kelas.
  final Map<int, List<Map<String, dynamic>>> _studentsByClass = {};

// Menandai kelas yang sedang memuat daftar murid.
  final Set<int> _loadingStudentClassIds = {};

// Menyimpan pesan error berdasarkan ID kelas.
  final Map<int, String> _studentErrors = {};


  Future<void> _loadStudents(int classId, {bool retry = false}) async {
    // Jika data sudah tersedia, tidak perlu mengambil ulang.
    if (_studentsByClass.containsKey(classId) && !retry) {
      return;
    }

    setState(() {
      _loadingStudentClassIds.add(classId);
      _studentErrors.remove(classId);
    });

    try {
      final students =
      await ApiService.instance.fetchClassStudents(classId);

      if (!mounted) return;

      setState(() {
        _studentsByClass[classId] = students;
        _loadingStudentClassIds.remove(classId);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingStudentClassIds.remove(classId);
        _studentErrors[classId] = e.toString();
      });
    }
  }

  Widget _buildClassCard(Map<String, dynamic> classItem) {
    final int classId = int.parse(classItem['class_id'].toString());

    final String className =
        classItem['class_name']?.toString() ?? 'Kelas';

    final String major =
        classItem['major']?.toString() ?? '-';

    final String cohortYear =
        classItem['cohort_year']?.toString() ?? '-';

    final bool isLoading =
    _loadingStudentClassIds.contains(classId);

    final String? error = _studentErrors[classId];

    final List<Map<String, dynamic>> students =
        _studentsByClass[classId] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          if (expanded) {
            _loadStudents(classId);
          }
        },
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFE2CC),
          child: Icon(
            Icons.groups_outlined,
            color: Color(0xFFFF7A00),
          ),
        ),
        title: Text(
          className,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('$major • Angkatan $cohortYear'),
        children: [
          const Divider(height: 1),

          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 30,
                  ),
                  const SizedBox(height: 8),
                  const Text('Gagal memuat daftar murid.'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      _loadStudents(classId, retry: true);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else if (students.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Belum ada murid di kelas ini.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...students.map((student) {
                final String name =
                    student['name']?.toString() ?? 'Tanpa Nama';

                final String nim =
                    student['nim']?.toString() ?? '-';

                final String studentMajor =
                    student['major']?.toString() ?? '-';

                return ListTile(
                  leading: const CircleAvatar(
                    radius: 19,
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'NIM: $nim\n$studentMajor',
                  ),
                  isThreeLine: true,
                );
              }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Kelas Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () async {
              setState(() {
                _studentsByClass.clear();
                _studentErrors.clear();
              });

              await _loadClasses();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
              ),
            );
          }

          if (errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadClasses,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (classes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadClasses,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Icon(
                    Icons.groups_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Belum ada kelas yang ditugaskan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadClasses,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${classes.length} kelas ditugaskan kepada Anda',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ...classes.map(_buildClassCard),
              ],
            ),
          );
        },
      ),
    );
  }
}
