import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/repositories/profile_repository.dart';
import 'package:wardrobe_app/screens/styling_guide_screen.dart';
import 'package:wardrobe_app/services/api_service.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockProfileRepository repo;

  final StylingGuide guide = (
    necklines: 'V-neck tops',
    hairstyles: 'Soft layers',
    sleeves: 'Cap sleeves',
    silhouettes: 'A-line dresses',
    colors: 'Warm earth tones',
    avoid: 'Boxy cuts',
  );

  Widget wrap() => const MaterialApp(home: StylingGuideScreen());

  Future<void> pumpScreen(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  // Taps "Generate", pumps once so the FutureBuilder is built and listening,
  // then fails the pending request. Completing the error only after the
  // listener exists mirrors a real network failure and avoids an unhandled
  // async error in the test.
  Future<void> tapGenerateAndFail(
    WidgetTester tester,
    Completer<StylingGuide> pending,
    String message,
  ) async {
    await tester.tap(find.text('Generate My Styling Guide'));
    await tester.pump();
    pending.completeError(Exception(message));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repo = MockProfileRepository();
    ProfileRepository.instance = repo;
  });

  testWidgets('shows the intro state before generating', (tester) async {
    await pumpScreen(tester);

    expect(find.text('Generate My Styling Guide'), findsOneWidget);
    verifyNever(() => repo.getStylingGuide());
  });

  testWidgets('shows a loading indicator while the guide is generating',
      (tester) async {
    final completer = Completer<StylingGuide>();
    when(() => repo.getStylingGuide()).thenAnswer((_) => completer.future);
    await pumpScreen(tester);

    await tester.tap(find.text('Generate My Styling Guide'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(guide);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows every guide section after generating', (tester) async {
    when(() => repo.getStylingGuide()).thenAnswer((_) async => guide);
    await pumpScreen(tester);

    await tester.tap(find.text('Generate My Styling Guide'));
    await tester.pumpAndSettle();

    expect(find.text('Necklines & Collars'), findsOneWidget);
    expect(find.text('V-neck tops'), findsOneWidget);
    expect(find.text('Hairstyles'), findsOneWidget);
    expect(find.text('Soft layers'), findsOneWidget);
    expect(find.text('Sleeves'), findsOneWidget);
    expect(find.text('Cap sleeves'), findsOneWidget);
    expect(find.text('Silhouettes'), findsOneWidget);
    expect(find.text('A-line dresses'), findsOneWidget);
    expect(find.text('Colors'), findsOneWidget);
    expect(find.text('Warm earth tones'), findsOneWidget);
    expect(find.text('What to Avoid'), findsOneWidget);
    expect(find.text('Boxy cuts'), findsOneWidget);
  });

  testWidgets('shows an error state when generating fails', (tester) async {
    final pending = Completer<StylingGuide>();
    when(() => repo.getStylingGuide()).thenAnswer((_) => pending.future);
    await pumpScreen(tester);

    await tapGenerateAndFail(tester, pending, 'Gemini unavailable');

    expect(find.text('Gemini unavailable'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });

  testWidgets('loads the guide after tapping Try Again', (tester) async {
    final firstAttempt = Completer<StylingGuide>();
    var calls = 0;
    when(() => repo.getStylingGuide()).thenAnswer((_) {
      calls++;
      return calls == 1 ? firstAttempt.future : Future.value(guide);
    });
    await pumpScreen(tester);

    await tapGenerateAndFail(tester, firstAttempt, 'Gemini unavailable');
    await tester.tap(find.text('Try Again'));
    await tester.pumpAndSettle();

    expect(find.text('V-neck tops'), findsOneWidget);
    expect(find.text('Gemini unavailable'), findsNothing);
    verify(() => repo.getStylingGuide()).called(2);
  });

  testWidgets('calls the repository again when Regenerate is tapped',
      (tester) async {
    when(() => repo.getStylingGuide()).thenAnswer((_) async => guide);
    await pumpScreen(tester);

    await tester.tap(find.text('Generate My Styling Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Regenerate'));
    await tester.pumpAndSettle();

    verify(() => repo.getStylingGuide()).called(2);
  });
}