import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'app_data.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance =
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool initialized = false;

  Future<void> init() async {
    if (initialized) return;

    tz.initializeTimeZones();

    final timezone =
    await FlutterTimezone.getLocalTimezone();

    tz.setLocalLocation(
      tz.getLocation(timezone.identifier),
    );

    const androidSettings =
    AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
    );

    final android =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.requestNotificationsPermission();

    await android?.requestExactAlarmsPermission();

    initialized = true;
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'schedule_channel',
        'Jadwal dan Pengingat',
        channelDescription:
        'Notifikasi jadwal kuliah dan tugas',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
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

    final scheduledDate =
    tz.TZDateTime.from(
      reminderDate,
      tz.local,
    );

    await _plugin.zonedSchedule(
      id: _idFromString(
        '${item.id}-reminder',
      ),
      title: 'Jadwal Kuliah',
      body:
      '${item.subject} dimulai ${item.startText}',
      scheduledDate: scheduledDate,
      notificationDetails: _details(),
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
      DateTimeComponents.dayOfWeekAndTime,
      payload: item.id,
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

    final scheduledDate =
    tz.TZDateTime.from(
      item.dueAt,
      tz.local,
    );

    await _plugin.zonedSchedule(
      id: _idFromString(item.id),
      title: item.title,
      body: item.description,
      scheduledDate: scheduledDate,
      notificationDetails: _details(),
      androidScheduleMode:
      AndroidScheduleMode.exactAllowWhileIdle,
      payload: item.id,
    );
  }

  Future<void> cancelSchedule(
      String id,
      ) async {
    if (!initialized) return;

    await _plugin.cancel(
      id: _idFromString('$id-reminder'),
    );
  }

  Future<void> cancelReminder(
      String id,
      ) async {
    if (!initialized) return;

    await _plugin.cancel(
      id: _idFromString(id),
    );
  }

  Future<void> rescheduleAll() async {
    if (!initialized) return;

    await _plugin.cancelAll();

    for (final schedule
    in AppData.instance.schedules) {
      await scheduleClass(schedule);
    }

    for (final reminder
    in AppData.instance.reminders) {
      await scheduleReminder(reminder);
    }
  }

  int _idFromString(String value) {
    return value.codeUnits.fold(
      0,
          (previous, element) =>
      (previous * 31 + element) & 0x7fffffff,
    );
  }
}