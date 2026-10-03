import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/models/clothing_item.dart';
import 'package:wardrobe_app/repositories/clothing_repository.dart';
import 'package:wardrobe_app/repositories/outfit_repository.dart';
import 'package:wardrobe_app/screens/outfit_builder_screen.dart';

class MockOutfitRepository extends Mock implements OutfitRepository {}

class MockClothingRepository extends Mock implements ClothingRepository {}

void main() {
  late MockOutfitRepository outfitRepo;
  late MockClothingRepository clothingRepo;

  ClothingItem makeItem(String id, String name) => ClothingItem(
        id: id,
        name: name,
        imageUrl: '',
        category: 'Tops',
        color: 'black',
        season: 'All',
        tags: const [],
      );

  Widget wrap() => const MaterialApp(home: OutfitBuilderScreen());

  setUp(() {
    outfitRepo = MockOutfitRepository();
    clothingRepo = MockClothingRepository();
    OutfitRepository.instance = outfitRepo;
    ClothingRepository.instance = clothingRepo;
  });

  testWidgets('shows message when wardrobe is empty', (tester) async {
    when(() => clothingRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Add some wardrobe items first.'), findsOneWidget);
  });

  testWidgets('updates selected count when items are tapped', (tester) async {
    when(() => clothingRepo.getAll()).thenAnswer(
        (_) async => [makeItem('a', 'White Tee'), makeItem('b', 'Blue Jeans')]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('0 item(s) selected'), findsOneWidget);

    await tester.tap(find.text('White Tee'));
    await tester.pump();
    expect(find.textContaining('1 item(s) selected'), findsOneWidget);

    await tester.tap(find.text('White Tee'));
    await tester.pump();
    expect(find.textContaining('0 item(s) selected'), findsOneWidget);
  });

  testWidgets('shows validation error when name is missing', (tester) async {
    when(() => clothingRepo.getAll())
        .thenAnswer((_) async => [makeItem('a', 'White Tee')]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Outfit'));
    await tester.pump();

    expect(find.text('Give this outfit a name'), findsOneWidget);
    verifyNever(() => outfitRepo.create(
        name: any(named: 'name'), itemIds: any(named: 'itemIds')));
  });

  testWidgets('shows validation error when no item is selected',
      (tester) async {
    when(() => clothingRepo.getAll())
        .thenAnswer((_) async => [makeItem('a', 'White Tee')]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'My Outfit');
    await tester.tap(find.text('Save Outfit'));
    await tester.pump();

    expect(find.text('Select at least one item'), findsOneWidget);
    verifyNever(() => outfitRepo.create(
        name: any(named: 'name'), itemIds: any(named: 'itemIds')));
  });

  testWidgets('calls repository create on valid save', (tester) async {
    when(() => clothingRepo.getAll()).thenAnswer(
        (_) async => [makeItem('a', 'White Tee'), makeItem('b', 'Blue Jeans')]);
    when(() => outfitRepo.create(
            name: any(named: 'name'), itemIds: any(named: 'itemIds')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Casual Friday  ');
    await tester.tap(find.text('White Tee'));
    await tester.tap(find.text('Blue Jeans'));
    await tester.pump();
    await tester.tap(find.text('Save Outfit'));
    await tester.pumpAndSettle();

    verify(() => outfitRepo.create(
        name: 'Casual Friday', itemIds: ['a', 'b'])).called(1);
  });

  testWidgets('shows error message when save fails', (tester) async {
    when(() => clothingRepo.getAll())
        .thenAnswer((_) async => [makeItem('a', 'White Tee')]);
    when(() => outfitRepo.create(
            name: any(named: 'name'), itemIds: any(named: 'itemIds')))
        .thenAnswer((_) async => throw Exception('Server error'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Outfit');
    await tester.tap(find.text('White Tee'));
    await tester.pump();
    await tester.tap(find.text('Save Outfit'));
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
  });
}