import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/daily_habit_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  NotificationDetails _buildNotificationDetails({
    required AndroidNotificationDetails androidDetails,
  }) {
    return NotificationDetails(android: androidDetails);
  }

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  /// Initialize notifications
  Future<void> initNotifications() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  /// Schedule reminder notifikasi
  Future<void> scheduleHabitReminder(
    DailyHabit habit, {
    required TimeOfDay time,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Jika waktu sudah lewat hari ini, jadwalkan untuk besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final dynamic details = _buildNotificationDetails(
      androidDetails: AndroidNotificationDetails(
        'habit_reminder_channel',
        'Pengingat Kebiasaan',
        channelDescription: 'Notifikasi untuk pengingat kebiasaan sehari-hari',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      habit.id.hashCode,
      'Pengingat: ${habit.name}',
      'Saatnya menyelesaikan kebiasaan mu! Streak: ${habit.streak} hari 🔥',
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Show immediate notification
  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'instant_channel',
          'Notifikasi Instan',
          channelDescription: 'Notifikasi instan tanpa dijadwalkan',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    final dynamic details = _buildNotificationDetails(
      androidDetails: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Cancel reminder untuk habit tertentu
  Future<void> cancelReminder(DailyHabit habit) async {
    await flutterLocalNotificationsPlugin.cancel(habit.id.hashCode);
  }

  /// Cancel all reminders
  Future<void> cancelAllReminders() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Schedule daily notifications untuk semua habits
  Future<void> scheduleAllHabitReminders(
    List<DailyHabit> habits, {
    required TimeOfDay defaultTime,
  }) async {
    for (final habit in habits) {
      await scheduleHabitReminder(habit, time: defaultTime);
    }
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
