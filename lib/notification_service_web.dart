import 'dart:async';
import 'dart:html' as html;

import 'app_data.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  bool initialized = false;

  final Map<String, Timer> _timers = {};

  Future<void> init() async {
    if (initialized) return;

    try {
      if (html.Notification.permission ==
          'default') {
        await html.Notification.requestPermission();
      }
    } catch (e) {
      print(
        'Gagal meminta izin notifikasi Web: $e',
      );
    }

    initialized = true;
  }

  Future<void> scheduleClass(
      ScheduleItem item,
      ) async {
    if (!initialized) return;

    await cancelSchedule(item.id);

    if (!item.reminderEnabled) return;

    final classDate = item.nextOccurrence();

    DateTime reminderDate = classDate.subtract(
      Duration(
        minutes: item.reminderMinutes,
      ),
    );

    if (reminderDate.isBefore(DateTime.now())) {
      reminderDate = reminderDate.add(
        const Duration(days: 7),
      );
    }

    _scheduleTimer(
      key: '${item.id}-reminder',
      scheduledDate: reminderDate,
      title: 'Jadwal Kuliah',
      body:
      '${item.subject} dimulai ${item.startText}',
      repeatWeekly: true,
    );
  }

  Future<void> scheduleReminder(
      ReminderItem item,
      ) async {
    if (!initialized) return;

    await cancelReminder(item.id);

    if (!item.notificationEnabled) return;

    if (item.dueAt.isBefore(DateTime.now())) {
      return;
    }

    _scheduleTimer(
      key: item.id,
      scheduledDate: item.dueAt,
      title: item.title,
      body: item.description,
      repeatWeekly: false,
    );
  }

  void _scheduleTimer({
    required String key,
    required DateTime scheduledDate,
    required String title,
    required String body,
    required bool repeatWeekly,
  }) {
    final now = DateTime.now();

    Duration difference =
    scheduledDate.difference(now);

    if (difference.isNegative) {
      return;
    }

    _timers[key]?.cancel();

    _timers[key] = Timer(
      difference,
          () {
        _showNotification(
          title: title,
          body: body,
        );

        if (repeatWeekly) {
          final nextDate =
          scheduledDate.add(
            const Duration(days: 7),
          );

          _scheduleTimer(
            key: key,
            scheduledDate: nextDate,
            title: title,
            body: body,
            repeatWeekly: true,
          );
        } else {
          _timers.remove(key);
        }
      },
    );
  }

  void _showNotification({
    required String title,
    required String body,
  }) {
    if (html.Notification.permission !=
        'granted') {
      print(
        'Izin notifikasi Chrome belum diberikan.',
      );
      return;
    }

    try {
      html.Notification(
        title,
        body: body,
        icon: 'icons/Icon-192.png',
      );
    } catch (e) {
      print(
        'Gagal menampilkan notifikasi Web: $e',
      );
    }
  }

  Future<void> cancelSchedule(
      String id,
      ) async {
    final key = '$id-reminder';

    _timers[key]?.cancel();
    _timers.remove(key);
  }

  Future<void> cancelReminder(
      String id,
      ) async {
    _timers[id]?.cancel();
    _timers.remove(id);
  }

  Future<void> rescheduleAll() async {
    if (!initialized) return;

    for (final timer in _timers.values) {
      timer.cancel();
    }

    _timers.clear();

    for (final schedule
    in AppData.instance.schedules) {
      await scheduleClass(schedule);
    }

    for (final reminder
    in AppData.instance.reminders) {
      await scheduleReminder(reminder);
    }
  }
}