import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/repositories/profile_repository.dart';
import 'package:wardrobe_app/screens/profile_screen.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockProfileRepository repo;

  Widget wrap() => const MaterialApp(home: ProfileScreen());

  void stubSaved({String? face, String? body, String? undertone}) {
    when(() => repo.getSavedFaceShape()).thenAnswer((_) async => face);
    when(() => repo.getSavedBodyShape()).thenAnswer((_) async => body);
    when(() => repo.getSavedUndertone()).thenAnswer((_) async => undertone);
  }

  setUp(() {
    repo = MockProfileRepository();
    ProfileRepository.instance = repo;
  });

  testWidgets('shows a loading indicator before the data arrives',
      (tester) async {
    useTallScreen(tester);
    stubSaved();

    await tester.pumpWidget(wrap());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows placeholders when nothing has been calculated yet',
      (tester) async {
    useTallScreen(tester);
    stubSaved();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Not calculated yet - tap to add'), findsNWidgets(3));
  });

  testWidgets('shows saved values in uppercase', (tester) async {
    useTallScreen(tester);
    stubSaved(face: 'oval', body: 'hourglass', undertone: 'warm');

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('OVAL'), findsOneWidget);
    expect(find.text('HOURGLASS'), findsOneWidget);
    expect(find.text('WARM'), findsOneWidget);
    expect(find.text('Not calculated yet - tap to add'), findsNothing);
  });

  testWidgets('opens the face shape screen and reloads on return',
      (tester) async {
    useTallScreen(tester);
    stubSaved();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Face Shape'));
    await tester.pumpAndSettle();
    expect(find.text('Face Shape Calculator'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('My Style Profile'), findsOneWidget);
    verify(() => repo.getSavedFaceShape()).called(2);
  });

  testWidgets('opens the body shape screen and reloads on return',
      (tester) async {
    useTallScreen(tester);
    stubSaved();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Body Shape'));
    await tester.pumpAndSettle();
    expect(find.text('Body Shape Calculator'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('My Style Profile'), findsOneWidget);
    verify(() => repo.getSavedBodyShape()).called(2);
  });
}