import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleItem {
  String id;
  String subject;
  int weekday;
  int startHour;
  int startMinute;
  int endHour;
  int endMinute;
  String room;
  String lecturer;
  String notes;
  bool reminderEnabled;
  int reminderMinutes;
  String? calendarEventId;

  ScheduleItem({
    required this.id,
    required this.subject,
    required this.weekday,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.room,
    required this.lecturer,
    required this.notes,
    this.reminderEnabled = true,
    this.reminderMinutes = 30,
    this.calendarEventId,
  });

  String get startText =>
      '${startHour.toString().padLeft(2, '0')}:'
          '${startMinute.toString().padLeft(2, '0')}';

  String get endText =>
      '${endHour.toString().padLeft(2, '0')}:'
          '${endMinute.toString().padLeft(2, '0')}';

  String get timeText => '$startText - $endText';

  DateTime nextOccurrence() {
    final now = DateTime.now();

    int difference = weekday - now.weekday;

    if (difference < 0) {
      difference += 7;
    }

    DateTime date = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: difference));

    DateTime result = DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMinute,
    );

    if (result.isBefore(now)) {
      result = result.add(const Duration(days: 7));
    }

    return result;
  }

  DateTime occurrenceOn(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      startHour,
      startMinute,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'weekday': weekday,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'room': room,
      'lecturer': lecturer,
      'notes': notes,
      'reminderEnabled': reminderEnabled,
      'reminderMinutes': reminderMinutes,
      'calendarEventId': calendarEventId,
    };
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'],
      subject: json['subject'],
      weekday: json['weekday'],
      startHour: json['startHour'],
      startMinute: json['startMinute'],
      endHour: json['endHour'],
      endMinute: json['endMinute'],
      room: json['room'] ?? '',
      lecturer: json['lecturer'] ?? '',
      notes: json['notes'] ?? '',
      reminderEnabled: json['reminderEnabled'] ?? true,
      reminderMinutes: json['reminderMinutes'] ?? 30,
      calendarEventId: json['calendarEventId'],
    );
  }
}

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

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  final List<ScheduleItem> schedules = [];
  final List<ReminderItem> reminders = [];

  bool loaded = false;

  Future<void> load() async {
    if (loaded) return;

    final scheduleData =
        await _prefs.getStringList('schedules') ?? [];

    final reminderData =
        await _prefs.getStringList('reminders') ?? [];

    schedules.clear();
    reminders.clear();

    for (final item in scheduleData) {
      schedules.add(
        ScheduleItem.fromJson(
          jsonDecode(item),
        ),
      );
    }

    for (final item in reminderData) {
      reminders.add(
        ReminderItem.fromJson(
          jsonDecode(item),
        ),
      );
    }

    if (schedules.isEmpty && reminders.isEmpty) {
      _createInitialData();
      await _save();
    }

    loaded = true;
    notifyListeners();
  }

  void _createInitialData() {
    schedules.addAll([
      ScheduleItem(
        id: 'schedule-1',
        subject: 'Mobile Programming',
        weekday: 5,
        startHour: 8,
        startMinute: 0,
        endHour: 10,
        endMinute: 30,
        room: 'Lab Komputer 3',
        lecturer: 'Dosen Mobile Programming',
        notes: 'Materi Flutter dan StatefulWidget',
      ),
      ScheduleItem(
        id: 'schedule-2',
        subject: 'Matematika',
        weekday: 5,
        startHour: 10,
        startMinute: 30,
        endHour: 13,
        endMinute: 0,
        room: 'K-502',
        lecturer: 'Dosen Matematika',
        notes: 'Pertemuan rutin',
      ),
      ScheduleItem(
        id: 'schedule-3',
        subject: 'Metpen Komputer',
        weekday: 5,
        startHour: 13,
        startMinute: 30,
        endHour: 16,
        endMinute: 0,
        room: 'D.101',
        lecturer: 'Dosen Metpen',
        notes: 'Metodologi penelitian',
        reminderEnabled: false,
      ),
    ]);

    reminders.add(
      ReminderItem(
        id: 'reminder-1',
        title: 'Tugas Mobile Programming',
        description: 'Deadline pengumpulan tugas',
        dueAt: DateTime.now().add(
          const Duration(days: 1),
        ),
      ),
    );
  }

  Future<void> addSchedule(ScheduleItem item) async {
    schedules.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> updateSchedule(ScheduleItem item) async {
    final index =
    schedules.indexWhere((element) => element.id == item.id);

    if (index != -1) {
      schedules[index] = item;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteSchedule(String id) async {
    schedules.removeWhere(
          (element) => element.id == id,
    );

    await _save();
    notifyListeners();
  }

  Future<void> addReminder(ReminderItem item) async {
    reminders.add(item);
    await _save();
    notifyListeners();
  }

  Future<void> updateReminder(ReminderItem item) async {
    final index =
    reminders.indexWhere((element) => element.id == item.id);

    if (index != -1) {
      reminders[index] = item;
      await _save();
      notifyListeners();
    }
  }

  Future<void> deleteReminder(String id) async {
    reminders.removeWhere(
          (element) => element.id == id,
    );

    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs.setStringList(
      'schedules',
      schedules
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );

    await _prefs.setStringList(
      'reminders',
      reminders
          .map((item) => jsonEncode(item.toJson()))
          .toList(),
    );
  }
}