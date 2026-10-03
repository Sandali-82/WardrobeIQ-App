import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/models/clothing_item.dart';

void main() {
  Map<String, dynamic> validJson() => {
        'id': 'item-1',
        'name': 'Blue Shirt',
        'imageUrl': 'https://example.com/shirt.jpg',
        'category': 'top',
        'color': 'blue',
        'season': 'summer',
        'tags': ['casual', 'cotton'],
      };

  group('ClothingItem.fromJson', () {
    test('maps every field from the json', () {
      final item = ClothingItem.fromJson(validJson());

      expect(item.id, 'item-1');
      expect(item.name, 'Blue Shirt');
      expect(item.imageUrl, 'https://example.com/shirt.jpg');
      expect(item.category, 'top');
      expect(item.color, 'blue');
      expect(item.season, 'summer');
      expect(item.tags, ['casual', 'cotton']);
    });

    test('keeps the tags in their original order', () {
      final json = validJson()..['tags'] = ['z-tag', 'a-tag', 'm-tag'];

      final item = ClothingItem.fromJson(json);

      expect(item.tags, ['z-tag', 'a-tag', 'm-tag']);
    });

    test('uses an empty tag list when tags is missing', () {
      final json = validJson()..remove('tags');

      final item = ClothingItem.fromJson(json);

      expect(item.tags, isEmpty);
    });

    test('uses an empty tag list when tags is null', () {
      final json = validJson()..['tags'] = null;

      final item = ClothingItem.fromJson(json);

      expect(item.tags, isEmpty);
    });

    test('throws when a required field is missing', () {
      final json = validJson()..remove('name');

      expect(() => ClothingItem.fromJson(json), throwsA(isA<TypeError>()));
    });

    test('throws when a field has the wrong type', () {
      final json = validJson()..['id'] = 42;

      expect(() => ClothingItem.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}