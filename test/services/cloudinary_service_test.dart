import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wardrobe_app/services/cloudinary_service.dart';

void main() {
  late Directory tempDir;
  late File imageFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cloudinary_test_');
    imageFile = File('${tempDir.path}/item.jpg')
      ..writeAsStringSync('fake image bytes');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  http.Response success() => http.Response(
        jsonEncode({'secure_url': 'https://res.example.com/item.jpg'}),
        200,
      );

  group('CloudinaryService.uploadImage', () {
    test('posts a multipart request to the Cloudinary image upload endpoint',
        () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return success();
      });

      await CloudinaryService.uploadImage(imageFile, client: client);

      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.host, 'api.cloudinary.com');
      expect(request.url.path, endsWith('/image/upload'));
      expect(request.headers['content-type'], startsWith('multipart/form-data'));
    });

    test('sends the upload preset and the image file', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return success();
      });

      await CloudinaryService.uploadImage(imageFile, client: client);

      final body = latin1.decode(requests.single.bodyBytes);
      expect(body, contains('name="upload_preset"'));
      expect(body, contains('name="file"'));
      expect(body, contains('filename="item.jpg"'));
      expect(body, contains('fake image bytes'));
    });

    test('returns the hosted image url from the response', () async {
      final client = MockClient((_) async => success());

      final url = await CloudinaryService.uploadImage(imageFile, client: client);

      expect(url, 'https://res.example.com/item.jpg');
    });

    for (final status in [400, 500]) {
      test('throws a friendly error when the upload fails with status $status',
          () async {
        final client = MockClient(
            (_) async => http.Response('{"error":{"message":"bad"}}', status));

        await expectLater(
          CloudinaryService.uploadImage(imageFile, client: client),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            'Exception: Image upload failed. Please try again.',
          )),
        );
      });
    }
  });
}