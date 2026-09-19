import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

/// Wraps flutter_local_notifications for the app's "wear this today"
/// outfit reminders. Call [init] once in main() before runApp.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    // If you know the device's IANA timezone name you can set it here with
    // tz.setLocalLocation(tz.getLocation('Asia/Colombo')); otherwise the
    // plugin falls back to the system default via tz.local.

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Android 13+ requires runtime notification permission.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Stable notification id derived from the outfit's date, so scheduling
  /// the same day twice overwrites rather than duplicates, and so it can
  /// be cancelled later just from the date.
  static int idForDate(DateTime date) {
    return int.parse('${date.year}${_pad(date.month)}${_pad(date.day)}');
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');

  /// Schedules a local reminder at [hour]:[minute] on [date] for the given
  /// outfit, unless the user has turned reminders off in Settings.
  static Future<void> scheduleOutfitReminder({
    required DateTime date,
    required String outfitName,
    int hour = 8,
    int minute = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('outfitReminderEnabled') ?? true;
    if (!enabled) return;

    final scheduled = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );

    // Don't schedule reminders for dates already in the past.
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      idForDate(date),
      'Wear this today',
      outfitName,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'outfit_reminders',
          'Outfit Reminders',
          channelDescription: 'Reminders for outfits planned on your calendar',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancels the reminder scheduled for a specific date (e.g. when the
  /// logged outfit for that day is removed).
  static Future<void> cancelReminderForDate(DateTime date) async {
    await _plugin.cancel(idForDate(date));
  }

  /// Cancels every scheduled reminder (e.g. when the user turns the
  /// Settings toggle off).
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}