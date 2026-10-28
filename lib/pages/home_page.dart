import 'package:flutter/material.dart';

import '../app_data.dart';

import '../widgets/schedule_card.dart';
import '../widgets/reminder_card.dart';
import '../widgets/section_header.dart';
import 'learning_tasks_page.dart';
import 'api_tasks_page.dart';
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,

      builder: (context, _) {
        final now = DateTime.now();

        final todaySchedules =
        AppData.instance.schedules
            .where(
              (item) =>
          item.weekday ==
              now.weekday,
        )
            .toList();

        todaySchedules.sort(
              (a, b) =>
          a.startHour * 60 +
              a.startMinute -
              (b.startHour * 60 +
                  b.startMinute),
        );

        final reminders =
        [...AppData.instance.reminders]
          ..sort(
                (a, b) =>
                a.dueAt.compareTo(
                  b.dueAt,
                ),
          );

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,

            titleSpacing: 16,

            title: Row(
              children: [

                Container(
                  width: 48,
                  height: 48,

                  decoration:
                  const BoxDecoration(
                    color:
                    Color(0xFFFFE5D0),
                    shape: BoxShape.circle,
                  ),

                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color:
                    Color(0xFFFF7A00),
                  ),
                ),

                const SizedBox(width: 10),

                const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [

                    Text(
                      'Halo, Dexter!',
                      style:
                      TextStyle(
                        fontSize: 13,
                      ),
                    ),

                    Text(
                      'Dexter',
                      style:
                      TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),

                    Text(
                      'NIM: 825240111',
                      style:
                      TextStyle(
                        fontSize: 10,
                        color:
                        Colors.black54,
                      ),
                    ),

                    Text(
                      'Sistem Informasi',
                      style:
                      TextStyle(
                        fontSize: 10,
                        color:
                        Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              padding:
              const EdgeInsets.fromLTRB(
                8,
                8,
                8,
                90,
              ),

              child: Column(
                children: [

                  _dateCard(),

                  const SizedBox(height: 10),

                  _attendanceCard(),

                  const SizedBox(height: 10),


                  Card(
                    color: Colors.white,
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFE2CC),
                        child: Icon(
                          Icons.storage,
                          color: Color(0xFFFF7A00),
                        ),
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
                    title:
                    'Jadwal Hari Ini',

                    onPressed: () {},
                  ),

                  if (todaySchedules.isEmpty)
                    const Padding(
                      padding:
                      EdgeInsets.all(24),

                      child: Text(
                        'Tidak ada jadwal hari ini.',
                      ),
                    ),

                  ...todaySchedules.map(
                        (schedule) =>
                        ScheduleCard(
                          schedule: schedule,

                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (_) =>
                                    ScheduleDetailPage(
                                      schedule:
                                      schedule,
                                    ),
                              ),
                            );
                          },
                        ),
                  ),

                  const SizedBox(height: 8),

                  SectionHeader(
                    title:
                    'Pengingat Terdekat',

                    onPressed: () {},
                  ),

                  if (reminders.isEmpty)
                    const Padding(
                      padding:
                      EdgeInsets.all(24),

                      child: Text(
                        'Belum ada pengingat.',
                      ),
                    ),

                  ...reminders
                      .take(3)
                      .map(
                        (reminder) =>
                        ReminderCard(
                          reminder: reminder,
                        ),
                  ),
                ],
              ),
            ),
          ),

          floatingActionButton:
          SizedBox(
            width: 170,
            height: 42,

            child:
            FloatingActionButton.extended(
              backgroundColor:
              const Color(0xFFFF7A00),

              foregroundColor:
              Colors.white,

              onPressed: () {
                if (todaySchedules
                    .isEmpty) {
                  return;
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Jadwal hari ini: '
                          '${todaySchedules.length} kelas',
                    ),
                  ),
                );
              },

              icon: const Icon(
                Icons.check_circle_outline,
                size: 18,
              ),

              label: const Text(
                'Absen Sekarang',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ),

          floatingActionButtonLocation:
          FloatingActionButtonLocation
              .centerFloat,
        );
      },
    );
  }

  Widget _dateCard() {
    final now = DateTime.now();

    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.symmetric(
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(12),
      ),

      child: Center(
        child: Text(
          'Hari ini: '
              '${now.day}/'
              '${now.month}/'
              '${now.year}',

          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _attendanceCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(10),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.08,
            ),
            blurRadius: 5,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          const Text(
            'Kehadiran Semester Ini',

            style: TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const Align(
            alignment:
            Alignment.centerRight,

            child: Text(
              '95%',

              style: TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          ClipRRect(
            borderRadius:
            BorderRadius.circular(
              10,
            ),

            child:
            const LinearProgressIndicator(
              value: 0.95,
              minHeight: 7,

              backgroundColor:
              Color(0xFFE2E2E2),

              valueColor:
              AlwaysStoppedAnimation<
                  Color>(
                Color(0xFF4A9BD3),
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Hadir: 19 / 20 Pertemuan',

            style: TextStyle(
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}