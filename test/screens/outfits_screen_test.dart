import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/models/clothing_item.dart';
import 'package:wardrobe_app/models/outfit.dart';
import 'package:wardrobe_app/repositories/clothing_repository.dart';
import 'package:wardrobe_app/repositories/outfit_repository.dart';
import 'package:wardrobe_app/screens/outfits_screen.dart';

class MockOutfitRepository extends Mock implements OutfitRepository {}

class MockClothingRepository extends Mock implements ClothingRepository {}

void main() {
  late MockOutfitRepository outfitRepo;
  late MockClothingRepository clothingRepo;

  Outfit makeOutfit(String id, String name,
          [List<String> ids = const ['a', 'b']]) =>
      Outfit(
        id: id,
        name: name,
        itemIds: ids,
        createdAt: DateTime(2026, 1, 1),
      );

  ClothingItem makeItem(String id, String name) => ClothingItem(
        id: id,
        name: name,
        imageUrl: '',
        category: 'Tops',
        color: 'black',
        season: 'All',
        tags: const [],
      );

  Widget wrap() => const MaterialApp(home: OutfitsScreen());

  setUp(() {
    outfitRepo = MockOutfitRepository();
    clothingRepo = MockClothingRepository();
    OutfitRepository.instance = outfitRepo;
    ClothingRepository.instance = clothingRepo;
  });

  testWidgets('shows empty state when there are no outfits', (tester) async {
    when(() => outfitRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.textContaining('No outfits yet'), findsOneWidget);
  });

  testWidgets('renders the list of outfits', (tester) async {
    when(() => outfitRepo.getAll()).thenAnswer((_) async => [
          makeOutfit('1', 'Casual Friday'),
          makeOutfit('2', 'Date Night', ['a']),
        ]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Casual Friday'), findsOneWidget);
    expect(find.text('Date Night'), findsOneWidget);
    expect(find.text('2 item(s) • tap to view'), findsOneWidget);
    expect(find.text('1 item(s) • tap to view'), findsOneWidget);
  });

  testWidgets('shows error message when loading outfits fails',
      (tester) async {
    when(() => outfitRepo.getAll())
        .thenAnswer((_) async => throw Exception('Network error'));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Network error'), findsOneWidget);
  });

  testWidgets('calls repository delete after confirming', (tester) async {
    when(() => outfitRepo.getAll())
        .thenAnswer((_) async => [makeOutfit('1', 'Casual Friday')]);
    when(() => outfitRepo.delete('1')).thenAnswer((_) async {});

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Delete outfit?'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => outfitRepo.delete('1')).called(1);
  });

  testWidgets('does not call repository delete when cancelled',
      (tester) async {
    when(() => outfitRepo.getAll())
        .thenAnswer((_) async => [makeOutfit('1', 'Casual Friday')]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => outfitRepo.delete(any()));
  });

  testWidgets('shows outfit items in the detail sheet on tap', (tester) async {
    when(() => outfitRepo.getAll()).thenAnswer(
        (_) async => [makeOutfit('1', 'Casual Friday', ['a', 'b'])]);
    when(() => clothingRepo.getAll()).thenAnswer((_) async => [
          makeItem('a', 'White Tee'),
          makeItem('b', 'Blue Jeans'),
          makeItem('c', 'Not In Outfit'),
        ]);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Casual Friday'));
    await tester.pumpAndSettle();

    expect(find.text('White Tee'), findsOneWidget);
    expect(find.text('Blue Jeans'), findsOneWidget);
    expect(find.text('Not In Outfit'), findsNothing);
  });

  testWidgets('shows fallback message when outfit items no longer exist',
      (tester) async {
    when(() => outfitRepo.getAll()).thenAnswer(
        (_) async => [makeOutfit('1', 'Old Outfit', ['x'])]);
    when(() => clothingRepo.getAll()).thenAnswer((_) async => []);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Old Outfit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('None of these items exist'), findsOneWidget);
  });
}