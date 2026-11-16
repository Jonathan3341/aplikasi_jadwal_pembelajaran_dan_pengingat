
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeacherSchedulePage extends StatefulWidget {
  const TeacherSchedulePage({super.key});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> schedules = [];

  final List<String> weekdays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.instance.fetchSchedules();

      result.sort((a, b) {
        final dayA = _getWeekdayNumber(a['weekday']);
        final dayB = _getWeekdayNumber(b['weekday']);

        if (dayA != dayB) {
          return dayA.compareTo(dayB);
        }

        return _formatTime(a['start_time'])
            .compareTo(_formatTime(b['start_time']));
      });

      if (!mounted) return;

      setState(() {
        schedules = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Gagal memuat jadwal mengajar: $e';
        isLoading = false;
      });
    }
  }

  int _getWeekdayNumber(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    final text = value?.toString().toLowerCase().trim() ?? '';

    final number = int.tryParse(text);
    if (number != null) return number;

    const dayMap = {
      'senin': 1,
      'selasa': 2,
      'rabu': 3,
      'kamis': 4,
      'jumat': 5,
      'jum\'at': 5,
      'sabtu': 6,
      'minggu': 7,
    };

    return dayMap[text] ?? 0;
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';

    final time = value.toString();
    final parts = time.split(':');

    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }

    return time;
  }

  List<Map<String, dynamic>> _getSchedulesByDay(int day) {
    return schedules.where((schedule) {
      return _getWeekdayNumber(schedule['weekday']) == day;
    }).toList();
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final subject = schedule['subject']?.toString() ?? 'Mata Pelajaran';
    final className = schedule['class_name']?.toString() ?? '-';
    final room = schedule['room']?.toString() ?? '-';

    final startTime = _formatTime(schedule['start_time']);
    final endTime = _formatTime(schedule['end_time']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
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
                Expanded(
                  child: Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 5),
                Text(
                  '$startTime - $endTime',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kelas: $className',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ruangan: $room',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaySection(int day) {
    final daySchedules = _getSchedulesByDay(day);

    if (daySchedules.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                weekdays[day - 1],
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${daySchedules.length} jadwal',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        ...daySchedules.map(_buildScheduleCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text(
          'Jadwal Mengajar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadSchedules,
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
                      onPressed: _loadSchedules,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (schedules.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 140),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Belum ada jadwal mengajar.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadSchedules,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                const Text(
                  'Daftar jadwal mengajar Anda',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                ...List.generate(
                  7,
                      (index) => _buildDaySection(index + 1),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
