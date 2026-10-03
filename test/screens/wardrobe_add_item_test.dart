import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wardrobe_app/models/clothing_item.dart';
import 'package:wardrobe_app/repositories/clothing_repository.dart';
import 'package:wardrobe_app/screens/wardrobe_screen.dart';
import 'package:wardrobe_app/services/image_uploader.dart';
import 'package:wardrobe_app/services/photo_picker.dart';
import '../helpers/mock_clothing_repository.dart';

class MockPhotoPicker extends Mock implements PhotoPicker {}

class MockImageUploader extends Mock implements ImageUploader {}

void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

// A 1x1 PNG. The preview has an errorBuilder, so the tests do not depend on
// the bytes decoding successfully.
final photo = PickedPhoto(
  bytes: base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='),
  mimeType: 'image/png',
  path: '/tmp/item.png',
);

ClothingItem makeItem() => ClothingItem(
      id: '1',
      name: 'Blue Shirt',
      imageUrl: '',
      category: 'top',
      color: 'blue',
      season: 'all-season',
      tags: const [],
    );

void main() {
  late MockClothingRepository repo;
  late MockPhotoPicker picker;
  late MockImageUploader uploader;

  setUpAll(() {
    registerFallbackValue(photo);
  });

  setUp(() {
    repo = MockClothingRepository();
    picker = MockPhotoPicker();
    uploader = MockImageUploader();
    ClothingRepository.instance = repo;
    PhotoPicker.instance = picker;
    ImageUploader.instance = uploader;

    when(() => repo.getAll()).thenAnswer((_) async => []);
  });

  // The add item sheet asks for the original size and a quality of 80.
  void stubPick(PhotoSource source, PickedPhoto? result) {
    when(() => picker.pick(source, maxWidth: null, imageQuality: 80))
        .thenAnswer((_) async => result);
  }

  void stubAddSuccess() {
    when(() => repo.add(
          name: any(named: 'name'),
          imageUrl: any(named: 'imageUrl'),
          category: any(named: 'category'),
          color: any(named: 'color'),
          season: any(named: 'season'),
        )).thenAnswer((_) async {});
  }

  Future<void> openSheet(WidgetTester tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(const MaterialApp(home: WardrobeScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> pickFromGallery(WidgetTester tester) async {
    await tester.tap(find.text('Tap to add a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose from gallery'));
    await tester.pumpAndSettle();
  }

  // Field order in the sheet: name, color.
  Future<void> fillText(
    WidgetTester tester, {
    String name = 'Blue Shirt',
    String color = 'blue',
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), name);
    await tester.enterText(find.byType(TextFormField).at(1), color);
  }

  testWidgets('opens the add item sheet from the floating button',
      (tester) async {
    await openSheet(tester);

    expect(find.text('Add Clothing Item'), findsOneWidget);
    expect(find.text('Tap to add a photo'), findsOneWidget);
    expect(find.text('Add Item'), findsOneWidget);
  });

  testWidgets('shows required errors and does not upload when the form is empty',
      (tester) async {
    await openSheet(tester);

    await tester.tap(find.text('Add Item'));
    await tester.pump();

    expect(find.text('Name is required'), findsOneWidget);
    expect(find.text('Color is required'), findsOneWidget);
    verifyNever(() => uploader.upload(any()));
  });

  testWidgets('asks for a photo when the form is valid but no photo is picked',
      (tester) async {
    await openSheet(tester);

    await fillText(tester);
    await tester.tap(find.text('Add Item'));
    await tester.pump();

    expect(find.text('Please add a photo of the item.'), findsOneWidget);
    verifyNever(() => uploader.upload(any()));
  });

  testWidgets('shows a preview after picking a photo from the gallery',
      (tester) async {
    stubPick(PhotoSource.gallery, photo);
    await openSheet(tester);

    await pickFromGallery(tester);

    expect(find.text('Tap to add a photo'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('requests the camera when "Take a photo" is chosen',
      (tester) async {
    stubPick(PhotoSource.camera, null);
    await openSheet(tester);

    await tester.tap(find.text('Tap to add a photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a photo'));
    await tester.pumpAndSettle();

    verify(() => picker.pick(PhotoSource.camera, maxWidth: null, imageQuality: 80))
        .called(1);
  });

  testWidgets('keeps the placeholder when the user cancels the picker',
      (tester) async {
    stubPick(PhotoSource.gallery, null);
    await openSheet(tester);

    await pickFromGallery(tester);

    expect(find.text('Tap to add a photo'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('uploads the photo, saves the item with defaults and refreshes the list',
      (tester) async {
    var loads = 0;
    when(() => repo.getAll()).thenAnswer((_) async {
      loads++;
      return loads == 1 ? [] : [makeItem()];
    });
    stubPick(PhotoSource.gallery, photo);
    when(() => uploader.upload(photo))
        .thenAnswer((_) async => 'https://img.example.com/blue.jpg');
    stubAddSuccess();
    await openSheet(tester);

    await pickFromGallery(tester);
    await fillText(tester, name: '  Blue Shirt  ', color: '  blue  ');
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    verify(() => uploader.upload(photo)).called(1);
    verify(() => repo.add(
          name: 'Blue Shirt',
          imageUrl: 'https://img.example.com/blue.jpg',
          category: 'top',
          color: 'blue',
          season: 'all-season',
        )).called(1);
    expect(find.text('Add Clothing Item'), findsNothing);
    expect(find.text('Blue Shirt'), findsOneWidget);
    expect(loads, 2);
  });

  testWidgets('saves the selected category and season', (tester) async {
    stubPick(PhotoSource.gallery, photo);
    when(() => uploader.upload(photo))
        .thenAnswer((_) async => 'https://img.example.com/dress.jpg');
    stubAddSuccess();
    await openSheet(tester);

    await pickFromGallery(tester);
    await fillText(tester, name: 'Summer Dress', color: 'red');

    // The wardrobe filter chips behind the sheet also contain the text
    // "dress", so pick the last match, which is the dropdown menu item.
    await tester.tap(find.descendant(
      of: find.byType(DropdownButtonFormField<String>).first,
      matching: find.text('top'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('dress').last);
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byType(DropdownButtonFormField<String>).last,
      matching: find.text('all-season'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('summer').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    verify(() => repo.add(
          name: 'Summer Dress',
          imageUrl: 'https://img.example.com/dress.jpg',
          category: 'dress',
          color: 'red',
          season: 'summer',
        )).called(1);
  });

  testWidgets('shows the upload error and does not save when the upload fails',
      (tester) async {
    stubPick(PhotoSource.gallery, photo);
    when(() => uploader.upload(photo)).thenAnswer(
        (_) async => throw Exception('Image upload failed. Please try again.'));
    await openSheet(tester);

    await pickFromGallery(tester);
    await fillText(tester);
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    expect(find.text('Image upload failed. Please try again.'), findsOneWidget);
    expect(find.text('Add Clothing Item'), findsOneWidget);
    verifyNever(() => repo.add(
          name: any(named: 'name'),
          imageUrl: any(named: 'imageUrl'),
          category: any(named: 'category'),
          color: any(named: 'color'),
          season: any(named: 'season'),
        ));
  });

  testWidgets('shows the error and keeps the sheet open when saving fails',
      (tester) async {
    stubPick(PhotoSource.gallery, photo);
    when(() => uploader.upload(photo))
        .thenAnswer((_) async => 'https://img.example.com/blue.jpg');
    when(() => repo.add(
          name: any(named: 'name'),
          imageUrl: any(named: 'imageUrl'),
          category: any(named: 'category'),
          color: any(named: 'color'),
          season: any(named: 'season'),
        )).thenAnswer((_) async => throw Exception('Server error'));
    await openSheet(tester);

    await pickFromGallery(tester);
    await fillText(tester);
    await tester.tap(find.text('Add Item'));
    await tester.pumpAndSettle();

    expect(find.text('Server error'), findsOneWidget);
    expect(find.text('Add Clothing Item'), findsOneWidget);
  });

  testWidgets('shows a spinner on the button while saving, then hides it',
      (tester) async {
    final upload = Completer<String>();
    stubPick(PhotoSource.gallery, photo);
    when(() => uploader.upload(photo)).thenAnswer((_) => upload.future);
    await openSheet(tester);

    await pickFromGallery(tester);
    await fillText(tester);
    await tester.tap(find.text('Add Item'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    upload.completeError(Exception('boom'));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}