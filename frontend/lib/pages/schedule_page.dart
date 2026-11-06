import 'package:flutter/material.dart';

import '../app_data.dart';
import '../notification_service.dart';

import '../widgets/empty_state.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/schedule_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool isDaily = true;
  bool isMonthly = false;

  int selectedDay = DateTime.now().weekday;

  DateTime selectedDate = DateTime.now();

  final List<String> days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  Future<void> _toggleScheduleReminder(ScheduleItem schedule) async {
    final newValue = !schedule.reminderEnabled;

    try {
      await AppData.instance.setScheduleReminderPreference(
        schedule.id,
        enabled: newValue,
      );

      if (newValue) {
        await NotificationService.instance.scheduleClass(schedule);
      } else {
        await NotificationService.instance.cancelSchedule(schedule.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? 'Pengingat ${schedule.subject} diaktifkan'
                : 'Pengingat ${schedule.subject} dimatikan',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah pengingat: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,
      builder: (context, _) {
        final schedules = AppData.instance.schedules;
        final isLoading = AppData.instance.schedulesLoading;
        final error = AppData.instance.scheduleError;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Jadwal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: 'Muat ulang jadwal',
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  AppData.instance.loadSchedulesFromApi();
                },
              ),
            ],
          ),

          body: Column(
            children: [
              // MODE HARIAN / MINGGUAN / BULANAN.
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        title: 'Harian',
                        selected: isDaily,
                        onTap: () {
                          setState(() {
                            isDaily = true;
                            isMonthly = false;
                            selectedDay = selectedDate.weekday;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _modeButton(
                        title: 'Mingguan',
                        selected: !isDaily && !isMonthly,
                        onTap: () {
                          setState(() {
                            isDaily = false;
                            isMonthly = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _modeButton(
                        title: 'Bulanan',
                        selected: isMonthly,
                        onTap: () {
                          setState(() {
                            isDaily = false;
                            isMonthly = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // PILIH HARI.
              if (isDaily)
                SizedBox(
                  height: 65,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final day = index + 1;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay = day;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                            ).add(Duration(days: day - selectedDate.weekday));
                          });
                        },
                        child: _dayButton(index, day == selectedDay),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // DAFTAR JADWAL.
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF7A00),
                        ),
                      );
                    }

                    if (error != null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.cloud_off,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(error, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  AppData.instance.loadSchedulesFromApi();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (isMonthly) {
                      return _monthlyCalendar(schedules);
                    }

                    return isDaily
                        ? _dailyList(schedules)
                        : _weeklyList(schedules);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFF7A00) : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _dayButton(int index, bool selected) {
    return Container(
      width: 58,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFF7A00) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            days[index],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 16,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(ScheduleItem schedule) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        title: Text(
          schedule.subject,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule.timeText),
              if (schedule.room.isNotEmpty) Text('Ruangan: ${schedule.room}'),
              if (schedule.lecturer.isNotEmpty)
                Text('Dosen: ${schedule.lecturer}'),
              if (schedule.className != null)
                Text('Kelas: ${schedule.className}'),
            ],
          ),
        ),
        trailing: IconButton(
          tooltip: schedule.reminderEnabled
              ? 'Matikan pengingat pribadi'
              : 'Aktifkan pengingat pribadi',
          icon: Icon(
            schedule.reminderEnabled
                ? Icons.notifications_active
                : Icons.notifications_off_outlined,
            color: schedule.reminderEnabled
                ? const Color(0xFFFF7A00)
                : Colors.grey,
          ),
          onPressed: () {
            _toggleScheduleReminder(schedule);
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ScheduleDetailPage(schedule: schedule),
            ),
          );
        },
      ),
    );
  }

  // DAFTAR HARIAN.
  Widget _dailyList(List<ScheduleItem> schedules) {
    final filtered =
        schedules.where((item) => item.weekday == selectedDay).toList()..sort(
          (a, b) =>
              (a.startHour * 60 + a.startMinute) -
              (b.startHour * 60 + b.startMinute),
        );

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today,
        title: 'Belum ada jadwal',
        description: 'Belum ada jadwal pada hari ini.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: filtered.map(_scheduleCard).toList(),
    );
  }

  // DAFTAR MINGGUAN.
  Widget _weeklyList(List<ScheduleItem> schedules) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: List.generate(7, (index) {
        final day = index + 1;

        final daySchedules =
            schedules.where((item) => item.weekday == day).toList()..sort(
              (a, b) =>
                  (a.startHour * 60 + a.startMinute) -
                  (b.startHour * 60 + b.startMinute),
            );

        if (daySchedules.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                days[index],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...daySchedules.map(_scheduleCard),
          ],
        );
      }),
    );
  }

  // KALENDER BULANAN.
  Widget _monthlyCalendar(List<ScheduleItem> schedules) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month - 1,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_monthName(selectedDate.month)} ${selectedDate.year}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedDate = DateTime(
                      selectedDate.year,
                      selectedDate.month + 1,
                      1,
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: CalendarWidget(
            selectedDate: selectedDate,
            scheduledWeekdays: schedules.map((item) => item.weekday).toSet(),
            onDateSelected: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
        ),
        const Divider(),
        Expanded(flex: 2, child: _selectedDateEvents(schedules)),
      ],
    );
  }

  Widget _selectedDateEvents(List<ScheduleItem> schedules) {
    final selectedSchedules =
        schedules.where((item) => item.weekday == selectedDate.weekday).toList()
          ..sort(
            (a, b) =>
                (a.startHour * 60 + a.startMinute) -
                (b.startHour * 60 + b.startMinute),
          );

    final dateLabel =
        '${selectedDate.day} ${_monthName(selectedDate.month)} '
        '${selectedDate.year}';

    if (selectedSchedules.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada jadwal pada $dateLabel.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54, fontSize: 13),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      children: [
        Text(
          'Jadwal $dateLabel',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        ...selectedSchedules.map(_scheduleCard),
      ],
    );
  }

  String _monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
  }
}
