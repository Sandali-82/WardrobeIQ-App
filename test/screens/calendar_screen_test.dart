import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/models/clothing_item.dart';
import 'package:wardrobe_app/models/outfit.dart';
import 'package:wardrobe_app/models/worn_log.dart';
import 'package:wardrobe_app/repositories/clothing_repository.dart';
import 'package:wardrobe_app/repositories/outfit_repository.dart';
import 'package:wardrobe_app/repositories/worn_log_repository.dart';
import 'package:wardrobe_app/screens/calendar_screen.dart';
import 'package:wardrobe_app/services/reminder_service.dart';

class MockWornLogRepository extends Mock implements WornLogRepository {}

class MockOutfitRepository extends Mock implements OutfitRepository {}

class MockClothingRepository extends Mock implements ClothingRepository {}

class MockReminderService extends Mock implements ReminderService {}

// The default test window is too short for the calendar plus the logged
// outfit card, which causes a RenderFlex overflow. A taller window avoids it.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockWornLogRepository wornRepo;
  late MockOutfitRepository outfitRepo;
  late MockClothingRepository clothingRepo;
  late MockReminderService reminders;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  Outfit makeOutfit(String id, String name, [List<String> ids = const ['a']]) =>
      Outfit(id: id, name: name, itemIds: ids, createdAt: DateTime(2026, 1, 1));

  ClothingItem makeItem(String id, String name) => ClothingItem(
        id: id,
        name: name,
        imageUrl: '',
        category: 'Tops',
        color: 'black',
        season: 'All',
        tags: const [],
      );

  // A log for today, so the selected day (which defaults to today) shows it.
  WornLog makeTodayLog({
    String outfitId = 'o1',
    String outfitName = 'Casual Friday',
  }) =>
      WornLog(
        id: 'log1',
        outfitId: outfitId,
        outfitName: outfitName,
        dateWorn: DateTime.now(),
      );

  Widget wrap() => const MaterialApp(home: CalendarScreen());

  void stubEmptyMonth() {
    when(() => wornRepo.getRange(
            from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => []);
  }

  void stubTodayLog() {
    when(() => wornRepo.getRange(
            from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => [makeTodayLog()]);
    when(() => outfitRepo.getAll())
        .thenAnswer((_) async => [makeOutfit('o1', 'Casual Friday')]);
    when(() => clothingRepo.getAll())
        .thenAnswer((_) async => [makeItem('a', 'White Tee')]);
  }

  setUp(() {
    wornRepo = MockWornLogRepository();
    outfitRepo = MockOutfitRepository();
    clothingRepo = MockClothingRepository();
    reminders = MockReminderService();
    WornLogRepository.instance = wornRepo;
    OutfitRepository.instance = outfitRepo;
    ClothingRepository.instance = clothingRepo;
    ReminderService.instance = reminders;
  });

  testWidgets('shows empty state when no outfit is logged for the day',
      (tester) async {
    stubEmptyMonth();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('No outfit logged for this day.'), findsOneWidget);
    expect(find.text('Log an Outfit'), findsOneWidget);
  });

  testWidgets('shows error message when loading logs fails', (tester) async {
    when(() => wornRepo.getRange(
            from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => throw Exception('Network error'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Network error'), findsOneWidget);
  });

  testWidgets('shows the logged outfit card with a "Wearing today" label',
      (tester) async {
    useTallScreen(tester);
    stubTodayLog();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Wearing today'), findsOneWidget);
    expect(find.text('Casual Friday'), findsOneWidget);
  });

  testWidgets('shows fallback message when the logged outfit no longer exists',
      (tester) async {
    useTallScreen(tester);
    when(() => wornRepo.getRange(
            from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((_) async => [makeTodayLog(outfitId: 'deleted')]);
    when(() => outfitRepo.getAll()).thenAnswer((_) async => []);
    when(() => clothingRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('This outfit no longer exists.'), findsOneWidget);
  });

  testWidgets('shows snackbar when logging an outfit with no outfits built',
      (tester) async {
    stubEmptyMonth();
    when(() => outfitRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log an Outfit'));
    await tester.pumpAndSettle();

    expect(
        find.text('Build an outfit first before logging one.'), findsOneWidget);
    verifyNever(() => wornRepo.log(
        outfitId: any(named: 'outfitId'), dateWorn: any(named: 'dateWorn')));
  });

  testWidgets('logs the picked outfit and schedules a reminder',
      (tester) async {
    stubEmptyMonth();
    when(() => outfitRepo.getAll())
        .thenAnswer((_) async => [makeOutfit('o1', 'Casual Friday')]);
    when(() => wornRepo.log(
            outfitId: any(named: 'outfitId'), dateWorn: any(named: 'dateWorn')))
        .thenAnswer((_) async {});
    when(() => reminders.scheduleOutfitReminder(
            date: any(named: 'date'), outfitName: any(named: 'outfitName')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log an Outfit'));
    await tester.pumpAndSettle();

    // The picker sheet lists outfits by name.
    await tester.tap(find.text('Casual Friday'));
    await tester.pumpAndSettle();

    verify(() => wornRepo.log(outfitId: 'o1', dateWorn: any(named: 'dateWorn')))
        .called(1);
    verify(() => reminders.scheduleOutfitReminder(
        date: any(named: 'date'), outfitName: 'Casual Friday')).called(1);
  });

  testWidgets('removes the log and cancels the reminder after confirming',
      (tester) async {
    useTallScreen(tester);
    stubTodayLog();
    when(() => wornRepo.delete('log1')).thenAnswer((_) async {});
    when(() => reminders.cancelReminderForDate(any()))
        .thenAnswer((_) async {});

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Remove outfit?'), findsOneWidget);

    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    verify(() => wornRepo.delete('log1')).called(1);
    verify(() => reminders.cancelReminderForDate(any())).called(1);
  });

  testWidgets('does not remove the log when cancelled', (tester) async {
    useTallScreen(tester);
    stubTodayLog();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => wornRepo.delete(any()));
    verifyNever(() => reminders.cancelReminderForDate(any()));
  });
}