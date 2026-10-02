import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/screens/login_screen.dart';
import 'package:wardrobe_app/screens/register_screen.dart';
import 'package:wardrobe_app/repositories/auth_repository.dart';
import '../helpers/mock_auth_repository.dart';

void main() {
  late MockAuthRepository authRepo;

  setUp(() {
    authRepo = MockAuthRepository();
    AuthRepository.instance = authRepo;
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  Future<void> fillAndSubmit(WidgetTester tester, {String email = 'a@b.com', String password = 'pw'}) async {
    await tester.enterText(find.byType(TextFormField).first, email);
    await tester.enterText(find.byType(TextFormField).last, password);
    await tester.tap(find.text('Log In'));
    await tester.pump();
  }

  testWidgets('shows required-field errors and does not call the repository when the form is empty',
      (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Log In'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(() => authRepo.login(any(), any()));
  });

  testWidgets('rejects an email without an @', (tester) async {
    await pumpLogin(tester);

    await fillAndSubmit(tester, email: 'not-an-email');

    expect(find.text('Enter a valid email'), findsOneWidget);
    verifyNever(() => authRepo.login(any(), any()));
  });

  testWidgets('shows the backend error message when login fails', (tester) async {
    when(() => authRepo.login(any(), any()))
        .thenAnswer((_) async => throw Exception('Please confirm your email before logging in.'));
    await pumpLogin(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Please confirm your email before logging in.'), findsOneWidget);
  });

  testWidgets('trims whitespace around the email before calling the repository', (tester) async {
    when(() => authRepo.login(any(), any())).thenAnswer((_) async => throw Exception('stop here'));
    await pumpLogin(tester);

    await fillAndSubmit(tester, email: '  a@b.com  ', password: 'pw');
    await tester.pumpAndSettle();

    verify(() => authRepo.login('a@b.com', 'pw')).called(1);
  });

  testWidgets('shows a loading spinner while the request is in flight, then hides it',
      (tester) async {
    final completer = Completer<Map<String, dynamic>>();
    when(() => authRepo.login(any(), any())).thenAnswer((_) => completer.future);
    await pumpLogin(tester);

    await fillAndSubmit(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(Exception('boom'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('the sign-up link opens the register screen', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text("Don't have an account? Sign up"));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
  });
}