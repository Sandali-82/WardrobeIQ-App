import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/repositories/profile_repository.dart';
import 'package:wardrobe_app/screens/body_shape_screen.dart';
import 'package:wardrobe_app/services/api_service.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockProfileRepository repo;

  Widget wrap() => const MaterialApp(home: BodyShapeScreen());

  // Field order on the screen: shoulder, bust, waist, hip.
  Future<void> fillForm(WidgetTester tester, List<String> values) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
  }

  void stubCalculate(Future<ShapeResult> Function() answer) {
    when(() => repo.calculateBodyShape(
          shoulderWidth: 40.0,
          bustWidth: 36.5,
          waistWidth: 28.0,
          hipWidth: 38.0,
        )).thenAnswer((_) => answer());
  }

  setUp(() {
    repo = MockProfileRepository();
    ProfileRepository.instance = repo;
  });

  testWidgets('shows required errors when the form is empty', (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Calculate Body Shape'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(4));
  });

  testWidgets('rejects a non-positive measurement', (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['40', '36.5', '0', '38']);
    await tester.tap(find.text('Calculate Body Shape'));
    await tester.pump();

    expect(find.text('Enter a positive number'), findsOneWidget);
  });

  testWidgets('rejects a non-numeric measurement', (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['40', 'abc', '28', '38']);
    await tester.tap(find.text('Calculate Body Shape'));
    await tester.pump();

    expect(find.text('Enter a positive number'), findsOneWidget);
  });

  testWidgets('does not call the repository when validation fails',
      (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Calculate Body Shape'));
    await tester.pump();

    verifyNever(() => repo.calculateBodyShape(
          shoulderWidth: any(named: 'shoulderWidth'),
          bustWidth: any(named: 'bustWidth'),
          waistWidth: any(named: 'waistWidth'),
          hipWidth: any(named: 'hipWidth'),
        ));
  });

  testWidgets('calls the repository with parsed values and shows the result',
      (tester) async {
    useTallScreen(tester);
    stubCalculate(
        () async => (shape: 'hourglass', explanation: 'Balanced bust and hips'));

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['40', '36.5', '28', '38']);
    await tester.tap(find.text('Calculate Body Shape'));
    await tester.pumpAndSettle();

    verify(() => repo.calculateBodyShape(
          shoulderWidth: 40.0,
          bustWidth: 36.5,
          waistWidth: 28.0,
          hipWidth: 38.0,
        )).called(1);
    expect(find.text('HOURGLASS'), findsOneWidget);
    expect(find.text('Balanced bust and hips'), findsOneWidget);
  });

  testWidgets('shows an error message when the calculation fails',
      (tester) async {
    useTallScreen(tester);
    stubCalculate(() async => throw Exception('Server error'));

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['40', '36.5', '28', '38']);
    await tester.tap(find.text('Calculate Body Shape'));
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
    expect(find.text('HOURGLASS'), findsNothing);
  });
}