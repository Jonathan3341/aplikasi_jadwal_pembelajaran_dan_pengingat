import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'models/schedule_item.dart';

export 'models/schedule_item.dart';

class ReminderItem {
  String id;
  String title;
  String description;
  DateTime dueAt;
  bool notificationEnabled;

  ReminderItem({
    required this.id,
    required this.title,
    required this.description,
    required this.dueAt,
    this.notificationEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueAt': dueAt.toIso8601String(),
      'notificationEnabled': notificationEnabled,
    };
  }

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      dueAt: DateTime.parse(json['dueAt']),
      notificationEnabled: json['notificationEnabled'] ?? true,
    );
  }
}

class AppData extends ChangeNotifier {
  AppData._();

  static final AppData instance = AppData._();

  // ID khusus untuk membedakan pengingat kelas dan pengingat manual.
  static const String scheduleReminderPrefix = 'schedule_';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  final List<ScheduleItem> schedules = [];
  final List<ReminderItem> reminders = [];

  // Preferensi pengingat pribadi per akun.
  String _reminderUserId = 'default';

  Map<String, dynamic> _scheduleReminderSettings = {};

  String get _reminderSettingsKey =>
      'scheduleReminderSettings_$_reminderUserId';

  bool loaded = false;
  bool schedulesLoading = false;

  String? scheduleError;

  void refreshUI() {
    notifyListeners();
  }

  // ==========================================
  // LOAD DATA
  // ==========================================

  Future<void> load() async {
    final remindersJson = await _prefs.getString('reminders');

    reminders.clear();

    if (remindersJson != null) {
      final List<dynamic> decoded = jsonDecode(remindersJson);

      for (final item in decoded) {
        final reminder = ReminderItem.fromJson(Map<String, dynamic>.from(item));

        // Pengingat kelas dibuat ulang dari backend,
        // sehingga tidak perlu dimuat dari SharedPreferences.
        if (!reminder.id.startsWith(scheduleReminderPrefix)) {
          reminders.add(reminder);
        }
      }
    }

    schedules.clear();
    loaded = true;
    notifyListeners();
  }

  Future<void> loadSchedulesFromApi({String? userId}) async {
    schedulesLoading = true;
    scheduleError = null;

    if (userId != null && userId.trim().isNotEmpty) {
      _reminderUserId = userId.trim();
    }

    schedules.clear();
    _removeAllScheduleReminders();

    notifyListeners();

    try {
      // Membaca preferensi pengingat lokal.
      final savedSettings = await _prefs.getString(_reminderSettingsKey);

      _scheduleReminderSettings = {};

      if (savedSettings != null) {
        final decoded = jsonDecode(savedSettings);

        if (decoded is Map) {
          _scheduleReminderSettings = Map<String, dynamic>.from(decoded);
        }
      }

      // Mengambil jadwal resmi dari backend.
      final result = await ApiService.instance.fetchSchedules();

      final fetchedSchedules = result
          .map((json) => ScheduleItem.fromApiJson(json))
          .toList();

      // Terapkan preferensi pengingat akun yang sedang login.
      for (final schedule in fetchedSchedules) {
        final preference = _scheduleReminderSettings[schedule.id];

        if (preference is Map) {
          schedule.reminderEnabled = preference['enabled'] == true;
        }
      }

      schedules.addAll(fetchedSchedules);

      // Buat pengingat lokal berdasarkan jadwal terbaru.
      for (final schedule in schedules) {
        _syncScheduleReminder(schedule);
      }
    } catch (error) {
      scheduleError = 'Gagal mengambil jadwal dari server: $error';
    } finally {
      schedulesLoading = false;
      notifyListeners();
    }
  }

  // ==========================================
  // SCHEDULE REMINDER
  // ==========================================

  // Menghitung waktu pengingat untuk kelas berikutnya.
  DateTime _nextReminderTime(ScheduleItem schedule) {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final daysUntilClass = (schedule.weekday - now.weekday + 7) % 7;

    var classStart = today.add(
      Duration(
        days: daysUntilClass,
        hours: schedule.startHour,
        minutes: schedule.startMinute,
      ),
    );

    var reminderTime = classStart.subtract(
      Duration(minutes: schedule.reminderMinutes),
    );

    // Jika waktu pengingat minggu ini sudah lewat,
    // hitung pengingat untuk minggu berikutnya.
    if (!reminderTime.isAfter(now)) {
      classStart = classStart.add(const Duration(days: 7));

      reminderTime = classStart.subtract(
        Duration(minutes: schedule.reminderMinutes),
      );
    }

    return reminderTime;
  }

  // Membuat atau memperbarui pengingat dari sebuah jadwal.
  void _syncScheduleReminder(ScheduleItem schedule) {
    final reminderId = '$scheduleReminderPrefix${schedule.id}';

    // Hapus versi lama terlebih dahulu agar tidak duplikat.
    reminders.removeWhere((item) => item.id == reminderId);

    if (!schedule.reminderEnabled) {
      return;
    }

    final descriptionParts = [
      'Mulai pukul ${schedule.startText}',
      if (schedule.room.trim().isNotEmpty) 'Ruangan ${schedule.room}',
      if (schedule.lecturer.trim().isNotEmpty) 'Dosen ${schedule.lecturer}',
    ];

    reminders.add(
      ReminderItem(
        id: reminderId,
        title: 'Kelas: ${schedule.subject}',
        description: descriptionParts.join(' • '),
        dueAt: _nextReminderTime(schedule),
        notificationEnabled: true,
      ),
    );
  }

  void _removeAllScheduleReminders() {
    reminders.removeWhere((item) => item.id.startsWith(scheduleReminderPrefix));
  }

  Future<void> setScheduleReminderPreference(
    String scheduleId, {
    required bool enabled,
  }) async {
    final index = schedules.indexWhere((item) => item.id == scheduleId);

    if (index == -1) {
      throw Exception('Jadwal tidak ditemukan.');
    }

    final schedule = schedules[index];

    final oldValue = schedule.reminderEnabled;

    // Ubah hanya data lokal.
    schedule.reminderEnabled = enabled;

    _scheduleReminderSettings[scheduleId] = {'enabled': enabled};

    try {
      await _prefs.setString(
        _reminderSettingsKey,
        jsonEncode(_scheduleReminderSettings),
      );

      _syncScheduleReminder(schedule);

      notifyListeners();
    } catch (error) {
      schedule.reminderEnabled = oldValue;
      rethrow;
    }
  }

  // ==========================================
  // CRUD SCHEDULE
  // ==========================================

  Future<ScheduleItem> addSchedule(ScheduleItem item) async {
    final result = await ApiService.instance.createSchedule(item.toApiJson());

    final savedSchedule = ScheduleItem.fromApiJson(result);

    schedules.add(savedSchedule);

    // Sinkronisasi pengingat ke daftar ReminderItem.
    _syncScheduleReminder(savedSchedule);

    notifyListeners();

    return savedSchedule;
  }

  Future<ScheduleItem> updateSchedule(ScheduleItem item) async {
    final result = await ApiService.instance.updateSchedule(
      item.id,
      item.toApiJson(),
    );

    final updatedSchedule = ScheduleItem.fromApiJson(result);

    final index = schedules.indexWhere((schedule) => schedule.id == item.id);

    if (index != -1) {
      updatedSchedule.calendarEventId = schedules[index].calendarEventId;

      schedules[index] = updatedSchedule;
    }

    // Perbarui pengingat jika waktu atau status berubah.
    _syncScheduleReminder(updatedSchedule);

    notifyListeners();

    return updatedSchedule;
  }

  Future<void> deleteSchedule(String id) async {
    await ApiService.instance.deleteSchedule(id);

    schedules.removeWhere((schedule) => schedule.id == id);

    reminders.removeWhere((item) => item.id == '$scheduleReminderPrefix$id');

    notifyListeners();
  }

  void clearSchedules() {
    schedules.clear();

    // Jangan biarkan pengingat kelas akun sebelumnya tertinggal.
    _removeAllScheduleReminders();

    schedulesLoading = false;
    scheduleError = null;

    notifyListeners();
  }

  // ==========================================
  // CRUD MANUAL REMINDER
  // ==========================================

  Future<void> addReminder(ReminderItem item) async {
    reminders.add(item);

    await _save();

    notifyListeners();
  }

  Future<void> updateReminder(ReminderItem item) async {
    final index = reminders.indexWhere((element) => element.id == item.id);

    if (index != -1) {
      reminders[index] = item;

      await _save();

      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    reminders.removeWhere((element) => element.id == id);

    await _save();

    notifyListeners();
  }

  // Simpan pengingat manual saja.
  // Pengingat kelas selalu dibuat ulang dari backend.
  Future<void> _save() async {
    final manualReminders = reminders.where(
      (item) => !item.id.startsWith(scheduleReminderPrefix),
    );

    await _prefs.setString(
      'reminders',
      jsonEncode(manualReminders.map((item) => item.toJson()).toList()),
    );
  }
}
