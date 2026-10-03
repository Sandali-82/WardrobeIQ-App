import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/models/outfit.dart';

void main() {
  Map<String, dynamic> validJson() => {
        'id': 'outfit-1',
        'name': 'Casual Friday',
        'itemIds': ['a', 'b', 'c'],
        'createdAt': '2026-01-15T08:30:00Z',
      };

  group('Outfit.fromJson', () {
    test('maps every field from the json', () {
      final outfit = Outfit.fromJson(validJson());

      expect(outfit.id, 'outfit-1');
      expect(outfit.name, 'Casual Friday');
      expect(outfit.itemIds, ['a', 'b', 'c']);
      expect(outfit.createdAt, DateTime.utc(2026, 1, 15, 8, 30));
    });

    test('uses an empty item list when itemIds is missing', () {
      final json = validJson()..remove('itemIds');

      final outfit = Outfit.fromJson(json);

      expect(outfit.itemIds, isEmpty);
    });

    test('uses an empty item list when itemIds is null', () {
      final json = validJson()..['itemIds'] = null;

      final outfit = Outfit.fromJson(json);

      expect(outfit.itemIds, isEmpty);
    });

    test('keeps a UTC timestamp as UTC (no local conversion)', () {
      final outfit = Outfit.fromJson(validJson());

      expect(outfit.createdAt.isUtc, isTrue);
    });

    test('throws a FormatException when createdAt is not a valid date', () {
      final json = validJson()..['createdAt'] = 'not-a-date';

      expect(() => Outfit.fromJson(json), throwsFormatException);
    });

    test('throws when a required field is missing', () {
      final json = validJson()..remove('name');

      expect(() => Outfit.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}