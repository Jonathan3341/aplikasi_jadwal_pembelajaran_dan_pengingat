import 'package:flutter/material.dart';

import '../services/api_service.dart';

class AdminSchedulesPage extends StatefulWidget {
  const AdminSchedulesPage({super.key});

  @override
  State<AdminSchedulesPage> createState() => _AdminSchedulesPageState();
}

class _AdminSchedulesPageState extends State<AdminSchedulesPage> {
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _schedules = [];

  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _weekdayNames = [
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.instance.fetchClasses(),
        ApiService.instance.fetchSchedules(),
      ]);

      if (!mounted) return;

      setState(() {
        _classes = List<Map<String, dynamic>>.from(results[0]);
        _schedules = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  int _weekdayNumber(dynamic value) {
    if (value is int) {
      return value >= 1 && value <= 7 ? value : 1;
    }

    final number = int.tryParse(value?.toString() ?? '');

    if (number != null && number >= 1 && number <= 7) {
      return number;
    }

    final day = value?.toString().toLowerCase().trim();

    const dayMap = {
      'senin': 1,
      'monday': 1,
      'selasa': 2,
      'tuesday': 2,
      'rabu': 3,
      'wednesday': 3,
      'kamis': 4,
      'thursday': 4,
      'jumat': 5,
      'friday': 5,
      'sabtu': 6,
      'saturday': 6,
      'minggu': 7,
      'sunday': 7,
    };

    return dayMap[day] ?? 1;
  }

  String _formatTime(dynamic value) {
    final time = value?.toString() ?? '-';

    if (time.length >= 5) {
      return time.substring(0, 5);
    }

    return time;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;

    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1';
  }

  String _className(dynamic classId) {
    if (classId == null) return 'Kelas belum ditentukan';

    for (final item in _classes) {
      if (item['id'].toString() == classId.toString()) {
        return item['class_name']?.toString() ?? 'Tanpa nama';
      }
    }

    return 'Kelas tidak ditemukan';
  }

  List<Map<String, dynamic>> get _sortedSchedules {
    final result = List<Map<String, dynamic>>.from(_schedules);

    result.sort((a, b) {
      final dayComparison = _weekdayNumber(a['weekday'])
          .compareTo(_weekdayNumber(b['weekday']));

      if (dayComparison != 0) return dayComparison;

      return _formatTime(a['start_time'])
          .compareTo(_formatTime(b['start_time']));
    });

    return result;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showScheduleForm({Map<String, dynamic>? schedule}) async {
    if (_classes.isEmpty) {
      _showMessage('Buat kelas akademik terlebih dahulu.');
      return;
    }

    final isEditing = schedule != null;

    final subjectController = TextEditingController(
      text: schedule?['subject']?.toString() ?? '',
    );

    final roomController = TextEditingController(
      text: schedule?['room']?.toString() ?? '',
    );

    final lecturerController = TextEditingController(
      text: schedule?['lecturer']?.toString() ?? '',
    );

    final notesController = TextEditingController(
      text: schedule?['notes']?.toString() ?? '',
    );

    final startController = TextEditingController(
      text: _formatTime(schedule?['start_time'] ?? '08:00'),
    );

    final endController = TextEditingController(
      text: _formatTime(schedule?['end_time'] ?? '10:00'),
    );

    final formKey = GlobalKey<FormState>();

    int? selectedClassId = int.tryParse(
      schedule?['class_id']?.toString() ?? '',
    );

    if (!_classes.any(
      (item) => int.tryParse(item['id'].toString()) == selectedClassId,
    )) {
      selectedClassId = null;
    }

    int selectedWeekday = _weekdayNumber(schedule?['weekday'] ?? 1);

    bool reminderEnabled = schedule == null
        ? true
        : _toBool(schedule['reminder_enabled']);

    int reminderMinutes =
        int.tryParse(schedule?['reminder_minutes']?.toString() ?? '') ?? 10;

    const reminderOptions = [5, 10, 15, 30, 60];

    if (!reminderOptions.contains(reminderMinutes)) {
      reminderMinutes = 10;
    }

    Future<void> pickTime(
      BuildContext dialogContext,
      TextEditingController controller,
      StateSetter setDialogState,
    ) async {
      final parts = controller.text.split(':');

      final initialTime = parts.length == 2
          ? TimeOfDay(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts[1]) ?? 0,
            )
          : const TimeOfDay(hour: 8, minute: 0);

      final picked = await showTimePicker(
        context: dialogContext,
        initialTime: initialTime,
      );

      if (picked == null) return;

      controller.text =
          '${picked.hour.toString().padLeft(2, '0')}:'
          '${picked.minute.toString().padLeft(2, '0')}';

      setDialogState(() {});
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'Ubah Jadwal' : 'Tambah Jadwal'),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Mata Kuliah',
                            hintText: 'Contoh: Pemrograman Mobile',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nama mata kuliah wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<int>(
                          value: selectedClassId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kelas Akademik',
                            border: OutlineInputBorder(),
                          ),
                          items: _classes.map((item) {
                            final id = int.parse(item['id'].toString());
                            final name = item['class_name']?.toString() ?? '-';

                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedClassId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Pilih kelas akademik';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        DropdownButtonFormField<int>(
                          value: selectedWeekday,
                          decoration: const InputDecoration(
                            labelText: 'Hari',
                            border: OutlineInputBorder(),
                          ),
                          items: List.generate(7, (index) {
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(_weekdayNames[index]),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedWeekday = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: startController,
                                readOnly: true,
                                onTap: () => pickTime(
                                  dialogContext,
                                  startController,
                                  setDialogState,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Jam Mulai',
                                  suffixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: endController,
                                readOnly: true,
                                onTap: () => pickTime(
                                  dialogContext,
                                  endController,
                                  setDialogState,
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Jam Selesai',
                                  suffixIcon: Icon(Icons.access_time),
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: roomController,
                          decoration: const InputDecoration(
                            labelText: 'Ruangan',
                            hintText: 'Contoh: Gedung A - 301',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: lecturerController,
                          decoration: const InputDecoration(
                            labelText: 'Dosen / Pengajar',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: notesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Catatan',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Pengingat Aktif'),
                          subtitle: const Text(
                            'Pengaturan awal pengingat untuk jadwal ini.',
                          ),
                          value: reminderEnabled,
                          onChanged: (value) {
                            setDialogState(() {
                              reminderEnabled = value;
                            });
                          },
                        ),

                        if (reminderEnabled)
                          DropdownButtonFormField<int>(
                            value: reminderMinutes,
                            decoration: const InputDecoration(
                              labelText: 'Ingatkan sebelum kelas',
                              border: OutlineInputBorder(),
                            ),
                            items: reminderOptions.map((minutes) {
                              return DropdownMenuItem<int>(
                                value: minutes,
                                child: Text('$minutes menit'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  reminderMinutes = value;
                                });
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;

                    final startParts = startController.text.split(':');
                    final endParts = endController.text.split(':');

                    final startValue =
                        int.parse(startParts[0]) * 60 +
                        int.parse(startParts[1]);

                    final endValue =
                        int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

                    if (endValue <= startValue) {
                      _showMessage(
                        'Jam selesai harus lebih besar dari jam mulai.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, {
                      'subject': subjectController.text.trim(),
                      'class_id': selectedClassId,
                      'weekday': selectedWeekday,
                      'start_time': startController.text,
                      'end_time': endController.text,
                      'room': roomController.text.trim(),
                      'lecturer': lecturerController.text.trim(),
                      'notes': notesController.text.trim(),
                      'reminder_enabled': reminderEnabled,
                      'reminder_minutes': reminderMinutes,
                    });
                  },
                  child: Text(isEditing ? 'Simpan' : 'Buat Jadwal'),
                ),
              ],
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      subjectController.dispose();
      roomController.dispose();
      lecturerController.dispose();
      notesController.dispose();
      startController.dispose();
      endController.dispose();
    });

    if (result == null) return;

    try {
      if (isEditing) {
        final id = schedule['id'].toString();

        await ApiService.instance.updateSchedule(id, result);

        _showMessage('Jadwal berhasil diperbarui.');
      } else {
        await ApiService.instance.createSchedule(result);

        _showMessage('Jadwal berhasil ditambahkan.');
      }

      await _loadData();
    } catch (error) {
      _showMessage('Gagal menyimpan jadwal: $error');
    }
  }

  Future<void> _deleteSchedule(Map<String, dynamic> schedule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Jadwal'),
          content: Text(
            'Apakah kamu yakin ingin menghapus jadwal '
            '"${schedule['subject']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final id = schedule['id'].toString();

      await ApiService.instance.deleteSchedule(id);

      _showMessage('Jadwal berhasil dihapus.');
      await _loadData();
    } catch (error) {
      _showMessage('Gagal menghapus jadwal: $error');
    }
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    final weekday = _weekdayNumber(schedule['weekday']);
    final subject = schedule['subject']?.toString() ?? '-';
    final start = _formatTime(schedule['start_time']);
    final end = _formatTime(schedule['end_time']);
    final room = schedule['room']?.toString() ?? '-';
    final lecturer = schedule['lecturer']?.toString() ?? '-';
    final className = _className(schedule['class_id']);
    final reminderEnabled = _toBool(schedule['reminder_enabled']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showScheduleForm(schedule: schedule);
                    } else if (value == 'delete') {
                      _deleteSchedule(schedule);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Ubah Jadwal')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus Jadwal')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              className,
              style: const TextStyle(
                color: Colors.deepOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 8),
                Text(_weekdayNames[weekday - 1]),
                const SizedBox(width: 18),
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 8),
                Text('$start - $end'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(room.isEmpty ? '-' : room)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(lecturer.isEmpty ? '-' : lecturer)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  reminderEnabled
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  size: 18,
                  color: reminderEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  reminderEnabled ? 'Pengingat aktif' : 'Pengingat nonaktif',
                  style: TextStyle(
                    color: reminderEnabled ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Jadwal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showScheduleForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? ListView(
                children: [
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Gagal memuat data:\n$_errorMessage',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ),
                ],
              )
            : _schedules.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(
                    Icons.calendar_month_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Center(child: Text('Belum ada jadwal pembelajaran.')),
                ],
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  Text(
                    'Total ${_schedules.length} jadwal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ..._sortedSchedules.map(_buildScheduleCard),
                ],
              ),
      ),
    );
  }
}
