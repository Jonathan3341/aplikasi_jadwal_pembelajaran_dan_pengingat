import 'package:flutter/material.dart';

import '../app_data.dart';
import '../widgets/calendar_widget.dart';
import '../widgets/schedule_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() =>
      _CalendarPageState();
}

class _CalendarPageState
    extends State<CalendarPage> {

  DateTime selectedDate =
  DateTime.now();

  bool monthly = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,

      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Kalender',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          body: Column(
            children: [

              Padding(
                padding:
                const EdgeInsets.all(
                  12,
                ),

                child: Row(
                  children: [

                    Expanded(
                      child: _modeButton(
                        'Bulanan',
                        monthly,
                            () {
                          setState(() {
                            monthly = true;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _modeButton(
                        'Mingguan',
                        !monthly,
                            () {
                          setState(() {
                            monthly = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (monthly)
                Expanded(
                  child: Column(
                    children: [

                      Padding(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 16,
                        ),

                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .spaceBetween,

                          children: [

                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectedDate =
                                      DateTime(
                                        selectedDate
                                            .year,
                                        selectedDate
                                            .month -
                                            1,
                                        1,
                                      );
                                });
                              },

                              icon: const Icon(
                                Icons
                                    .chevron_left,
                              ),
                            ),

                            Text(
                              _monthName(
                                selectedDate
                                    .month,
                              ),

                              style:
                              const TextStyle(
                                fontWeight:
                                FontWeight
                                    .bold,
                                fontSize: 16,
                              ),
                            ),

                            IconButton(
                              onPressed: () {
                                setState(() {
                                  selectedDate =
                                      DateTime(
                                        selectedDate
                                            .year,
                                        selectedDate
                                            .month +
                                            1,
                                        1,
                                      );
                                });
                              },

                              icon: const Icon(
                                Icons
                                    .chevron_right,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child:
                        CalendarWidget(
                          selectedDate:
                          selectedDate,

                          onDateSelected:
                              (date) {
                            setState(() {
                              selectedDate =
                                  date;
                            });
                          },
                        ),
                      ),

                      const Divider(),

                      Expanded(
                        child:
                        _selectedDayEvents(),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child:
                  _weeklyCalendar(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeButton(
      String title,
      bool selected,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding:
        const EdgeInsets.symmetric(
          vertical: 10,
        ),

        decoration: BoxDecoration(
          color: selected
              ? const Color(
            0xFFFF7A00,
          )
              : Colors.white,

          borderRadius:
          BorderRadius.circular(
            10,
          ),
        ),

        child: Text(
          title,
          textAlign: TextAlign.center,

          style: TextStyle(
            color: selected
                ? Colors.white
                : Colors.black87,

            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _selectedDayEvents() {
    final schedules =
    AppData.instance.schedules
        .where(
          (item) =>
      item.weekday ==
          selectedDate.weekday,
    )
        .toList();

    if (schedules.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada kegiatan pada tanggal ini.',
        ),
      );
    }

    return ListView(
      padding:
      const EdgeInsets.all(12),

      children: [

        Text(
          '${selectedDate.day} '
              '${_monthName(selectedDate.month)} '
              '${selectedDate.year}',

          style: const TextStyle(
            fontWeight:
            FontWeight.bold,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 10),

        ...schedules.map(
              (schedule) =>
              ScheduleCard(
                schedule: schedule,
              ),
        ),
      ],
    );
  }

  Widget _weeklyCalendar() {
    final monday =
    selectedDate.subtract(
      Duration(
        days: selectedDate.weekday - 1,
      ),
    );

    return ListView.builder(
      padding:
      const EdgeInsets.all(12),

      itemCount: 7,

      itemBuilder: (context, index) {
        final date =
        monday.add(
          Duration(days: index),
        );

        final schedules =
        AppData.instance.schedules
            .where(
              (item) =>
          item.weekday ==
              date.weekday,
        )
            .toList();

        return Card(
          color: Colors.white,

          child: Padding(
            padding:
            const EdgeInsets.all(12),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  '${_dayName(date.weekday)}, '
                      '${date.day}/'
                      '${date.month}',

                  style:
                  const TextStyle(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                if (schedules.isEmpty)
                  const Text(
                    'Tidak ada jadwal',
                    style: TextStyle(
                      color:
                      Colors.black54,
                    ),
                  ),

                ...schedules.map(
                      (schedule) => ListTile(
                    contentPadding:
                    EdgeInsets.zero,

                    leading: const Icon(
                      Icons
                          .calendar_today,
                      color:
                      Color(
                        0xFFFF7A00,
                      ),
                    ),

                    title: Text(
                      schedule.subject,
                    ),

                    subtitle: Text(
                      '${schedule.timeText} • '
                          '${schedule.room}',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

  String _dayName(int day) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return days[day - 1];
  }
}