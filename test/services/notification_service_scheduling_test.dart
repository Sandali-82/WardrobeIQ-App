import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:wardrobe_app/services/notification_service.dart';

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

// Dates are built from the same clock the service uses (tz.local), so the
// tests behave the same on any machine and at any time of day.
DateTime dayFromNow(int days) {
  final d = tz.TZDateTime.now(tz.local).add(Duration(days: days));
  return DateTime(d.year, d.month, d.day);
}

void main() {
  late MockNotificationsPlugin plugin;

  setUpAll(() {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Colombo'));

    registerFallbackValue(tz.TZDateTime.now(tz.local));
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(AndroidScheduleMode.exact);
    registerFallbackValue(UILocalNotificationDateInterpretation.absoluteTime);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    plugin = MockNotificationsPlugin();
    NotificationService.setPluginForTesting(plugin);

    when(() => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        )).thenAnswer((_) async {});
    when(() => plugin.cancel(any())).thenAnswer((_) async {});
    when(() => plugin.cancelAll()).thenAnswer((_) async {});
  });

  // Returns the positional arguments of every zonedSchedule call, in order:
  // [id, title, body, scheduledDate] repeated once per call.
  List<dynamic> capturedSchedules() => verify(() => plugin.zonedSchedule(
        captureAny(),
        captureAny(),
        captureAny(),
        captureAny(),
        any(),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        uiLocalNotificationDateInterpretation:
            any(named: 'uiLocalNotificationDateInterpretation'),
      )).captured;

  void verifyNothingScheduled() {
    verifyNever(() => plugin.zonedSchedule(
          any(),
          any(),
          any(),
          any(),
          any(),
          androidScheduleMode: any(named: 'androidScheduleMode'),
          uiLocalNotificationDateInterpretation:
              any(named: 'uiLocalNotificationDateInterpretation'),
        ));
  }

  group('scheduleOutfitReminder', () {
    test('schedules a reminder for the outfit at 8:00 by default', () async {
      final date = dayFromNow(30);

      await NotificationService.scheduleOutfitReminder(
        date: date,
        outfitName: 'Casual Friday',
      );

      final captured = capturedSchedules();
      expect(captured, hasLength(4));
      expect(captured[0], NotificationService.idForDate(date));
      expect(captured[1], 'Wear this today');
      expect(captured[2], 'Casual Friday');

      final scheduled = captured[3] as tz.TZDateTime;
      expect(scheduled.year, date.year);
      expect(scheduled.month, date.month);
      expect(scheduled.day, date.day);
      expect(scheduled.hour, 8);
      expect(scheduled.minute, 0);
    });

    test('schedules at a custom hour and minute', () async {
      final date = dayFromNow(30);

      await NotificationService.scheduleOutfitReminder(
        date: date,
        outfitName: 'Date Night',
        hour: 18,
        minute: 30,
      );

      final scheduled = capturedSchedules()[3] as tz.TZDateTime;
      expect(scheduled.hour, 18);
      expect(scheduled.minute, 30);
    });

    test('schedules when reminders are explicitly turned on', () async {
      SharedPreferences.setMockInitialValues({'outfitReminderEnabled': true});

      await NotificationService.scheduleOutfitReminder(
        date: dayFromNow(30),
        outfitName: 'Casual Friday',
      );

      expect(capturedSchedules(), hasLength(4));
    });

    test('does not schedule when reminders are turned off in settings',
        () async {
      SharedPreferences.setMockInitialValues({'outfitReminderEnabled': false});

      await NotificationService.scheduleOutfitReminder(
        date: dayFromNow(30),
        outfitName: 'Casual Friday',
      );

      verifyNothingScheduled();
    });

    test('does not schedule a reminder for a date in the past', () async {
      await NotificationService.scheduleOutfitReminder(
        date: dayFromNow(-2),
        outfitName: 'Casual Friday',
      );

      verifyNothingScheduled();
    });

    test('uses the same id when the same day is scheduled twice', () async {
      final date = dayFromNow(30);

      await NotificationService.scheduleOutfitReminder(
        date: date,
        outfitName: 'First choice',
      );
      await NotificationService.scheduleOutfitReminder(
        date: date,
        outfitName: 'Second choice',
      );

      final captured = capturedSchedules();
      expect(captured, hasLength(8));
      expect(captured[0], captured[4]);
      expect(captured[2], 'First choice');
      expect(captured[6], 'Second choice');
    });
  });

  group('cancelling reminders', () {
    test('cancelReminderForDate cancels the notification for that date',
        () async {
      final date = DateTime(2026, 3, 10);

      await NotificationService.cancelReminderForDate(date);

      verify(() => plugin.cancel(20260310)).called(1);
    });

    test('cancelAll cancels every scheduled notification', () async {
      await NotificationService.cancelAll();

      verify(() => plugin.cancelAll()).called(1);
    });
  });
}