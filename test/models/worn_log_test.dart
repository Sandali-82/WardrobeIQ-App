import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe_app/models/worn_log.dart';

void main() {
  Map<String, dynamic> validJson() => {
        'id': 'log-1',
        'outfitId': 'outfit-1',
        'outfitName': 'Casual Friday',
        'dateWorn': '2026-03-10T20:00:00Z',
      };

  group('WornLog.fromJson', () {
    test('maps the id, outfit id and outfit name', () {
      final log = WornLog.fromJson(validJson());

      expect(log.id, 'log-1');
      expect(log.outfitId, 'outfit-1');
      expect(log.outfitName, 'Casual Friday');
    });

    test('converts a UTC dateWorn to local time', () {
      final log = WornLog.fromJson(validJson());

      expect(log.dateWorn.isUtc, isFalse);
    });

    test('keeps the same moment in time after the local conversion', () {
      final log = WornLog.fromJson(validJson());

      expect(log.dateWorn.isAtSameMomentAs(DateTime.utc(2026, 3, 10, 20)), isTrue);
    });

    test('exposes local year, month and day (used for calendar date keys)', () {
      final log = WornLog.fromJson(validJson());
      final expected = DateTime.utc(2026, 3, 10, 20).toLocal();

      expect(log.dateWorn.year, expected.year);
      expect(log.dateWorn.month, expected.month);
      expect(log.dateWorn.day, expected.day);
    });

    test('treats a timestamp without a zone suffix as local time', () {
      final json = validJson()..['dateWorn'] = '2026-03-10T20:00:00';

      final log = WornLog.fromJson(json);

      expect(log.dateWorn.isUtc, isFalse);
      expect(log.dateWorn.hour, 20);
      expect(log.dateWorn.day, 10);
    });

    test('throws a FormatException when dateWorn is not a valid date', () {
      final json = validJson()..['dateWorn'] = 'not-a-date';

      expect(() => WornLog.fromJson(json), throwsFormatException);
    });

    test('throws when a required field is missing', () {
      final json = validJson()..remove('outfitName');

      expect(() => WornLog.fromJson(json), throwsA(isA<TypeError>()));
    });
  });
}