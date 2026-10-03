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

class MockWornLogRepository extends Mock implements WornLogRepository {}

class MockOutfitRepository extends Mock implements OutfitRepository {}

class MockClothingRepository extends Mock implements ClothingRepository {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

String monthDay(DateTime d) => '${_months[d.month - 1]} ${d.day}';

void main() {
  late MockWornLogRepository wornRepo;
  late MockOutfitRepository outfitRepo;
  late MockClothingRepository clothingRepo;

  setUpAll(() {
    registerFallbackValue(DateTime(2026, 1, 1));
  });

  setUp(() {
    wornRepo = MockWornLogRepository();
    outfitRepo = MockOutfitRepository();
    clothingRepo = MockClothingRepository();
    WornLogRepository.instance = wornRepo;
    OutfitRepository.instance = outfitRepo;
    ClothingRepository.instance = clothingRepo;

    // Whichever month is requested, it contains one log on the 15th.
    when(() => wornRepo.getRange(from: any(named: 'from'), to: any(named: 'to')))
        .thenAnswer((invocation) async {
      final from = invocation.namedArguments[#from] as DateTime;
      return [
        WornLog(
          id: 'log1',
          outfitId: 'o1',
          outfitName: 'Casual Friday',
          dateWorn: DateTime(from.year, from.month, 15),
        ),
      ];
    });
    when(() => outfitRepo.getAll()).thenAnswer((_) async => [
          Outfit(
            id: 'o1',
            name: 'Casual Friday',
            itemIds: const ['a'],
            createdAt: DateTime(2026, 1, 1),
          ),
        ]);
    when(() => clothingRepo.getAll()).thenAnswer((_) async => [
          ClothingItem(
            id: 'a',
            name: 'White Tee',
            imageUrl: '',
            category: 'Tops',
            color: 'black',
            season: 'All',
            tags: const [],
          ),
        ]);
  });

  Future<void> pumpCalendar(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: CalendarScreen()));
    await tester.pumpAndSettle();
  }

  Future<void> goToPreviousMonth(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
  }

  Future<void> goToNextMonth(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
  }

  Future<void> selectDay(WidgetTester tester, int day) async {
    await tester.tap(find.text('$day'));
    await tester.pumpAndSettle();
  }

  testWidgets('labels a log on a past day as "Worn on <date>"', (tester) async {
    await pumpCalendar(tester);
    final now = DateTime.now();
    // The 15th of the previous month is always before today.
    final pastDay = DateTime(now.year, now.month - 1, 15);

    await goToPreviousMonth(tester);
    await selectDay(tester, 15);

    expect(find.text('Worn on ${monthDay(pastDay)}'), findsOneWidget);
    expect(find.text('Casual Friday'), findsOneWidget);
    expect(find.text('Wearing today'), findsNothing);
  });

  testWidgets('labels a log on a future day as "Planned for <date>"',
      (tester) async {
    await pumpCalendar(tester);
    final now = DateTime.now();
    // The 15th of the next month is always after today.
    final futureDay = DateTime(now.year, now.month + 1, 15);

    await goToNextMonth(tester);
    await selectDay(tester, 15);

    expect(find.text('Planned for ${monthDay(futureDay)}'), findsOneWidget);
    expect(find.text('Casual Friday'), findsOneWidget);
    expect(find.text('Wearing today'), findsNothing);
  });

  testWidgets('shows the empty state when a day without a log is selected',
      (tester) async {
    await pumpCalendar(tester);

    await goToNextMonth(tester);
    await selectDay(tester, 16);

    expect(find.text('No outfit logged for this day.'), findsOneWidget);
    expect(find.text('Log an Outfit'), findsOneWidget);
  });
}