import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

// ============================================================
// Notification Service — দৈনিক রিমাইন্ডার
// পানি পরীক্ষা / খাবার দেওয়ার সময়
// ============================================================

class NotificationService {
  static const int kWaterReminderId = 1001;
  static const int kFeedReminderId = 1002;
  static const int kFeedReminderIdEvening = 1003;

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ============================================================
  // Initialize Notification Service
  // ============================================================
  static Future<void> init() async {
    if (_initialized) return;

    // Initialize timezone database
    tzdata.initializeTimeZones();

    // Android initialization
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings();

    // Combined settings
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize plugin
    await _plugin.initialize(settings);

    // ============================================================
    // Android 13+ notification permission
    // ============================================================
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // ============================================================
    // Android exact alarm permission
    // ============================================================
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  // ============================================================
  // Schedule Daily Reminder
  // ============================================================
  static Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'aquaguard_reminders',
      'দৈনিক রিমাইন্ডার',
      channelDescription:
      'পানি পরীক্ষা ও খাবার দেওয়ার সময়সূচি মনে করিয়ে দেয়',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // ============================================================
    // Schedule notification
    // ============================================================
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      details,

      // Android exact alarm
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,

      // Repeat every day at the selected time
      matchDateTimeComponents: DateTimeComponents.time,

      // Required by your installed flutter_local_notifications version
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ============================================================
  // Cancel Reminder
  // ============================================================
  static Future<void> cancelReminder(int id) async {
    await init();

    await _plugin.cancel(id);
  }

  // ============================================================
  // Get next occurrence of selected time
  // ============================================================
  static tz.TZDateTime _nextInstanceOfTime(
      int hour,
      int minute,
      ) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's time has already passed,
    // schedule it for tomorrow.
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}