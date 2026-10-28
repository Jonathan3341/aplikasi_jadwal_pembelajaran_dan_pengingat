import 'package:flutter/material.dart';

import '../app_data.dart';

class ScheduleCard extends StatelessWidget {
  final ScheduleItem schedule;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
  });

  Color get statusColor {
    if (schedule.nextOccurrence()
        .isBefore(DateTime.now())) {
      return Colors.grey;
    }

    return const Color(0xFFFF7A00);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 1x tap
      onTap: onTap,

      // 2x tap
      onDoubleTap: onDoubleTap,

      // tekan dan tahan
      onLongPress: onLongPress,

      child: Container(
        width: double.infinity,

        margin: const EdgeInsets.only(
          bottom: 10,
        ),

        padding: const EdgeInsets.all(10),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
          BorderRadius.circular(10),

          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.08),
              blurRadius: 5,
              offset:
              const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [

                  Text(
                    schedule.subject,

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Jam: ${schedule.timeText}',
                    style:
                    const TextStyle(
                      fontSize: 11,
                    ),
                  ),

                  Text(
                    'Ruang: ${schedule.room}',
                    style:
                    const TextStyle(
                      fontSize: 11,
                    ),
                  ),

                  Text(
                    'Dosen: ${schedule.lecturer}',
                    style:
                    const TextStyle(
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [

                      const Text(
                        'Status: ',
                        style:
                        TextStyle(
                          fontSize: 11,
                        ),
                      ),

                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),

                        decoration:
                        BoxDecoration(
                          color: statusColor,
                          borderRadius:
                          BorderRadius
                              .circular(
                              10),
                        ),

                        child: const Text(
                          'Terjadwal',
                          style:
                          TextStyle(
                            color:
                            Colors.white,
                            fontSize: 10,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit?.call();
                }

                if (value == 'delete') {
                  onDelete?.call();
                }
              },

              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ScheduleDetailPage extends StatelessWidget {
  final ScheduleItem schedule;

  const ScheduleDetailPage({
    super.key,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detail Kegiatan',
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(14),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  schedule.subject,

                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 18),

                _detail(
                  Icons.access_time,
                  'Waktu',
                  schedule.timeText,
                ),

                _detail(
                  Icons.calendar_today,
                  'Hari',
                  _dayName(schedule.weekday),
                ),

                _detail(
                  Icons.room,
                  'Ruangan',
                  schedule.room,
                ),

                _detail(
                  Icons.person,
                  'Dosen',
                  schedule.lecturer,
                ),

                _detail(
                  Icons.notifications,
                  'Pengingat',
                  schedule.reminderEnabled
                      ? '${schedule.reminderMinutes} menit sebelum kelas'
                      : 'Tidak aktif',
                ),

                const SizedBox(height: 16),

                const Text(
                  'Catatan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  schedule.notes.isEmpty
                      ? 'Tidak ada catatan.'
                      : schedule.notes,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(
      IconData icon,
      String title,
      String value,
      ) {
    return Padding(
      padding:
      const EdgeInsets.only(bottom: 14),

      child: Row(
        children: [

          Icon(
            icon,
            color:
            const Color(0xFFFF7A00),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                  const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),

                Text(
                  value,
                  style:
                  const TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _dayName(int day) {
    const names = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return names[day - 1];
  }
}