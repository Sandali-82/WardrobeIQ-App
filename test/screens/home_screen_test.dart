import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/screens/home_screen.dart';
import 'package:wardrobe_app/screens/login_screen.dart';
import '../helpers/home_test_setup.dart';

// All five tabs are built at once inside an IndexedStack, so the default
// test window is too small and causes layout overflows in hidden tabs.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late HomeTestHarness harness;

  setUp(() {
    harness = HomeTestHarness()..install();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
  }

  // Bottom navigation label -> app bar title of the screen it opens.
  const tabs = {
    'Outfits': 'My Outfits',
    'Calendar': 'Outfit Calendar',
    'Suggest': 'AI Outfit Suggestion',
    'Profile': 'My Style Profile',
  };

  testWidgets('shows all five navigation tabs', (tester) async {
    await pumpHome(tester);

    expect(find.text('Wardrobe'), findsOneWidget);
    expect(find.text('Outfits'), findsOneWidget);
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Suggest'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('starts on the wardrobe tab', (tester) async {
    await pumpHome(tester);

    expect(find.text('My Wardrobe'), findsOneWidget);
    expect(find.text('My Outfits'), findsNothing);
  });

  for (final entry in tabs.entries) {
    testWidgets('opens the ${entry.key} tab', (tester) async {
      await pumpHome(tester);

      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();

      expect(find.text(entry.value), findsOneWidget);
      expect(find.text('My Wardrobe'), findsNothing);
    });
  }

  testWidgets('shows the logout button only on the profile tab',
      (tester) async {
    await pumpHome(tester);
    expect(find.byIcon(Icons.logout), findsNothing);

    await tester.tap(find.text('Outfits'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.logout), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.logout), findsOneWidget);

    await tester.tap(find.text('Wardrobe'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.logout), findsNothing);
  });

  testWidgets('logging out clears the session and opens the login screen',
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    verify(() => harness.auth.logout()).called(1);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('loads the data for every tab up front', (tester) async {
    await pumpHome(tester);

    verify(() => harness.clothing.getAll()).called(1);
    verify(() => harness.outfits.getAll()).called(1);
    verify(() => harness.wornLogs.getRange(
        from: any(named: 'from'), to: any(named: 'to'))).called(1);
    verify(() => harness.suggestions.getOccasionTypes()).called(1);
    verify(() => harness.profile.getSavedFaceShape()).called(1);
    verify(() => harness.profile.getSavedBodyShape()).called(1);
    verify(() => harness.profile.getSavedUndertone()).called(1);
  });
}