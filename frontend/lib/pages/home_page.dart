import 'package:flutter/material.dart';

import '../app_data.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

import '../widgets/schedule_card.dart';
import '../widgets/reminder_card.dart';
import '../widgets/section_header.dart';

import 'learning_tasks_page.dart';
import 'api_tasks_page.dart';
import 'attendance_map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Key untuk memperbarui kartu absensi setelah kembali
  // dari halaman Absensi Lokasi.
  final GlobalKey<_AttendanceSemesterCardState> _attendanceCardKey =
      GlobalKey<_AttendanceSemesterCardState>();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,
      builder: (context, _) {
        final now = DateTime.now();

        final todaySchedules = AppData.instance.schedules
            .where((item) => item.weekday == now.weekday)
            .toList();

        todaySchedules.sort(
          (a, b) =>
              a.startHour * 60 +
              a.startMinute -
              (b.startHour * 60 + b.startMinute),
        );

        final reminders = [...AppData.instance.reminders]
          ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5D0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: Color(0xFFFF7A00),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: _ProfileHeader()),
              ],
            ),
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
              child: Column(
                children: [
                  _dateCard(),

                  const SizedBox(height: 10),

                  // Kehadiran sekarang mengambil data dari API.
                  _AttendanceSemesterCard(key: _attendanceCardKey),

                  const SizedBox(height: 10),

                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFE2CC),
                        child: Icon(Icons.storage, color: Color(0xFFFF7A00)),
                      ),
                      title: const Text('Tugas Pembelajaran'),
                      subtitle: const Text(
                        'Tambah, edit, dan kelola tugas dengan SQLite',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LearningTasksPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFE2CC),
                        child: Icon(
                          Icons.cloud_download_outlined,
                          color: Color(0xFFFF7A00),
                        ),
                      ),
                      title: const Text('Data Tugas dari API'),
                      subtitle: const Text(
                        'Ambil dan tampilkan data dari REST API',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ApiTasksPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  SectionHeader(
                    title: 'Jadwal Hari Ini',
                    onPressed: () {
                      widget.onNavigate?.call(1);
                    },
                  ),

                  if (todaySchedules.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Tidak ada jadwal hari ini.'),
                    ),

                  ...todaySchedules.map(
                    (schedule) => ScheduleCard(
                      schedule: schedule,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ScheduleDetailPage(schedule: schedule),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  SectionHeader(
                    title: 'Pengingat Terdekat',
                    onPressed: () {
                      widget.onNavigate?.call(2);
                    },
                  ),

                  if (reminders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Belum ada pengingat.'),
                    ),

                  ...reminders
                      .take(3)
                      .map((reminder) => ReminderCard(reminder: reminder)),
                ],
              ),
            ),
          ),

          floatingActionButton: SizedBox(
            width: 170,
            height: 42,
            child: FloatingActionButton.extended(
              backgroundColor: const Color(0xFFFF7A00),
              foregroundColor: Colors.white,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AttendanceMapPage()),
                );

                // Setelah kembali dari halaman absensi,
                // ambil ulang data kehadiran dari backend.
                if (!mounted) return;

                _attendanceCardKey.currentState?.loadAttendance();
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text(
                'Absen Sekarang',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _dateCard() {
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Hari ini: '
          '${now.day}/'
          '${now.month}/'
          '${now.year}',
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ),
    );
  }
}

// KARTU KEHADIRAN SEMESTER

class _AttendanceSemesterCard extends StatefulWidget {
  const _AttendanceSemesterCard({super.key});

  @override
  State<_AttendanceSemesterCard> createState() =>
      _AttendanceSemesterCardState();
}

class _AttendanceSemesterCardState extends State<_AttendanceSemesterCard> {
  final ApiService _apiService = ApiService.instance;

  List<Map<String, dynamic>> _attendanceRecords = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    loadAttendance();
  }

  // Mengambil riwayat absensi langsung dari backend.
  Future<void> loadAttendance() async {
    if (!mounted || _isLoading && _attendanceRecords.isNotEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _apiService.fetchMyAttendance();

      if (!mounted) return;

      // Endpoint saat ini mengembalikan seluruh riwayat absensi.
      // Semua record yang dikembalikan dihitung.
      setState(() {
        _attendanceRecords = records;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Menghitung kehadiran tepat waktu.
  int get _presentCount {
    return _attendanceRecords.where((item) {
      final status = item['status']?.toString().toLowerCase();

      return status == 'hadir';
    }).length;
  }

  // Menghitung kehadiran terlambat.
  int get _lateCount {
    return _attendanceRecords.where((item) {
      final status = item['status']?.toString().toLowerCase();

      return status == 'terlambat';
    }).length;
  }

  // Total semua record absensi.
  int get _totalAttendance {
    return _attendanceRecords.length;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul dan tombol refresh.
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kehadiran Semester Ini',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),

              IconButton(
                tooltip: 'Perbarui kehadiran',
                visualDensity: VisualDensity.compact,
                onPressed: _isLoading ? null : loadAttendance,
                icon: const Icon(
                  Icons.refresh,
                  size: 20,
                  color: Color(0xFFFF7A00),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_errorMessage != null)
            _buildError()
          else
            _buildAttendanceStatistics(),
        ],
      ),
    );
  }

  // Tampilan statistik kehadiran.
  Widget _buildAttendanceStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Total absensi tercatat',
          style: TextStyle(fontSize: 11, color: Colors.black54),
        ),

        const SizedBox(height: 2),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$_totalAttendance',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7A00),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 6, bottom: 5),
              child: Text(
                'pertemuan',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _buildStatisticItem(
                label: 'Hadir',
                count: _presentCount,
                color: Colors.green,
                icon: Icons.check_circle_outline,
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: _buildStatisticItem(
                label: 'Terlambat',
                count: _lateCount,
                color: Colors.orange,
                icon: Icons.access_time,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          _totalAttendance == 0
              ? 'Belum ada data absensi yang tersimpan.'
              : 'Data diperbarui dari riwayat absensi server.',
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),

        const SizedBox(height: 4),

        if (_totalAttendance > 0)
          Text(
            'Terakhir diperbarui: ${TimeOfDay.now().format(context)}',
            style: const TextStyle(fontSize: 10, color: Colors.black38),
          ),
      ],
    );
  }

  // Komponen angka Hadir dan Terlambat.
  Widget _buildStatisticItem({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),

          const SizedBox(width: 7),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tampilan jika API gagal diakses.
  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 18),
              SizedBox(width: 6),
              Text(
                'Gagal mengambil data kehadiran',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),

          const SizedBox(height: 8),

          TextButton.icon(
            onPressed: loadAttendance,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

// HEADER PROFIL MURID

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  late Future<Map<String, dynamic>> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.instance.getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Memuat profil...', style: TextStyle(fontSize: 13));
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Text(
            'Profil tidak dapat dimuat',
            style: TextStyle(fontSize: 13),
          );
        }

        final profile = snapshot.data!;

        final name = profile['name']?.toString().trim() ?? '';
        final nim = profile['nim']?.toString().trim() ?? '';
        final major = profile['major']?.toString().trim() ?? '';

        final displayName = name.isEmpty ? 'Pengguna' : name;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Halo, $displayName!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),

            Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            Text(
              nim.isEmpty ? 'NIM belum diisi' : 'NIM: $nim',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),

            Text(
              major.isEmpty ? 'Jurusan belum diisi' : major,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        );
      },
    );
  }
}
