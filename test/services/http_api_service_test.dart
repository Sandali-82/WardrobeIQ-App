import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardrobe_app/services/http_api_service.dart';

// Matches an Exception whose message is exactly [message].
Matcher throwsMessage(String message) => throwsA(
      isA<Exception>().having((e) => e.toString(), 'message', 'Exception: $message'),
    );

http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, dynamic> bodyOf(http.Request request) =>
    jsonDecode(request.body) as Map<String, dynamic>;

Map<String, dynamic> clothingJson(String id, String name) => {
      'id': id,
      'name': name,
      'imageUrl': 'https://img.example.com/$id.jpg',
      'category': 'top',
      'color': 'blue',
      'season': 'all-season',
      'tags': ['casual'],
    };

Map<String, dynamic> outfitJson(String id, String name) => {
      'id': id,
      'name': name,
      'itemIds': ['a', 'b'],
      'createdAt': '2026-01-15T08:30:00Z',
    };

Map<String, dynamic> wornLogJson(String id, String outfitName) => {
      'id': id,
      'outfitId': 'o1',
      'outfitName': outfitName,
      'dateWorn': '2026-03-10T00:00:00Z',
    };

// Wraps a client so a test can check that it was closed.
class _CloseTrackingClient extends http.BaseClient {
  _CloseTrackingClient(this._inner);

  final http.Client _inner;
  bool closed = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);

  @override
  void close() {
    closed = true;
    _inner.close();
  }
}

void main() {
  late List<http.Request> requests;

  setUp(() {
    requests = [];
    SharedPreferences.setMockInitialValues({});
  });

  // A service whose HTTP client records every request and answers with
  // whatever [respond] returns.
  HttpApiService serviceReturning(
      http.Response Function(http.Request request) respond) {
    return HttpApiService(
      clientFactory: () => MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
  }

  // A service whose HTTP client always fails with [error].
  HttpApiService serviceThrowing(Object error) => HttpApiService(
        clientFactory: () => MockClient((_) async => throw error),
      );

  void saveToken([String token = 'abc']) =>
      SharedPreferences.setMockInitialValues({'token': token});

  group('session storage', () {
    test('reports not logged in when there is no saved token', () async {
      final service = serviceReturning((_) => jsonResponse({}));

      expect(await service.isLoggedIn(), isFalse);
    });

    test('reports logged in when a token is saved', () async {
      saveToken();
      final service = serviceReturning((_) => jsonResponse({}));

      expect(await service.isLoggedIn(), isTrue);
    });

    test('returns empty user info when nothing is saved', () async {
      final service = serviceReturning((_) => jsonResponse({}));

      expect(await service.getSavedUserInfo(), (name: null, email: null));
    });

    test('saves the session received from a deep link', () async {
      final service = serviceReturning((_) => jsonResponse({}));

      await service.saveSessionFromDeepLink(
        token: 'deep-token',
        name: 'Test User',
        email: 'test@example.com',
      );

      expect(await service.isLoggedIn(), isTrue);
      expect(await service.getSavedUserInfo(),
          (name: 'Test User', email: 'test@example.com'));
    });

    test('clearToken removes the token and the cached user info', () async {
      SharedPreferences.setMockInitialValues({
        'token': 'abc',
        'userName': 'Test User',
        'userEmail': 'test@example.com',
      });
      final service = serviceReturning((_) => jsonResponse({}));

      await service.clearToken();

      expect(await service.isLoggedIn(), isFalse);
      expect(await service.getSavedUserInfo(), (name: null, email: null));
    });
  });

  group('auth', () {
    test('register posts the details and returns the response without saving a session',
        () async {
      final service = serviceReturning(
          (_) => jsonResponse({'message': 'Check your email'}, 201));

      final result = await service.register('Test User', 'test@example.com', 'secret1');

      expect(result['message'], 'Check your email');
      expect(requests.single.method, 'POST');
      expect(requests.single.url.toString(),
          '${HttpApiService.baseUrl}/api/auth/register');
      expect(bodyOf(requests.single), {
        'name': 'Test User',
        'email': 'test@example.com',
        'password': 'secret1',
      });
      expect(await service.isLoggedIn(), isFalse);
    });

    test('register surfaces the backend error message', () async {
      final service = serviceReturning(
          (_) => jsonResponse({'message': 'Email is already registered'}, 400));

      await expectLater(
        service.register('Test User', 'test@example.com', 'secret1'),
        throwsMessage('Email is already registered'),
      );
    });

    test('login posts the credentials and saves the token and user info', () async {
      final service = serviceReturning((_) => jsonResponse({
            'token': 'jwt-token',
            'name': 'Test User',
            'email': 'test@example.com',
          }));

      final result = await service.login('test@example.com', 'secret1');

      expect(result['token'], 'jwt-token');
      expect(requests.single.method, 'POST');
      expect(requests.single.url.toString(), '${HttpApiService.baseUrl}/api/auth/login');
      expect(bodyOf(requests.single),
          {'email': 'test@example.com', 'password': 'secret1'});
      expect((await SharedPreferences.getInstance()).getString('token'), 'jwt-token');
      expect(await service.getSavedUserInfo(),
          (name: 'Test User', email: 'test@example.com'));
    });

    test('login does not send a previously saved token', () async {
      saveToken('old-token');
      final service = serviceReturning((_) => jsonResponse({
            'token': 'new-token',
            'name': 'Test User',
            'email': 'test@example.com',
          }));

      await service.login('test@example.com', 'secret1');

      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('login surfaces the backend error and does not save a session', () async {
      final service = serviceReturning(
          (_) => jsonResponse({'message': 'Invalid email or password'}, 401));

      await expectLater(
        service.login('test@example.com', 'wrong'),
        throwsMessage('Invalid email or password'),
      );
      expect(await service.isLoggedIn(), isFalse);
    });

    test('login with a malformed success response fails with a generic message',
        () async {
      final service = serviceReturning((_) => jsonResponse({}));

      await expectLater(
        service.login('test@example.com', 'secret1'),
        throwsMessage('Something went wrong. Please try again.'),
      );
      expect(await service.isLoggedIn(), isFalse);
    });
  });

  group('request plumbing', () {
    test('sends the bearer token and a JSON content type when logged in', () async {
      saveToken('abc');
      final service = serviceReturning((_) => jsonResponse([]));

      await service.getClothingItems();

      expect(requests.single.headers['Authorization'], 'Bearer abc');
      expect(requests.single.headers['Content-Type'], startsWith('application/json'));
    });

    test('sends no Authorization header when there is no token', () async {
      final service = serviceReturning((_) => jsonResponse([]));

      await service.getClothingItems();

      expect(requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('uses the backend message for a non-2xx response', () async {
      final service = serviceReturning(
          (_) => jsonResponse({'message': 'Item not found'}, 404));

      await expectLater(service.getClothingItems(), throwsMessage('Item not found'));
    });

    test('falls back to "Request failed" when the error body has no message',
        () async {
      final service = serviceReturning((_) => jsonResponse({}, 500));

      await expectLater(service.getClothingItems(), throwsMessage('Request failed'));
    });

    test('falls back to "Request failed" when the error body is not an object',
        () async {
      final service = serviceReturning((_) => jsonResponse(['oops'], 500));

      await expectLater(service.getClothingItems(), throwsMessage('Request failed'));
    });

    test('fails with a generic message when the body is not valid JSON', () async {
      final service = serviceReturning((_) => http.Response('not json', 200));

      await expectLater(
        service.getClothingItems(),
        throwsMessage('Something went wrong. Please try again.'),
      );
    });

    test('accepts an empty success body', () async {
      saveToken();
      final service = serviceReturning((_) => http.Response('', 204));

      await service.deleteClothingItem('item-1');

      expect(requests.single.method, 'DELETE');
    });

    test('reports a timeout with a friendly message', () async {
      final service = serviceThrowing(TimeoutException('slow'));

      await expectLater(
        service.getClothingItems(),
        throwsMessage('The server took too long to respond. Please try again.'),
      );
    });

    test('reports a socket error as a connection problem', () async {
      final service = serviceThrowing(const SocketException('no route'));

      await expectLater(
        service.getClothingItems(),
        throwsMessage("Couldn't connect to the server. Check your connection and try again."),
      );
    });

    test('reports an HTTP error as a connection problem', () async {
      final service = serviceThrowing(const HttpException('connection closed'));

      await expectLater(
        service.getClothingItems(),
        throwsMessage("Couldn't connect to the server. Check your connection and try again."),
      );
    });

    test('wraps an unexpected error in a generic message', () async {
      final service = serviceThrowing(ArgumentError('bad'));

      await expectLater(
        service.getClothingItems(),
        throwsMessage('Something went wrong. Please try again.'),
      );
    });

    test('closes the client after a successful request', () async {
      final clients = <_CloseTrackingClient>[];
      final service = HttpApiService(clientFactory: () {
        final client = _CloseTrackingClient(MockClient((_) async => jsonResponse([])));
        clients.add(client);
        return client;
      });

      await service.getClothingItems();

      expect(clients, hasLength(1));
      expect(clients.single.closed, isTrue);
    });

    test('closes the client after a failed request', () async {
      final clients = <_CloseTrackingClient>[];
      final service = HttpApiService(clientFactory: () {
        final client = _CloseTrackingClient(
            MockClient((_) async => jsonResponse({'message': 'Nope'}, 500)));
        clients.add(client);
        return client;
      });

      await expectLater(service.getClothingItems(), throwsA(isA<Exception>()));

      expect(clients.single.closed, isTrue);
    });
  });

  group('clothing items', () {
    test('getClothingItems parses the list', () async {
      final service = serviceReturning((_) =>
          jsonResponse([clothingJson('1', 'Blue Shirt'), clothingJson('2', 'Black Jeans')]));

      final items = await service.getClothingItems();

      expect(requests.single.method, 'GET');
      expect(requests.single.url.toString(),
          '${HttpApiService.baseUrl}/api/clothingitem');
      expect(items.map((i) => i.name), ['Blue Shirt', 'Black Jeans']);
      expect(items.first.tags, ['casual']);
    });

    test('addClothingItem posts every field with an empty tag list by default',
        () async {
      final service = serviceReturning((_) => jsonResponse({}, 201));

      await service.addClothingItem(
        name: 'Blue Shirt',
        imageUrl: 'https://img.example.com/1.jpg',
        category: 'top',
        color: 'blue',
        season: 'summer',
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/clothingitem');
      expect(bodyOf(requests.single), {
        'name': 'Blue Shirt',
        'imageUrl': 'https://img.example.com/1.jpg',
        'category': 'top',
        'color': 'blue',
        'season': 'summer',
        'tags': <String>[],
      });
    });

    test('deleteClothingItem sends a DELETE for the item id', () async {
      final service = serviceReturning((_) => http.Response('', 204));

      await service.deleteClothingItem('item-1');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/api/clothingitem/item-1');
    });
  });

  group('outfits', () {
    test('getOutfits parses the list', () async {
      final service = serviceReturning((_) =>
          jsonResponse([outfitJson('1', 'Casual Friday'), outfitJson('2', 'Date Night')]));

      final outfits = await service.getOutfits();

      expect(requests.single.url.path, '/api/outfit');
      expect(outfits.map((o) => o.name), ['Casual Friday', 'Date Night']);
      expect(outfits.first.itemIds, ['a', 'b']);
    });

    test('createOutfit posts the name and item ids', () async {
      final service = serviceReturning((_) => jsonResponse({}, 201));

      await service.createOutfit(name: 'Casual Friday', itemIds: ['a', 'b']);

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/outfit');
      expect(bodyOf(requests.single), {
        'name': 'Casual Friday',
        'itemIds': ['a', 'b'],
      });
    });

    test('deleteOutfit sends a DELETE for the outfit id', () async {
      final service = serviceReturning((_) => http.Response('', 204));

      await service.deleteOutfit('outfit-1');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/api/outfit/outfit-1');
    });
  });

  group('worn logs', () {
    test('getWornLogs sends zero-padded date-only range parameters', () async {
      final service = serviceReturning((_) => jsonResponse([wornLogJson('1', 'Casual Friday')]));

      final logs = await service.getWornLogs(
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 31),
      );

      expect(requests.single.url.path, '/api/wornlog');
      expect(requests.single.url.queryParameters, {'from': '2026-03-01', 'to': '2026-03-31'});
      expect(logs.single.outfitName, 'Casual Friday');
    });

    test('logWornOutfit sends the outfit id and a date-only value', () async {
      final service = serviceReturning((_) => jsonResponse({}, 201));

      await service.logWornOutfit(
        outfitId: 'o1',
        dateWorn: DateTime(2026, 3, 10, 18, 45),
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/wornlog');
      expect(bodyOf(requests.single), {'outfitId': 'o1', 'dateWorn': '2026-03-10'});
    });

    test('deleteWornLog sends a DELETE for the log id', () async {
      final service = serviceReturning((_) => http.Response('', 204));

      await service.deleteWornLog('log-1');

      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/api/wornlog/log-1');
    });
  });

  group('suggestions', () {
    test('getOccasionTypes returns the list of names', () async {
      final service = serviceReturning((_) => jsonResponse(['Casual', 'Work', 'Party']));

      final types = await service.getOccasionTypes();

      expect(requests.single.url.path, '/api/suggestion/occasion-types');
      expect(types, ['Casual', 'Work', 'Party']);
    });

    test('getSuggestion posts the occasion and notes and maps the result', () async {
      final service = serviceReturning((_) => jsonResponse({
            'suggestedItemIds': ['a', 'b'],
            'explanation': 'Wear light layers',
          }));

      final result = await service.getSuggestion(occasion: 'Casual', notes: 'outdoor');

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/suggestion/occasion');
      expect(bodyOf(requests.single), {'occasion': 'Casual', 'notes': 'outdoor'});
      expect(result.itemIds, ['a', 'b']);
      expect(result.explanation, 'Wear light layers');
    });

    test('getSuggestion leaves the notes out when they are null', () async {
      final service = serviceReturning((_) => jsonResponse({
            'suggestedItemIds': <String>[],
            'explanation': 'Keep it simple',
          }));

      await service.getSuggestion(occasion: 'Work');

      expect(bodyOf(requests.single), {'occasion': 'Work'});
    });

    test('getSuggestion leaves the notes out when they are empty', () async {
      final service = serviceReturning((_) => jsonResponse({
            'suggestedItemIds': <String>[],
            'explanation': 'Keep it simple',
          }));

      await service.getSuggestion(occasion: 'Work', notes: '');

      expect(bodyOf(requests.single), {'occasion': 'Work'});
    });
  });

  group('profile', () {
    test('calculateFaceShape posts the measurements and maps the result', () async {
      final service = serviceReturning((_) => jsonResponse({
            'faceShape': 'oval',
            'explanation': 'Balanced proportions',
          }));

      final result = await service.calculateFaceShape(
        foreheadWidth: 12.5,
        cheekboneWidth: 14,
        jawlineWidth: 11,
        faceLength: 19,
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/profile/face-shape');
      expect(bodyOf(requests.single), {
        'foreheadWidth': 12.5,
        'cheekboneWidth': 14,
        'jawlineWidth': 11,
        'faceLength': 19,
      });
      expect(result, (shape: 'oval', explanation: 'Balanced proportions'));
    });

    test('calculateBodyShape posts the measurements and maps the result', () async {
      final service = serviceReturning((_) => jsonResponse({
            'bodyShape': 'hourglass',
            'explanation': 'Balanced bust and hips',
          }));

      final result = await service.calculateBodyShape(
        shoulderWidth: 40,
        bustWidth: 36.5,
        waistWidth: 28,
        hipWidth: 38,
      );

      expect(requests.single.url.path, '/api/profile/body-shape');
      expect(bodyOf(requests.single), {
        'shoulderWidth': 40,
        'bustWidth': 36.5,
        'waistWidth': 28,
        'hipWidth': 38,
      });
      expect(result, (shape: 'hourglass', explanation: 'Balanced bust and hips'));
    });

    test('getSavedFaceShape returns the saved value', () async {
      final service = serviceReturning((_) => jsonResponse({'faceShape': 'oval'}));

      expect(await service.getSavedFaceShape(), 'oval');
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/api/profile/face-shape');
    });

    test('getSavedFaceShape returns null when the request fails', () async {
      final service = serviceReturning((_) => jsonResponse({'message': 'Not found'}, 404));

      expect(await service.getSavedFaceShape(), isNull);
    });

    test('getSavedBodyShape returns the saved value', () async {
      final service = serviceReturning((_) => jsonResponse({'bodyShape': 'pear'}));

      expect(await service.getSavedBodyShape(), 'pear');
      expect(requests.single.url.path, '/api/profile/body-shape');
    });

    test('getSavedBodyShape returns null when the connection fails', () async {
      final service = serviceThrowing(const SocketException('no route'));

      expect(await service.getSavedBodyShape(), isNull);
    });

    test('analyzeUndertone posts the image and maps the result', () async {
      final service = serviceReturning((_) => jsonResponse({
            'undertone': 'warm',
            'explanation': 'Golden tones',
          }));

      final result = await service.analyzeUndertone(
        imageBase64: 'abc123',
        mimeType: 'image/png',
      );

      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/profile/undertone');
      expect(bodyOf(requests.single), {'imageBase64': 'abc123', 'mimeType': 'image/png'});
      expect(result, (undertone: 'warm', explanation: 'Golden tones'));
    });

    test('getSavedUndertone reads the skinUndertone field', () async {
      final service = serviceReturning((_) => jsonResponse({'skinUndertone': 'cool'}));

      expect(await service.getSavedUndertone(), 'cool');
    });

    test('getSavedUndertone returns null when the request fails', () async {
      final service = serviceReturning((_) => jsonResponse({'message': 'Server error'}, 500));

      expect(await service.getSavedUndertone(), isNull);
    });

    test('getStylingGuide maps all six sections', () async {
      final service = serviceReturning((_) => jsonResponse({
            'necklines': 'V-neck tops',
            'hairstyles': 'Soft layers',
            'sleeves': 'Cap sleeves',
            'silhouettes': 'A-line dresses',
            'colors': 'Warm earth tones',
            'avoid': 'Boxy cuts',
          }));

      final guide = await service.getStylingGuide();

      expect(requests.single.url.path, '/api/profile/styling-guide');
      expect(guide, (
        necklines: 'V-neck tops',
        hairstyles: 'Soft layers',
        sleeves: 'Cap sleeves',
        silhouettes: 'A-line dresses',
        colors: 'Warm earth tones',
        avoid: 'Boxy cuts',
      ));
    });

    test('getStylingGuide surfaces the backend error', () async {
      final service = serviceReturning(
          (_) => jsonResponse({'message': 'Add your face shape first'}, 400));

      await expectLater(service.getStylingGuide(), throwsMessage('Add your face shape first'));
    });
  });

  group('settings', () {
    test('updateProfile patches the details, caches them and returns them', () async {
      final service = serviceReturning((_) => jsonResponse({
            'name': 'New Name',
            'email': 'new@example.com',
          }));

      final result = await service.updateProfile(
        name: 'New Name',
        email: 'new@example.com',
      );

      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.path, '/api/auth/profile');
      expect(bodyOf(requests.single), {'name': 'New Name', 'email': 'new@example.com'});
      expect(result, (name: 'New Name', email: 'new@example.com'));
      expect(await service.getSavedUserInfo(),
          (name: 'New Name', email: 'new@example.com'));
    });

    test('updateProfile sends only the fields that are not empty', () async {
      final service = serviceReturning((_) => jsonResponse({
            'name': 'Old Name',
            'email': 'new@example.com',
          }));

      await service.updateProfile(name: '', email: 'new@example.com');

      expect(bodyOf(requests.single), {'email': 'new@example.com'});
    });

    test('updateProfile surfaces the backend error', () async {
      final service = serviceReturning(
          (_) => jsonResponse({'message': 'Email already in use'}, 400));

      await expectLater(
        service.updateProfile(name: 'New Name', email: 'taken@example.com'),
        throwsMessage('Email already in use'),
      );
    });

    test('changePassword sends a PUT with both passwords', () async {
      final service = serviceReturning((_) => http.Response('', 204));

      await service.changePassword(currentPassword: 'oldpass', newPassword: 'newpass1');

      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/api/auth/change-password');
      expect(bodyOf(requests.single),
          {'currentPassword': 'oldpass', 'newPassword': 'newpass1'});
    });

    test('changePassword surfaces the backend error', () async {
      final service = serviceReturning(
          (_) => jsonResponse({'message': 'Current password is incorrect'}, 400));

      await expectLater(
        service.changePassword(currentPassword: 'wrong', newPassword: 'newpass1'),
        throwsMessage('Current password is incorrect'),
      );
    });
  });
}