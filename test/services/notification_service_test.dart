import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/services/notification_service.dart';

void main() {
  group('NotificationService.idForDate', () {
    test('formats the date as yyyyMMdd', () {
      expect(NotificationService.idForDate(DateTime(2026, 11, 25)), 20261125);
    });

    test('pads a single-digit month and day with zeros', () {
      expect(NotificationService.idForDate(DateTime(2026, 3, 5)), 20260305);
    });

    test('handles the first and last day of the year', () {
      expect(NotificationService.idForDate(DateTime(2026, 1, 1)), 20260101);
      expect(NotificationService.idForDate(DateTime(2026, 12, 31)), 20261231);
    });

    test('handles a leap day', () {
      expect(NotificationService.idForDate(DateTime(2028, 2, 29)), 20280229);
    });

    test('ignores the time of day, so one day always maps to one id', () {
      final morning = NotificationService.idForDate(DateTime(2026, 3, 10, 8, 0));
      final night = NotificationService.idForDate(DateTime(2026, 3, 10, 23, 59));

      expect(morning, night);
    });

    test('gives different ids to different days', () {
      final ids = {
        NotificationService.idForDate(DateTime(2026, 3, 10)),
        NotificationService.idForDate(DateTime(2026, 3, 11)),
        NotificationService.idForDate(DateTime(2026, 4, 10)),
        NotificationService.idForDate(DateTime(2027, 3, 10)),
      };

      expect(ids, hasLength(4));
    });

    test('stays within the 32-bit range that notification ids require', () {
      const maxInt32 = 2147483647;

      expect(NotificationService.idForDate(DateTime(9999, 12, 31)),
          lessThanOrEqualTo(maxInt32));
    });
  });
}