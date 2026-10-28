import 'package:flutter/foundation.dart';

import 'package:device_calendar_plus/device_calendar_plus.dart';

import 'app_data.dart';

class CalendarService {
  CalendarService._();

  static final CalendarService instance =
  CalendarService._();

  final DeviceCalendar _calendar =
      DeviceCalendar.instance;

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final status =
    await _calendar.requestPermissions();

    return status == CalendarPermissionStatus.granted;
  }

  Future<String?> createScheduleEvent(
      ScheduleItem item,
      ) async {
    if (kIsWeb) return null;

    final allowed = await requestPermission();

    if (!allowed) {
      return null;
    }

    final start = item.nextOccurrence();

    final end = DateTime(
      start.year,
      start.month,
      start.day,
      item.endHour,
      item.endMinute,
    );

    try {
      final eventId =
      await _calendar.createEvent(
        title: item.subject,
        startDate: start,
        endDate: end,
        description: item.notes,
        location: item.room,

        recurrenceRule: WeeklyRecurrence(
          daysOfWeek: [
            DayOfWeek.values[item.weekday - 1],
          ],
        ),

        reminders: [
          Duration(
            minutes: item.reminderMinutes,
          ),
        ],
      );

      return eventId;
    } catch (e) {
      debugPrint(
        'Calendar create error: $e',
      );

      return null;
    }
  }

  Future<void> deleteScheduleEvent(
      String? eventId,
      ) async {
    if (kIsWeb || eventId == null) return;

    try {
      await _calendar.deleteEvent(
        instanceId: eventId,
      );
    } catch (e) {
      debugPrint(
        'Calendar delete error: $e',
      );
    }
  }

  Future<void> syncSchedule(
      ScheduleItem item,
      ) async {
    if (kIsWeb) return;

    if (item.calendarEventId != null) {
      await deleteScheduleEvent(
        item.calendarEventId,
      );
    }

    final eventId =
    await createScheduleEvent(item);

    item.calendarEventId = eventId;

    await AppData.instance.updateSchedule(
      item,
    );
  }
}