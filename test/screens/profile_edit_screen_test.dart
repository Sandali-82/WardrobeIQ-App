import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardrobe_app/repositories/profile_repository.dart';
import 'package:wardrobe_app/screens/profile_edit_screen.dart';
import 'package:wardrobe_app/services/reminder_service.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockReminderService extends Mock implements ReminderService {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockProfileRepository repo;
  late MockReminderService reminders;

  Widget wrap() => const MaterialApp(home: ProfileEditScreen());

  Future<void> pumpScreen(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  // Field order on the screen: name, email, current password,
  // new password, confirm password.
  Finder field(int index) => find.byType(TextFormField).at(index);

  Future<void> enter(WidgetTester tester, int index, String text) =>
      tester.enterText(field(index), text);

  String controllerText(WidgetTester tester, int index) =>
      tester.widget<TextFormField>(field(index)).controller!.text;

  Finder changePasswordButton() =>
      find.widgetWithText(OutlinedButton, 'Change Password');

  setUp(() {
    repo = MockProfileRepository();
    reminders = MockReminderService();
    ProfileRepository.instance = repo;
    ReminderService.instance = reminders;
    SharedPreferences.setMockInitialValues({});
    when(() => repo.getSavedUserInfo()).thenAnswer(
        (_) async => (name: 'Test User', email: 'test@example.com'));
  });

  group('account details', () {
    testWidgets('loads the saved name and email into the form',
        (tester) async {
      await pumpScreen(tester);

      expect(controllerText(tester, 0), 'Test User');
      expect(controllerText(tester, 1), 'test@example.com');
    });

    testWidgets('requires a name', (tester) async {
      await pumpScreen(tester);

      await enter(tester, 0, '');
      await tester.tap(find.text('Save Details'));
      await tester.pump();

      expect(find.text('Name is required'), findsOneWidget);
      verifyNever(() => repo.updateProfile(
          name: any(named: 'name'), email: any(named: 'email')));
    });

    testWidgets('requires an email', (tester) async {
      await pumpScreen(tester);

      await enter(tester, 1, '');
      await tester.tap(find.text('Save Details'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('rejects an email without an @', (tester) async {
      await pumpScreen(tester);

      await enter(tester, 1, 'invalid');
      await tester.tap(find.text('Save Details'));
      await tester.pump();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('saves trimmed details and shows a success message',
        (tester) async {
      when(() => repo.updateProfile(
              name: 'New Name', email: 'new@example.com'))
          .thenAnswer((_) async => (name: 'New Name', email: 'new@example.com'));
      await pumpScreen(tester);

      await enter(tester, 0, '  New Name  ');
      await enter(tester, 1, '  new@example.com  ');
      await tester.tap(find.text('Save Details'));
      await tester.pumpAndSettle();

      verify(() => repo.updateProfile(
          name: 'New Name', email: 'new@example.com')).called(1);
      expect(find.text('Profile updated.'), findsOneWidget);
    });

    testWidgets('shows an error message when saving fails', (tester) async {
      when(() => repo.updateProfile(
              name: any(named: 'name'), email: any(named: 'email')))
          .thenAnswer((_) async => throw Exception('Email already in use'));
      await pumpScreen(tester);

      await tester.tap(find.text('Save Details'));
      await tester.pumpAndSettle();

      expect(find.text('Email already in use'), findsOneWidget);
      expect(find.text('Profile updated.'), findsNothing);
    });
  });

  group('change password', () {
    testWidgets('requires the current and new passwords', (tester) async {
      await pumpScreen(tester);

      await tester.tap(changePasswordButton());
      await tester.pump();

      expect(find.text('Required'), findsNWidgets(2));
      verifyNever(() => repo.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword')));
    });

    testWidgets('rejects a new password shorter than 6 characters',
        (tester) async {
      await pumpScreen(tester);

      await enter(tester, 2, 'oldpass');
      await enter(tester, 3, 'abc');
      await enter(tester, 4, 'abc');
      await tester.tap(changePasswordButton());
      await tester.pump();

      expect(find.text('At least 6 characters'), findsOneWidget);
    });

    testWidgets('rejects a mismatched confirmation', (tester) async {
      await pumpScreen(tester);

      await enter(tester, 2, 'oldpass');
      await enter(tester, 3, 'newpass1');
      await enter(tester, 4, 'newpass2');
      await tester.tap(changePasswordButton());
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('changes the password, shows success and clears the fields',
        (tester) async {
      when(() => repo.changePassword(
              currentPassword: 'oldpass', newPassword: 'newpass1'))
          .thenAnswer((_) async {});
      await pumpScreen(tester);

      await enter(tester, 2, 'oldpass');
      await enter(tester, 3, 'newpass1');
      await enter(tester, 4, 'newpass1');
      await tester.tap(changePasswordButton());
      await tester.pumpAndSettle();

      verify(() => repo.changePassword(
          currentPassword: 'oldpass', newPassword: 'newpass1')).called(1);
      expect(find.text('Password changed.'), findsOneWidget);
      expect(controllerText(tester, 2), isEmpty);
      expect(controllerText(tester, 3), isEmpty);
      expect(controllerText(tester, 4), isEmpty);
    });

    testWidgets('shows an error message when the change fails',
        (tester) async {
      when(() => repo.changePassword(
              currentPassword: any(named: 'currentPassword'),
              newPassword: any(named: 'newPassword')))
          .thenAnswer((_) async => throw Exception('Current password is wrong'));
      await pumpScreen(tester);

      await enter(tester, 2, 'wrongpass');
      await enter(tester, 3, 'newpass1');
      await enter(tester, 4, 'newpass1');
      await tester.tap(changePasswordButton());
      await tester.pumpAndSettle();

      expect(find.text('Current password is wrong'), findsOneWidget);
      expect(find.text('Password changed.'), findsNothing);
    });
  });

  group('notifications', () {
    SwitchListTile reminderSwitch(WidgetTester tester) =>
        tester.widget<SwitchListTile>(find.byType(SwitchListTile));

    testWidgets('reflects a saved "off" preference', (tester) async {
      SharedPreferences.setMockInitialValues({'outfitReminderEnabled': false});
      await pumpScreen(tester);

      expect(reminderSwitch(tester).value, isFalse);
    });

    testWidgets('turning reminders off saves the preference and cancels all',
        (tester) async {
      when(() => reminders.cancelAll()).thenAnswer((_) async {});
      await pumpScreen(tester);
      expect(reminderSwitch(tester).value, isTrue);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('outfitReminderEnabled'), isFalse);
      expect(reminderSwitch(tester).value, isFalse);
      verify(() => reminders.cancelAll()).called(1);
    });

    testWidgets('turning reminders on saves the preference without cancelling',
        (tester) async {
      SharedPreferences.setMockInitialValues({'outfitReminderEnabled': false});
      await pumpScreen(tester);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('outfitReminderEnabled'), isTrue);
      verifyNever(() => reminders.cancelAll());
    });
  });
}