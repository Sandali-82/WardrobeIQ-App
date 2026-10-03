import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/screens/home_screen.dart';
import 'package:wardrobe_app/screens/login_screen.dart';
import 'package:wardrobe_app/screens/startup_router.dart';
import '../helpers/home_test_setup.dart';

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

  Widget wrap() => const MaterialApp(home: StartupRouter());

  testWidgets('shows a loading indicator while the session is being checked',
      (tester) async {
    final completer = Completer<bool>();
    when(() => harness.auth.isLoggedIn()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(wrap());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);

    completer.complete(false);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the login screen when the user is not logged in',
      (tester) async {
    when(() => harness.auth.isLoggedIn()).thenAnswer((_) async => false);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('shows the home screen when the user is logged in',
      (tester) async {
    useTallScreen(tester);
    when(() => harness.auth.isLoggedIn()).thenAnswer((_) async => true);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('falls back to the login screen when the session check fails',
      (tester) async {
    final completer = Completer<bool>();
    when(() => harness.auth.isLoggedIn()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(wrap());
    completer.completeError(Exception('Storage unavailable'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}