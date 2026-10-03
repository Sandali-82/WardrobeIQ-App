import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/models/clothing_item.dart';
import 'package:wardrobe_app/repositories/clothing_repository.dart';
import 'package:wardrobe_app/repositories/suggestion_repository.dart';
import 'package:wardrobe_app/screens/suggestion_screen.dart';

class MockSuggestionRepository extends Mock implements SuggestionRepository {}

class MockClothingRepository extends Mock implements ClothingRepository {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockSuggestionRepository suggestions;
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

  Widget wrap() => const MaterialApp(home: SuggestionScreen());

  void stubOccasions() {
    when(() => suggestions.getOccasionTypes())
        .thenAnswer((_) async => ['Casual', 'Work', 'Party']);
  }

  void stubWardrobe() {
    when(() => clothingRepo.getAll()).thenAnswer((_) async => [
          makeItem('a', 'White Tee'),
          makeItem('b', 'Blue Jeans'),
          makeItem('c', 'Not Suggested'),
        ]);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  setUp(() {
    suggestions = MockSuggestionRepository();
    clothingRepo = MockClothingRepository();
    SuggestionRepository.instance = suggestions;
    ClothingRepository.instance = clothingRepo;
  });

  testWidgets('shows a loading indicator while occasion types load',
      (tester) async {
    useTallScreen(tester);
    final completer = Completer<List<String>>();
    when(() => suggestions.getOccasionTypes()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(wrap());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(['Casual', 'Work']);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Casual'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
  });

  testWidgets('shows a chip for every occasion type', (tester) async {
    stubOccasions();

    await pumpScreen(tester);

    expect(find.byType(ChoiceChip), findsNWidgets(3));
    expect(find.text('Casual'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Party'), findsOneWidget);
  });

  testWidgets('shows an error message when occasion types fail to load',
      (tester) async {
    when(() => suggestions.getOccasionTypes())
        .thenAnswer((_) async => throw Exception('Network error'));

    await pumpScreen(tester);

    expect(find.text('Could not load occasion types'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('asks to pick an occasion first and does not call the API',
      (tester) async {
    stubOccasions();
    await pumpScreen(tester);

    await tester.tap(find.text('Get Suggestion'));
    await tester.pump();

    expect(find.text('Pick an occasion first'), findsOneWidget);
    verifyNever(() => suggestions.getSuggestion(
        occasion: any(named: 'occasion'), notes: any(named: 'notes')));
  });

  testWidgets('sends the occasion and trimmed notes, then shows matched items',
      (tester) async {
    stubOccasions();
    stubWardrobe();
    when(() => suggestions.getSuggestion(
          occasion: 'Casual',
          notes: 'outdoor',
        )).thenAnswer((_) async =>
        (itemIds: ['a', 'b'], explanation: 'Wear light layers'));
    await pumpScreen(tester);

    await tester.tap(find.text('Casual'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '  outdoor  ');
    await tester.tap(find.text('Get Suggestion'));
    await tester.pumpAndSettle();

    verify(() => suggestions.getSuggestion(occasion: 'Casual', notes: 'outdoor'))
        .called(1);
    expect(find.text('Wear light layers'), findsOneWidget);
    expect(find.text('White Tee'), findsOneWidget);
    expect(find.text('Blue Jeans'), findsOneWidget);
    expect(find.text('Not Suggested'), findsNothing);
  });

  testWidgets('sends empty notes when none are entered', (tester) async {
    stubOccasions();
    stubWardrobe();
    when(() => suggestions.getSuggestion(occasion: 'Work', notes: ''))
        .thenAnswer((_) async => (itemIds: ['a'], explanation: 'Keep it smart'));
    await pumpScreen(tester);

    await tester.tap(find.text('Work'));
    await tester.pump();
    await tester.tap(find.text('Get Suggestion'));
    await tester.pumpAndSettle();

    verify(() => suggestions.getSuggestion(occasion: 'Work', notes: ''))
        .called(1);
    expect(find.text('Keep it smart'), findsOneWidget);
  });

  testWidgets('shows an error message when the suggestion fails',
      (tester) async {
    stubOccasions();
    stubWardrobe();
    when(() => suggestions.getSuggestion(
          occasion: any(named: 'occasion'),
          notes: any(named: 'notes'),
        )).thenAnswer((_) async => throw Exception('Gemini quota exceeded'));
    await pumpScreen(tester);

    await tester.tap(find.text('Casual'));
    await tester.pump();
    await tester.tap(find.text('Get Suggestion'));
    await tester.pumpAndSettle();

    expect(find.text('Gemini quota exceeded'), findsOneWidget);
    expect(find.text('Suggestion'), findsNothing);
  });

  testWidgets('shows the explanation without item cards when nothing matches',
      (tester) async {
    stubOccasions();
    stubWardrobe();
    when(() => suggestions.getSuggestion(occasion: 'Party', notes: ''))
        .thenAnswer((_) async =>
            (itemIds: ['deleted-item'], explanation: 'Dress up a little'));
    await pumpScreen(tester);

    await tester.tap(find.text('Party'));
    await tester.pump();
    await tester.tap(find.text('Get Suggestion'));
    await tester.pumpAndSettle();

    expect(find.text('Dress up a little'), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });
}