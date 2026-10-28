import 'package:flutter/material.dart';

import '../app_data.dart';
import '../notification_service.dart';

import '../widgets/reminder_card.dart';
import '../widgets/empty_state.dart';

class ReminderPage extends StatelessWidget {
  const ReminderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppData.instance,

      builder: (context, _) {
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
            title: const Text(
              'Pengingat',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),

          body: reminders.isEmpty
              ? const EmptyState(
            icon:
            Icons.notifications_none,
            title:
            'Belum ada pengingat',
            description:
            'Tambahkan pengingat tugas atau kegiatan penting.',
          )
              : ListView(
            padding:
            const EdgeInsets.all(
              16,
            ),

            children:
            reminders.map(
                  (reminder) {
                return ReminderCard(
                  reminder: reminder,

                  onEdit: () {
                    _showReminderForm(
                      context,
                      reminder,
                    );
                  },

                  onDelete: () async {
                    await NotificationService
                        .instance
                        .cancelReminder(
                      reminder.id,
                    );

                    await AppData.instance
                        .deleteReminder(
                      reminder.id,
                    );
                  },
                );
              },
            ).toList(),
          ),

          floatingActionButton:
          FloatingActionButton(
            backgroundColor:
            const Color(0xFFFF7A00),

            foregroundColor:
            Colors.white,

            onPressed: () {
              _showReminderForm(
                context,
                null,
              );
            },

            child: const Icon(
              Icons.add,
            ),
          ),
        );
      },
    );
  }

  static Future<void> _showReminderForm(
      BuildContext context,
      ReminderItem? existing,
      ) async {
    final titleController =
    TextEditingController(
      text: existing?.title ?? '',
    );

    final descriptionController =
    TextEditingController(
      text: existing?.description ?? '',
    );

    DateTime dueAt =
        existing?.dueAt ??
            DateTime.now().add(
              const Duration(hours: 1),
            );

    bool notificationEnabled =
        existing?.notificationEnabled ?? true;

    await showDialog(
      context: context,

      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Tambah Pengingat'
                    : 'Edit Pengingat',
              ),

              content:
              SingleChildScrollView(
                child: Column(
                  children: [

                    TextField(
                      controller:
                      titleController,
                      decoration:
                      const InputDecoration(
                        labelText: 'Judul',
                      ),
                    ),

                    TextField(
                      controller:
                      descriptionController,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Deskripsi',
                      ),
                    ),

                    ListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      title: const Text(
                        'Tanggal',
                      ),

                      subtitle: Text(
                        '${dueAt.day}/'
                            '${dueAt.month}/'
                            '${dueAt.year}',
                      ),

                      onTap: () async {
                        final result =
                        await showDatePicker(
                          context: context,
                          firstDate:
                          DateTime.now(),
                          lastDate:
                          DateTime.now()
                              .add(
                            const Duration(
                              days: 365,
                            ),
                          ),
                          initialDate:
                          dueAt,
                        );

                        if (result != null) {
                          setDialogState(() {
                            dueAt =
                                DateTime(
                                  result.year,
                                  result.month,
                                  result.day,
                                  dueAt.hour,
                                  dueAt.minute,
                                );
                          });
                        }
                      },
                    ),

                    ListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      title: const Text(
                        'Waktu',
                      ),

                      trailing: Text(
                        '${dueAt.hour.toString().padLeft(2, '0')}:'
                            '${dueAt.minute.toString().padLeft(2, '0')}',
                      ),

                      onTap: () async {
                        final result =
                        await showTimePicker(
                          context: context,
                          initialTime:
                          TimeOfDay(
                            hour: dueAt.hour,
                            minute:
                            dueAt.minute,
                          ),
                        );

                        if (result != null) {
                          setDialogState(() {
                            dueAt =
                                DateTime(
                                  dueAt.year,
                                  dueAt.month,
                                  dueAt.day,
                                  result.hour,
                                  result.minute,
                                );
                          });
                        }
                      },
                    ),

                    SwitchListTile(
                      contentPadding:
                      EdgeInsets.zero,

                      title: const Text(
                        'Notifikasi',
                      ),

                      value:
                      notificationEnabled,

                      onChanged: (value) {
                        setDialogState(() {
                          notificationEnabled =
                              value;
                        });
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
                    if (titleController
                        .text
                        .trim()
                        .isEmpty) {
                      return;
                    }

                    final item =
                    ReminderItem(
                      id: existing?.id ??
                          DateTime.now()
                              .millisecondsSinceEpoch
                              .toString(),

                      title:
                      titleController
                          .text
                          .trim(),

                      description:
                      descriptionController
                          .text
                          .trim(),

                      dueAt: dueAt,

                      notificationEnabled:
                      notificationEnabled,
                    );

                    if (existing == null) {
                      await AppData.instance
                          .addReminder(item);
                    } else {
                      await AppData.instance
                          .updateReminder(item);
                    }

                    await NotificationService
                        .instance
                        .scheduleReminder(
                      item,
                    );

                    if (context.mounted) {
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

    titleController.dispose();
    descriptionController.dispose();
  }
}