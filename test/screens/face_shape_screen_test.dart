import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/repositories/profile_repository.dart';
import 'package:wardrobe_app/screens/face_shape_screen.dart';
import 'package:wardrobe_app/services/api_service.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockProfileRepository repo;

  Widget wrap() => const MaterialApp(home: FaceShapeScreen());

  // Field order on the screen: forehead, cheekbone, jawline, face length.
  Future<void> fillForm(WidgetTester tester, List<String> values) async {
    for (var i = 0; i < values.length; i++) {
      await tester.enterText(find.byType(TextFormField).at(i), values[i]);
    }
  }

  void stubCalculate(Future<ShapeResult> Function() answer) {
    when(() => repo.calculateFaceShape(
          foreheadWidth: 12.5,
          cheekboneWidth: 14.0,
          jawlineWidth: 11.0,
          faceLength: 19.0,
        )).thenAnswer((_) => answer());
  }

  setUp(() {
    repo = MockProfileRepository();
    ProfileRepository.instance = repo;
  });

  testWidgets('shows required errors when the form is empty', (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Calculate Face Shape'));
    await tester.pump();

    expect(find.text('Required'), findsNWidgets(4));
  });

  testWidgets('rejects a non-positive measurement', (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['-5', '14', '11', '19']);
    await tester.tap(find.text('Calculate Face Shape'));
    await tester.pump();

    expect(find.text('Enter a positive number'), findsOneWidget);
  });

  testWidgets('rejects a non-numeric measurement', (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['abc', '14', '11', '19']);
    await tester.tap(find.text('Calculate Face Shape'));
    await tester.pump();

    expect(find.text('Enter a positive number'), findsOneWidget);
  });

  testWidgets('does not call the repository when validation fails',
      (tester) async {
    useTallScreen(tester);

    await tester.pumpWidget(wrap());
    await tester.tap(find.text('Calculate Face Shape'));
    await tester.pump();

    verifyNever(() => repo.calculateFaceShape(
          foreheadWidth: any(named: 'foreheadWidth'),
          cheekboneWidth: any(named: 'cheekboneWidth'),
          jawlineWidth: any(named: 'jawlineWidth'),
          faceLength: any(named: 'faceLength'),
        ));
  });

  testWidgets('calls the repository with parsed values and shows the result',
      (tester) async {
    useTallScreen(tester);
    stubCalculate(() async => (shape: 'oval', explanation: 'Balanced proportions'));

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['12.5', '14', '11', '19']);
    await tester.tap(find.text('Calculate Face Shape'));
    await tester.pumpAndSettle();

    verify(() => repo.calculateFaceShape(
          foreheadWidth: 12.5,
          cheekboneWidth: 14.0,
          jawlineWidth: 11.0,
          faceLength: 19.0,
        )).called(1);
    expect(find.text('OVAL'), findsOneWidget);
    expect(find.text('Balanced proportions'), findsOneWidget);
  });

  testWidgets('shows an error message when the calculation fails',
      (tester) async {
    useTallScreen(tester);
    stubCalculate(() async => throw Exception('Server error'));

    await tester.pumpWidget(wrap());
    await fillForm(tester, ['12.5', '14', '11', '19']);
    await tester.tap(find.text('Calculate Face Shape'));
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
    expect(find.text('OVAL'), findsNothing);
  });
}