
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class TeacherDashboardPage extends StatefulWidget {
  final Map<String, dynamic> profile;
  final ValueChanged<int> onNavigate;

  const TeacherDashboardPage({
    super.key,
    required this.profile,
    required this.onNavigate,
  });

  @override
  State<TeacherDashboardPage> createState() =>
      _TeacherDashboardPageState();
}

class _TeacherDashboardPageState
    extends State<TeacherDashboardPage> {
  List<Map<String, dynamic>> _schedules = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final schedules =
      await ApiService.instance.fetchSchedules();

      if (!mounted) return;

      setState(() {
        _schedules = schedules;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  int get _today {
    final weekday = DateTime.now().weekday;
    return weekday;
  }

  String get _todayName {
    const days = [
      '',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return days[_today];
  }

  List<Map<String, dynamic>> get _todaySchedules {
    final result = _schedules.where((schedule) {
      return int.tryParse(
        schedule['weekday']?.toString() ?? '',
      ) ==
          _today;
    }).toList();

    result.sort((a, b) {
      return (a['start_time'] ?? '')
          .toString()
          .compareTo((b['start_time'] ?? '').toString());
    });

    return result;
  }

  int get _totalClasses {
    final classIds = _schedules
        .map((schedule) => schedule['class_id']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    return classIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final teacherName =
        widget.profile['name']?.toString() ?? 'Guru';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Dashboard Guru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSchedules,
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF7A00),
          ),
        )
            : _errorMessage != null
            ? _buildError()
            : _buildContent(teacherName),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.cloud_off,
          size: 55,
          color: Colors.grey,
        ),
        const SizedBox(height: 12),
        const Center(
          child: Text('Gagal memuat jadwal mengajar.'),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton(
            onPressed: _loadSchedules,
            child: const Text('Coba Lagi'),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(String teacherName) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildWelcomeCard(teacherName),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Total Jadwal',
                value: _schedules.length.toString(),
                icon: Icons.calendar_month,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Kelas Diajar',
                value: _totalClasses.toString(),
                icon: Icons.school_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Jadwal Hari Ini',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => widget.onNavigate(1),
              child: const Text('Lihat Semua'),
            ),
          ],
        ),

        Text(
          _todayName,
          style: const TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 12),

        if (_todaySchedules.isEmpty)
          _buildEmptySchedule()
        else
          ..._todaySchedules.map(_buildScheduleCard),
      ],
    );
  }

  Widget _buildWelcomeCard(String teacherName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7A00),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.waving_hand,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 14),
          const Text(
            'Selamat datang,',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            teacherName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Semoga kegiatan mengajar hari ini berjalan lancar.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFFF7A00), size: 28),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(
      Map<String, dynamic> schedule,
      ) {
    final subject = schedule['subject']?.toString() ?? '-';
    final className = schedule['class_name']?.toString() ?? '-';
    final room = schedule['room']?.toString() ?? '-';
    final start = schedule['start_time']?.toString() ?? '-';
    final end = schedule['end_time']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 75,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A00),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 7),
                Text('Kelas: $className'),
                Text('Ruangan: $room'),
                const SizedBox(height: 7),
                Text(
                  '$start - $end',
                  style: const TextStyle(
                    color: Color(0xFFFF7A00),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.event_available,
            size: 42,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            'Tidak ada jadwal mengajar hari ini.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
