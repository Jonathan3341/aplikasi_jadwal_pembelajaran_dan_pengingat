import 'package:flutter/material.dart';

import '../app_data.dart';
import '../calendar_service.dart';
import '../notification_service.dart';

import '../widgets/schedule_card.dart';
import '../widgets/empty_state.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() =>
      _SchedulePageState();
}

class _SchedulePageState
    extends State<SchedulePage> {
  Future<void> _toggleScheduleReminder(
      ScheduleItem schedule,
      ) async {
    schedule.reminderEnabled =
    !schedule.reminderEnabled;

    await AppData.instance.updateSchedule(
      schedule,
    );

    await NotificationService.instance
        .scheduleClass(schedule);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          schedule.reminderEnabled
              ? 'Pengingat ${schedule.subject} diaktifkan'
              : 'Pengingat ${schedule.subject} dimatikan',
        ),
      ),
    );
  }

  void _showGestureActions(
      ScheduleItem schedule,
      ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              const SizedBox(height: 8),

              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                schedule.subject,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ListTile(
                leading: const Icon(
                  Icons.edit,
                ),
                title: const Text(
                  'Edit Jadwal',
                ),
                onTap: () {
                  Navigator.pop(context);

                  _showScheduleForm(
                    existing: schedule,
                  );
                },
              ),

              ListTile(
                leading: Icon(
                  schedule.reminderEnabled
                      ? Icons.notifications_off
                      : Icons.notifications,
                ),
                title: Text(
                  schedule.reminderEnabled
                      ? 'Matikan Pengingat'
                      : 'Aktifkan Pengingat',
                ),
                onTap: () async {
                  Navigator.pop(context);

                  await _toggleScheduleReminder(
                    schedule,
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text(
                  'Hapus Jadwal',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);

                  _deleteSchedule(
                    schedule,
                  );
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
  bool isDaily = true;
  int selectedDay = DateTime.now().weekday;

  final List<String> days = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,

      builder: (context, _) {
        final schedules =
            AppData.instance.schedules;

        return Scaffold(

          appBar: AppBar(
            title: const Text(
              'Jadwal',
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
                const EdgeInsets.all(16),

                child: Row(
                  children: [

                    Expanded(
                      child:
                      _modeButton(
                        title: 'Harian',
                        selected: isDaily,

                        onTap: () {
                          setState(() {
                            isDaily = true;
                          });
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child:
                      _modeButton(
                        title: 'Mingguan',
                        selected: !isDaily,

                        onTap: () {
                          setState(() {
                            isDaily = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              if (isDaily)
                SizedBox(
                  height: 65,

                  child: ListView.builder(
                    scrollDirection:
                    Axis.horizontal,

                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                    ),

                    itemCount: 7,

                    itemBuilder:
                        (context, index) {
                      final day =
                          index + 1;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedDay =
                                day;
                          });
                        },

                        child:
                        _dayButton(
                          index,
                          day ==
                              selectedDay,
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              Expanded(
                child: isDaily
                    ? _dailyList(
                  schedules,
                )
                    : _weeklyList(
                  schedules,
                ),
              ),
            ],
          ),

          floatingActionButton:
          FloatingActionButton(
            backgroundColor:
            const Color(0xFFFF7A00),

            foregroundColor:
            Colors.white,

            onPressed: () {
              _showScheduleForm();
            },

            child: const Icon(
              Icons.add,
            ),
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

  Widget _dayButton(
      int index,
      bool selected,
      ) {
    return Container(
      width: 58,

      margin:
      const EdgeInsets.symmetric(
        horizontal: 4,
      ),

      decoration: BoxDecoration(
        color: selected
            ? const Color(
          0xFFFF7A00,
        )
            : Colors.white,

        borderRadius:
        BorderRadius.circular(
          12,
        ),
      ),

      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [

          Text(
            days[index],

            style: TextStyle(
              fontSize: 12,
              fontWeight:
              FontWeight.bold,

              color: selected
                  ? Colors.white
                  : Colors.black87,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '${index + 1}',

            style: TextStyle(
              fontSize: 16,

              color: selected
                  ? Colors.white
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyList(
      List<ScheduleItem> schedules,
      ) {
    final filtered =
    schedules
        .where(
          (item) =>
      item.weekday ==
          selectedDay,
    )
        .toList();

    filtered.sort(
          (a, b) =>
      a.startHour * 60 +
          a.startMinute -
          (b.startHour * 60 +
              b.startMinute),
    );

    if (filtered.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today,
        title: 'Belum ada jadwal',
        description:
        'Belum ada jadwal pada hari ini.',
      );
    }

    return ListView(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
      ),

      children: filtered.map(
            (schedule) {
              return ScheduleCard(
                schedule: schedule,

                // ONE TAP
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ScheduleDetailPage(
                            schedule: schedule,
                          ),
                    ),
                  );
                },

                // DOUBLE TAP
                onDoubleTap: () {
                  _toggleScheduleReminder(
                    schedule,
                  );
                },

                // HOLD / LONG PRESS
                onLongPress: () {
                  _showGestureActions(
                    schedule,
                  );
                },

                onEdit: () {
                  _showScheduleForm(
                    existing: schedule,
                  );
                },

                onDelete: () {
                  _deleteSchedule(
                    schedule,
                  );
                },
              );
        },
      ).toList(),
    );
  }

  Widget _weeklyList(
      List<ScheduleItem> schedules,
      ) {
    return ListView(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
      ),

      children: List.generate(
        7,
            (index) {
          final day = index + 1;

          final daySchedules =
          schedules
              .where(
                (item) =>
            item.weekday ==
                day,
          )
              .toList();

          if (daySchedules.isEmpty) {
            return const SizedBox();
          }

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              Padding(
                padding:
                const EdgeInsets
                    .symmetric(
                  vertical: 8,
                ),

                child: Text(
                  days[index],

                  style:
                  const TextStyle(
                    fontSize: 16,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              ...daySchedules.map(
                    (schedule) =>
                        ScheduleCard(
                          schedule: schedule,

                          // ONE TAP
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ScheduleDetailPage(
                                      schedule: schedule,
                                    ),
                              ),
                            );
                          },

                          // DOUBLE TAP
                          onDoubleTap: () {
                            _toggleScheduleReminder(
                              schedule,
                            );
                          },

                          // HOLD / LONG PRESS
                          onLongPress: () {
                            _showGestureActions(
                              schedule,
                            );
                          },

                          onEdit: () {
                            _showScheduleForm(
                              existing: schedule,
                            );
                          },

                          onDelete: () {
                            _deleteSchedule(
                              schedule,
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteSchedule(
      ScheduleItem schedule,
      ) async {
    await CalendarService.instance
        .deleteScheduleEvent(
      schedule.calendarEventId,
    );

    await NotificationService.instance
        .cancelSchedule(
      schedule.id,
    );

    await AppData.instance
        .deleteSchedule(
      schedule.id,
    );
  }

  Future<void> _showScheduleForm({
    ScheduleItem? existing,
  }) async {
    final subjectController =
    TextEditingController(
      text: existing?.subject ?? '',
    );

    final roomController =
    TextEditingController(
      text: existing?.room ?? '',
    );

    final lecturerController =
    TextEditingController(
      text: existing?.lecturer ?? '',
    );

    final notesController =
    TextEditingController(
      text: existing?.notes ?? '',
    );

    int weekday =
        existing?.weekday ??
            selectedDay;

    TimeOfDay startTime =
    TimeOfDay(
      hour: existing?.startHour ?? 8,
      minute: existing?.startMinute ?? 0,
    );

    TimeOfDay endTime =
    TimeOfDay(
      hour: existing?.endHour ?? 10,
      minute: existing?.endMinute ?? 0,
    );

    bool reminderEnabled =
        existing?.reminderEnabled ?? true;

    int reminderMinutes =
        existing?.reminderMinutes ?? 30;

    await showDialog(
      context: context,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Tambah Jadwal'
                    : 'Edit Jadwal',
              ),

              content:
              SingleChildScrollView(
                child: Column(
                  children: [

                    TextField(
                      controller:
                      subjectController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Mata Pelajaran',
                      ),
                    ),

                    DropdownButtonFormField<int>(
                      initialValue: weekday,

                      decoration:
                      const InputDecoration(
                        labelText: 'Hari',
                      ),

                      items:
                      List.generate(
                        7,
                            (index) {
                          return DropdownMenuItem(
                            value:
                            index + 1,
                            child: Text(
                              days[index],
                            ),
                          );
                        },
                      ),

                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            weekday =
                                value;
                          });
                        }
                      },
                    ),

                    ListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      title: const Text(
                        'Jam Mulai',
                      ),

                      trailing: Text(
                        startTime.format(
                          context,
                        ),
                      ),

                      onTap: () async {
                        final result =
                        await showTimePicker(
                          context: context,
                          initialTime:
                          startTime,
                        );

                        if (result != null) {
                          setDialogState(() {
                            startTime =
                                result;
                          });
                        }
                      },
                    ),

                    ListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      title: const Text(
                        'Jam Selesai',
                      ),

                      trailing: Text(
                        endTime.format(
                          context,
                        ),
                      ),

                      onTap: () async {
                        final result =
                        await showTimePicker(
                          context: context,
                          initialTime:
                          endTime,
                        );

                        if (result != null) {
                          setDialogState(() {
                            endTime =
                                result;
                          });
                        }
                      },
                    ),

                    TextField(
                      controller:
                      roomController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Ruangan',
                      ),
                    ),

                    TextField(
                      controller:
                      lecturerController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Dosen',
                      ),
                    ),

                    TextField(
                      controller:
                      notesController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Catatan',
                      ),
                    ),

                    SwitchListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      title: const Text(
                        'Pengingat kelas',
                      ),

                      value:
                      reminderEnabled,

                      onChanged: (value) {
                        setDialogState(() {
                          reminderEnabled =
                              value;
                        });
                      },
                    ),

                    if (reminderEnabled)
                      DropdownButtonFormField<int>(
                        initialValue:
                        reminderMinutes,

                        decoration:
                        const InputDecoration(
                          labelText:
                          'Ingatkan sebelum',
                        ),

                        items: const [
                          DropdownMenuItem(
                            value: 5,
                            child:
                            Text('5 menit'),
                          ),
                          DropdownMenuItem(
                            value: 10,
                            child:
                            Text('10 menit'),
                          ),
                          DropdownMenuItem(
                            value: 15,
                            child:
                            Text('15 menit'),
                          ),
                          DropdownMenuItem(
                            value: 30,
                            child:
                            Text('30 menit'),
                          ),
                          DropdownMenuItem(
                            value: 60,
                            child:
                            Text('1 jam'),
                          ),
                        ],

                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              reminderMinutes =
                                  value;
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),

              actions: [

                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },

                  child:
                  const Text('Batal'),
                ),

                ElevatedButton(
                  onPressed: () async {
                    if (subjectController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final item =
                    ScheduleItem(
                      id: existing?.id ??
                          DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),

                      subject:
                      subjectController
                          .text
                          .trim(),

                      weekday: weekday,

                      startHour:
                      startTime.hour,

                      startMinute:
                      startTime.minute,

                      endHour:
                      endTime.hour,

                      endMinute:
                      endTime.minute,

                      room:
                      roomController
                          .text
                          .trim(),

                      lecturer:
                      lecturerController
                          .text
                          .trim(),

                      notes:
                      notesController
                          .text
                          .trim(),

                      reminderEnabled:
                      reminderEnabled,

                      reminderMinutes:
                      reminderMinutes,

                      calendarEventId:
                      existing
                          ?.calendarEventId,
                    );

                    if (existing == null) {
                      await AppData.instance
                          .addSchedule(
                        item,
                      );
                    } else {
                      await AppData.instance
                          .updateSchedule(
                        item,
                      );
                    }

                    await CalendarService
                        .instance
                        .syncSchedule(
                      item,
                    );

                    await NotificationService
                        .instance
                        .scheduleClass(
                      item,
                    );

                    if (mounted) {
                      Navigator.pop(
                        dialogContext,
                      );
                    }
                  },

                  child:
                  const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    subjectController.dispose();
    roomController.dispose();
    lecturerController.dispose();
    notesController.dispose();
  }
}