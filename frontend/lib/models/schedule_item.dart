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

  // Informasi kelas akademik.
  int? classId;
  String? className;

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
    this.classId,
    this.className,
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

    final date = DateTime(
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

    if (!result.isAfter(now)) {
      result = result.add(const Duration(days: 7));
    }

    return result;
  }

  DateTime occurrenceOn(DateTime date) {
    return DateTime(date.year, date.month, date.day, startHour, startMinute);
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
      'classId': classId,
      'className': className,
    };
  }

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'].toString(),
      subject: json['subject'] ?? '',
      weekday: (json['weekday'] as num).toInt(),
      startHour: (json['startHour'] as num).toInt(),
      startMinute: (json['startMinute'] as num).toInt(),
      endHour: (json['endHour'] as num).toInt(),
      endMinute: (json['endMinute'] as num).toInt(),
      room: json['room'] ?? '',
      lecturer: json['lecturer'] ?? '',
      notes: json['notes'] ?? '',
      reminderEnabled: json['reminderEnabled'] ?? true,
      reminderMinutes: (json['reminderMinutes'] as num?)?.toInt() ?? 30,
      calendarEventId: json['calendarEventId'],
      classId: (json['classId'] as num?)?.toInt(),
      className: json['className'],
    );
  }

  factory ScheduleItem.fromApiJson(Map<String, dynamic> json) {
    final startParts = (json['start_time'] as String).split(':');
    final endParts = (json['end_time'] as String).split(':');

    final reminderValue = json['reminder_enabled'];

    return ScheduleItem(
      id: json['id'].toString(),
      subject: json['subject'] ?? '',
      weekday: (json['weekday'] as num).toInt(),
      startHour: int.parse(startParts[0]),
      startMinute: int.parse(startParts[1]),
      endHour: int.parse(endParts[0]),
      endMinute: int.parse(endParts[1]),
      room: json['room'] ?? '',
      lecturer: json['lecturer'] ?? '',
      notes: json['notes'] ?? '',
      reminderEnabled:
          reminderValue == true || reminderValue == 1 || reminderValue == '1',
      reminderMinutes: (json['reminder_minutes'] as num?)?.toInt() ?? 30,
      calendarEventId: null,
      classId: (json['class_id'] as num?)?.toInt(),
      className: json['class_name']?.toString(),
    );
  }

  Map<String, dynamic> toApiJson() {
    String formatTime(int hour, int minute) {
      return '${hour.toString().padLeft(2, '0')}:'
          '${minute.toString().padLeft(2, '0')}';
    }

    return {
      'class_id': classId,
      'subject': subject,
      'weekday': weekday,
      'start_time': formatTime(startHour, startMinute),
      'end_time': formatTime(endHour, endMinute),
      'room': room,
      'lecturer': lecturer,
      'notes': notes,
      'reminder_enabled': reminderEnabled,
      'reminder_minutes': reminderMinutes,
    };
  }
}
