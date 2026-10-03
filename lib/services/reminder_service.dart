import 'notification_service.dart';

abstract class ReminderService {
  static ReminderService instance = _ReminderServiceImpl();

  Future<void> scheduleOutfitReminder({
    required DateTime date,
    required String outfitName,
  });
  Future<void> cancelReminderForDate(DateTime date);
  Future<void> cancelAll();
}

class _ReminderServiceImpl implements ReminderService {
  @override
  Future<void> scheduleOutfitReminder({
    required DateTime date,
    required String outfitName,
  }) =>
      NotificationService.scheduleOutfitReminder(date: date, outfitName: outfitName);

  @override
  Future<void> cancelReminderForDate(DateTime date) =>
      NotificationService.cancelReminderForDate(date);

  @override
  Future<void> cancelAll() => NotificationService.cancelAll();
}