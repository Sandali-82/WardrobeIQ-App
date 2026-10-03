import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/repositories/profile_repository.dart';
import 'package:wardrobe_app/screens/undertone_screen.dart';
import 'package:wardrobe_app/services/photo_picker.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockPhotoPicker extends Mock implements PhotoPicker {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  late MockProfileRepository repo;
  late MockPhotoPicker picker;

  // A 1x1 PNG. The screen has an errorBuilder, so the test does not depend
  // on the bytes decoding successfully.
  final photo = PickedPhoto(
    bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='),
    mimeType: 'image/png',
  );

  Widget wrap() => const MaterialApp(home: UndertoneScreen());

  Future<void> pumpScreen(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  Future<void> pickFromGallery(WidgetTester tester, Finder tapTarget) async {
    await tester.tap(tapTarget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
  }

  ElevatedButton analyzeButton(WidgetTester tester) => tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Analyze Undertone'));

  setUp(() {
    repo = MockProfileRepository();
    picker = MockPhotoPicker();
    ProfileRepository.instance = repo;
    PhotoPicker.instance = picker;
  });

  testWidgets('disables the analyze button before a photo is selected',
      (tester) async {
    await pumpScreen(tester);

    expect(find.text('Tap to select a photo'), findsOneWidget);
    expect(analyzeButton(tester).onPressed, isNull);
  });

  testWidgets('shows a preview and enables analyze after picking from gallery',
      (tester) async {
    when(() => picker.pick(PhotoSource.gallery)).thenAnswer((_) async => photo);
    await pumpScreen(tester);

    await pickFromGallery(tester, find.text('Tap to select a photo'));

    expect(find.text('Tap to select a photo'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('requests the camera when "Take a photo" is chosen',
      (tester) async {
    when(() => picker.pick(PhotoSource.camera)).thenAnswer((_) async => null);
    await pumpScreen(tester);

    await tester.tap(find.text('Tap to select a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    verify(() => picker.pick(PhotoSource.camera)).called(1);
  });

  testWidgets('keeps the placeholder when the user cancels the picker',
      (tester) async {
    when(() => picker.pick(PhotoSource.gallery)).thenAnswer((_) async => null);
    await pumpScreen(tester);

    await pickFromGallery(tester, find.text('Tap to select a photo'));

    expect(find.text('Tap to select a photo'), findsOneWidget);
    expect(analyzeButton(tester).onPressed, isNull);
  });

  testWidgets('sends the encoded photo and shows the result', (tester) async {
    when(() => picker.pick(PhotoSource.gallery)).thenAnswer((_) async => photo);
    when(() => repo.analyzeUndertone(
          imageBase64: base64Encode(photo.bytes),
          mimeType: 'image/png',
        )).thenAnswer(
        (_) async => (undertone: 'warm', explanation: 'Golden tones'));
    await pumpScreen(tester);

    await pickFromGallery(tester, find.text('Tap to select a photo'));
    await tester.tap(find.text('Analyze Undertone'));
    await tester.pumpAndSettle();

    verify(() => repo.analyzeUndertone(
          imageBase64: base64Encode(photo.bytes),
          mimeType: 'image/png',
        )).called(1);
    expect(find.text('WARM'), findsOneWidget);
    expect(find.text('Golden tones'), findsOneWidget);
  });

  testWidgets('shows an error message when the analysis fails', (tester) async {
    when(() => picker.pick(PhotoSource.gallery)).thenAnswer((_) async => photo);
    when(() => repo.analyzeUndertone(
          imageBase64: any(named: 'imageBase64'),
          mimeType: any(named: 'mimeType'),
        )).thenAnswer((_) async => throw Exception('Analysis timed out'));
    await pumpScreen(tester);

    await pickFromGallery(tester, find.text('Tap to select a photo'));
    await tester.tap(find.text('Analyze Undertone'));
    await tester.pumpAndSettle();

    expect(find.text('Analysis timed out'), findsOneWidget);
    expect(find.text('WARM'), findsNothing);
  });

  testWidgets('clears the previous result when a new photo is picked',
      (tester) async {
    when(() => picker.pick(PhotoSource.gallery)).thenAnswer((_) async => photo);
    when(() => repo.analyzeUndertone(
          imageBase64: any(named: 'imageBase64'),
          mimeType: any(named: 'mimeType'),
        )).thenAnswer(
        (_) async => (undertone: 'warm', explanation: 'Golden tones'));
    await pumpScreen(tester);

    await pickFromGallery(tester, find.text('Tap to select a photo'));
    await tester.tap(find.text('Analyze Undertone'));
    await tester.pumpAndSettle();
    expect(find.text('WARM'), findsOneWidget);

    await pickFromGallery(tester, find.byType(Image));

    expect(find.text('WARM'), findsNothing);
    expect(find.text('Golden tones'), findsNothing);
  });
}