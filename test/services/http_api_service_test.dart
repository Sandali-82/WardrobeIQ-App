import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wardrobe_app/services/http_api_service.dart';

// Injects a MockClient through HttpApiService's clientFactory, so every
// test exercises the real request-building, parsing and error-handling
// code with zero network. A fresh MockClient is returned per call because
// HttpApiService closes the client after each request.
HttpApiService apiWith(Future<http.Response> Function(http.Request) handler) =>
    HttpApiService(clientFactory: () => MockClient(handler));

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('login', () {
    test('saves the token and user info on success', () async {
      late http.Request captured;
      final api = apiWith((req) async {
        captured = req;
        return jsonResponse({
          'token': 'jwt-123',
          'userId': '1',
          'name': 'Sandali',
          'email': 's@example.com',
        });
      });

      final result = await api.login('s@example.com', 'pw');

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/auth/login');
      expect(jsonDecode(captured.body), {'email': 's@example.com', 'password': 'pw'});
      expect(result['token'], 'jwt-123');
      expect(await api.isLoggedIn(), isTrue);
      final info = await api.getSavedUserInfo();
      expect(info.name, 'Sandali');
      expect(info.email, 's@example.com');
    });

    test('surfaces the backend error message and saves no session', () async {
      final api = apiWith(
          (_) async => jsonResponse({'message': 'Invalid email or password.'}, 401));

      await expectLater(
        api.login('a@b.com', 'wrong'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Invalid email or password.'))),
      );
      expect(await api.isLoggedIn(), isFalse);
    });

    test('shows a friendly message when the server returns non-JSON (e.g. a proxy error page)', () async {
      final api = apiWith((_) async => http.Response('<html>Bad Gateway</html>', 502));

      await expectLater(
        api.login('a@b.com', 'pw'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Something went wrong'))),
      );
    });

    test('shows a friendly message when the device cannot reach the server', () async {
      final api = apiWith((_) async => throw const SocketException('no route to host'));

      await expectLater(
        api.login('a@b.com', 'pw'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('connect to the server'))),
      );
    });

    test('shows a friendly message on timeout', () async {
      final api = apiWith((_) async => throw TimeoutException('slow'));

      await expectLater(
        api.login('a@b.com', 'pw'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('took too long'))),
      );
    });
  });

  group('register', () {
    test('returns the backend message and does NOT save a session', () async {
      final api = apiWith((_) async => jsonResponse(
          {'message': 'Registration successful. Please check your email to confirm your account.'}));

      final result = await api.register('New User', 'new@example.com', 'password123');

      expect(result['message'], contains('Registration successful'));
      expect(await api.isLoggedIn(), isFalse);
    });

    test('surfaces the conflict message when the email is already registered', () async {
      final api = apiWith((_) async =>
          jsonResponse({'message': 'An account with this email already exists.'}, 409));

      await expectLater(
        api.register('X', 'taken@example.com', 'password123'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('already exists'))),
      );
    });
  });

  group('authenticated requests', () {
    test('send the saved token as a Bearer header', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-abc'});
      late http.Request captured;
      final api = apiWith((req) async {
        captured = req;
        return jsonResponse([]);
      });

      final items = await api.getClothingItems();

      expect(items, isEmpty);
      expect(captured.headers['Authorization'], 'Bearer jwt-abc');
    });

    test('omit the Authorization header when no token is saved', () async {
      late http.Request captured;
      final api = apiWith((req) async {
        captured = req;
        return jsonResponse([]);
      });

      await api.getClothingItems();

      expect(captured.headers.containsKey('Authorization'), isFalse);
    });

    test('changePassword sends a PUT and copes with an empty 204 response', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-abc'});
      late http.Request captured;
      final api = apiWith((req) async {
        captured = req;
        return http.Response('', 204);
      });

      await api.changePassword(currentPassword: 'old-pw', newPassword: 'new-pw-123');

      expect(captured.method, 'PUT');
      expect(captured.url.path, '/api/auth/change-password');
      expect(jsonDecode(captured.body), {'currentPassword': 'old-pw', 'newPassword': 'new-pw-123'});
    });

    test('changePassword surfaces the backend message when the current password is wrong', () async {
      final api = apiWith((_) async =>
          jsonResponse({'message': 'Current password is incorrect.'}, 400));

      await expectLater(
        api.changePassword(currentPassword: 'x', newPassword: 'new-pw-123'),
        throwsA(predicate((e) => e is Exception && e.toString().contains('Current password is incorrect.'))),
      );
    });
  });

  group('worn logs', () {
    test('query dates are formatted as zero-padded yyyy-MM-dd', () async {
      late http.Request captured;
      final api = apiWith((req) async {
        captured = req;
        return jsonResponse([]);
      });

      await api.getWornLogs(from: DateTime(2026, 6, 5), to: DateTime(2026, 6, 30));

      expect(captured.url.queryParameters, {'from': '2026-06-05', 'to': '2026-06-30'});
    });

    test('logWornOutfit sends the date without a time component', () async {
      late http.Request captured;
      final api = apiWith((req) async {
        captured = req;
        return jsonResponse({});
      });

      await api.logWornOutfit(outfitId: 'outfit-1', dateWorn: DateTime(2026, 9, 3, 18, 45));

      expect(jsonDecode(captured.body), {'outfitId': 'outfit-1', 'dateWorn': '2026-09-03'});
    });
  });

  group('session handling', () {
    test('clearToken removes the token and cached user info', () async {
      final api = apiWith((_) async => jsonResponse(
          {'token': 'jwt-123', 'userId': '1', 'name': 'Sandali', 'email': 's@example.com'}));
      await api.login('s@example.com', 'pw');

      await api.clearToken();

      expect(await api.isLoggedIn(), isFalse);
      final info = await api.getSavedUserInfo();
      expect(info.name, isNull);
      expect(info.email, isNull);
    });

    test('saveSessionFromDeepLink logs the user in without any network call', () async {
      var networkCalls = 0;
      final api = apiWith((_) async {
        networkCalls++;
        return jsonResponse({});
      });

      await api.saveSessionFromDeepLink(token: 'deep-link-jwt', name: 'Sandali', email: 's@example.com');

      expect(await api.isLoggedIn(), isTrue);
      expect(networkCalls, 0);
    });

    test('updateProfile refreshes the cached user info', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-abc', 'userName': 'Old', 'userEmail': 'old@example.com'});
      final api = apiWith((_) async => jsonResponse({'name': 'New Name', 'email': 'new@example.com'}));

      await api.updateProfile(name: 'New Name');

      final info = await api.getSavedUserInfo();
      expect(info.name, 'New Name');
      expect(info.email, 'new@example.com');
    });
  });

  group('saved profile factors', () {
    test('getSavedFaceShape returns null instead of throwing when nothing is saved (404)', () async {
      final api = apiWith((_) async =>
          jsonResponse({'message': 'No face shape calculated yet.'}, 404));

      expect(await api.getSavedFaceShape(), isNull);
    });

    test('getSavedFaceShape returns the saved shape', () async {
      final api = apiWith((_) async => jsonResponse({'faceShape': 'round'}));

      expect(await api.getSavedFaceShape(), 'round');
    });
  });
}