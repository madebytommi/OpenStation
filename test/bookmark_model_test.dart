import 'package:flutter_test/flutter_test.dart';
import 'package:open_station/models/bookmark.dart';
import 'package:open_station/models/station.dart';

void main() {
  const station = Station(
    uuid: 'station-1',
    name: 'Test Station',
    url: 'http://example.com/original',
    resolvedUrl: 'https://example.com/resolved',
    homepage: 'https://example.com',
    faviconUrl: 'https://example.com/icon.png',
    countryCode: 'US',
    state: 'Tennessee',
    tags: ['rock', 'local'],
    codec: 'MP3',
    bitrate: 128,
    isWorking: true,
  );

  group('Bookmark', () {
    test('serializes and restores the station snapshot and UTC date', () {
      final bookmark = Bookmark(
        station: station,
        bookmarkedAt: DateTime.parse('2026-07-26T18:30:00-05:00'),
      );

      final json = bookmark.toJson();
      final restored = Bookmark.fromJson(json);

      expect(json['station']['stationuuid'], 'station-1');
      expect(json['bookmarkedAt'], '2026-07-26T23:30:00.000Z');
      expect(restored, bookmark);
      expect(restored.bookmarkedAt.isUtc, isTrue);
    });

    test('rejects records with a missing station snapshot', () {
      expect(
        Bookmark.tryFromJson({
          'bookmarkedAt': '2026-07-26T23:30:00.000Z',
        }),
        isNull,
      );
    });

    test('rejects records with a missing or invalid bookmark date', () {
      expect(Bookmark.tryFromJson({'station': station.toJson()}), isNull);
      expect(
        Bookmark.tryFromJson({
          'station': station.toJson(),
          'bookmarkedAt': 'not-a-date',
        }),
        isNull,
      );
    });
  });
}
