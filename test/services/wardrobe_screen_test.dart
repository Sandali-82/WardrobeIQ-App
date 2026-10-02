import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/models/clothing_item.dart';
import 'package:wardrobe_app/repositories/clothing_repository.dart';
import 'package:wardrobe_app/screens/wardrobe_screen.dart';
import '../helpers/mock_clothing_repository.dart';

ClothingItem makeItem({
  String id = '1',
  String name = 'Blue Shirt',
  String category = 'top',
  String color = 'blue',
}) =>
    ClothingItem(
      id: id,
      name: name,
      imageUrl: '',
      category: category,
      color: color,
      season: 'all-season',
      tags: const [],
    );

void main() {
  late MockClothingRepository repo;

  setUp(() {
    repo = MockClothingRepository();
    ClothingRepository.instance = repo;
  });

  Future<void> pumpWardrobe(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: WardrobeScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty-wardrobe message when there are no items', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => []);

    await pumpWardrobe(tester);

    expect(find.textContaining('wardrobe is empty'), findsOneWidget);
  });

  testWidgets('renders a card per item with its name and category/color', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => [
          makeItem(id: '1', name: 'Blue Shirt', category: 'top', color: 'blue'),
          makeItem(id: '2', name: 'Black Jeans', category: 'bottom', color: 'black'),
        ]);

    await pumpWardrobe(tester);

    expect(find.text('Blue Shirt'), findsOneWidget);
    expect(find.text('top • blue'), findsOneWidget);
    expect(find.text('Black Jeans'), findsOneWidget);
    expect(find.text('bottom • black'), findsOneWidget);
  });

  testWidgets('shows a network/API error instead of the grid when loading fails', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => throw Exception('Could not reach server.'));

    await pumpWardrobe(tester);

    expect(find.text('Could not reach server.'), findsOneWidget);
  });

  testWidgets('filtering by category chip shows only matching items', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => [
          makeItem(id: '1', name: 'Blue Shirt', category: 'top'),
          makeItem(id: '2', name: 'Black Jeans', category: 'bottom'),
        ]);

    await pumpWardrobe(tester);
    expect(find.text('Blue Shirt'), findsOneWidget);
    expect(find.text('Black Jeans'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'top'));
    await tester.pumpAndSettle();

    expect(find.text('Blue Shirt'), findsOneWidget);
    expect(find.text('Black Jeans'), findsNothing);
  });

  testWidgets('filtering to a category with nothing in it shows the "no items" message',
      (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => [makeItem(category: 'top')]);

    await pumpWardrobe(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'footwear'));
    await tester.pumpAndSettle();

    expect(find.text('No items in this category.'), findsOneWidget);
  });

  testWidgets('long-pressing a card and confirming calls delete and refreshes the list',
      (tester) async {
    var callCount = 0;
    when(() => repo.getAll()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? [makeItem(id: '1', name: 'Blue Shirt')] : [];
    });
    when(() => repo.delete('1')).thenAnswer((_) async {});

    await pumpWardrobe(tester);
    expect(find.text('Blue Shirt'), findsOneWidget);

    await tester.longPress(find.text('Blue Shirt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => repo.delete('1')).called(1);
    expect(find.text('Blue Shirt'), findsNothing);
  });

  testWidgets('tapping Cancel in the delete dialog does not call delete', (tester) async {
    when(() => repo.getAll()).thenAnswer((_) async => [makeItem(id: '1', name: 'Blue Shirt')]);

    await pumpWardrobe(tester);
    await tester.longPress(find.text('Blue Shirt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => repo.delete(any()));
    expect(find.text('Blue Shirt'), findsOneWidget);
  });
}