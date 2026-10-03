import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/repositories/auth_repository.dart';
import 'package:wardrobe_app/screens/login_screen.dart';
import 'package:wardrobe_app/screens/register_screen.dart';
import '../helpers/mock_auth_repository.dart';

void main() {
  late MockAuthRepository authRepo;

  setUp(() {
    authRepo = MockAuthRepository();
    AuthRepository.instance = authRepo;
  });

  Future<void> pumpRegister(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
  }

  // Field order on the screen: name, email, password.
  Future<void> fillForm(
    WidgetTester tester, {
    String name = 'Test User',
    String email = 'test@example.com',
    String password = 'secret1',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), name);
    await tester.enterText(find.byType(TextFormField).at(1), email);
    await tester.enterText(find.byType(TextFormField).at(2), password);
  }

  // While the "Check your email" dialog is open, the screen's loading spinner
  // keeps animating (the loading flag is only cleared after the dialog
  // closes), so pumpAndSettle would time out. Pump a fixed number of frames
  // instead: one to run the request and open the dialog, one to finish the
  // dialog animation.
  Future<void> pumpUntilDialogIsOpen(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('shows required-field errors and does not call the repository when empty',
      (tester) async {
    await pumpRegister(tester);

    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    verifyNever(() => authRepo.register(any(), any(), any()));
  });

  testWidgets('rejects an email without an @', (tester) async {
    await pumpRegister(tester);

    await fillForm(tester, email: 'not-an-email');
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
    verifyNever(() => authRepo.register(any(), any(), any()));
  });

  testWidgets('rejects a password shorter than 6 characters', (tester) async {
    await pumpRegister(tester);

    await fillForm(tester, password: 'abc');
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('At least 6 characters'), findsOneWidget);
    verifyNever(() => authRepo.register(any(), any(), any()));
  });

  testWidgets('registers with trimmed values, shows the backend message, then opens login',
      (tester) async {
    when(() => authRepo.register('Test User', 'test@example.com', 'secret1'))
        .thenAnswer((_) async => <String, dynamic>{'message': 'Check your inbox to confirm.'});
    await pumpRegister(tester);

    await fillForm(tester, name: '  Test User  ', email: '  test@example.com  ');
    await tester.tap(find.text('Sign Up'));
    await pumpUntilDialogIsOpen(tester);

    verify(() => authRepo.register('Test User', 'test@example.com', 'secret1')).called(1);
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.text('Check your inbox to confirm.'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(RegisterScreen), findsNothing);
  });

  testWidgets('shows the default message when the backend sends none', (tester) async {
    when(() => authRepo.register(any(), any(), any()))
        .thenAnswer((_) async => <String, dynamic>{});
    await pumpRegister(tester);

    await fillForm(tester);
    await tester.tap(find.text('Sign Up'));
    await pumpUntilDialogIsOpen(tester);

    expect(
      find.text('Registration successful. Please check your email to confirm your account.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the error message and stays on the screen when registration fails',
      (tester) async {
    when(() => authRepo.register(any(), any(), any()))
        .thenAnswer((_) async => throw Exception('Email is already registered'));
    await pumpRegister(tester);

    await fillForm(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('Email is already registered'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
    expect(find.byType(RegisterScreen), findsOneWidget);
  });

  testWidgets('shows a loading spinner while the request is in flight, then hides it',
      (tester) async {
    final completer = Completer<Map<String, dynamic>>();
    when(() => authRepo.register(any(), any(), any()))
        .thenAnswer((_) => completer.future);
    await pumpRegister(tester);

    await fillForm(tester);
    await tester.tap(find.text('Sign Up'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.completeError(Exception('boom'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}