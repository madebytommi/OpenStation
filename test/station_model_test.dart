import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_station/models/station.dart';

void main() {
  group('Station Model Normalization Tests', () {
    test('Scenario 1: Complete metadata parsing', () {
      const jsonFixture = '''
      {
        "changeuuid": "1e4aa307-6ef0-4444-bdb9-5bee3e26a230",
        "stationuuid": "c76686ca-a8b9-4db9-9839-1470c9599623",
        "name": "102.7 KIIS FM",
        "url": "http://stream.radios.com/live",
        "url_resolved": "https://stream.revma.ihrhls.com/zc185",
        "homepage": "https://kiisfm.iheart.com/",
        "favicon": "https://i.iheart.com/favicon.png",
        "tags": "pop, top 40, rock",
        "countrycode": "US",
        "state": "California",
        "codec": "AAC",
        "bitrate": 128,
        "lastcheckok": 1
      }
      ''';

      final map = jsonDecode(jsonFixture) as Map<String, dynamic>;
      final station = Station.fromJson(map);

      expect(station.uuid, 'c76686ca-a8b9-4db9-9839-1470c9599623');
      expect(station.name, '102.7 KIIS FM');
      expect(station.url, 'http://stream.radios.com/live');
      expect(station.resolvedUrl, 'https://stream.revma.ihrhls.com/zc185');
      expect(station.homepage, 'https://kiisfm.iheart.com/');
      expect(station.faviconUrl, 'https://i.iheart.com/favicon.png');
      expect(station.countryCode, 'US');
      expect(station.state, 'California');
      expect(station.codec, 'AAC');
      expect(station.bitrate, 128);
      expect(station.isWorking, true);
      expect(station.tags, ['pop', 'top 40', 'rock']);
    });

    test('Scenario 2: Missing name defaults to Unknown station', () {
      const jsonFixture = '''
      {
        "stationuuid": "test-uuid-missing-name",
        "name": "   ",
        "url": "http://stream.test/audio",
        "url_resolved": "http://stream.test/audio"
      }
      ''';

      final map = jsonDecode(jsonFixture) as Map<String, dynamic>;
      final station = Station.fromJson(map);

      expect(station.name, 'Unknown station');
    });

    test(
      'Scenario 2b: Explicit null or "null" string in fields does not become literal "null"',
      () {
        const jsonFixture = '''
      {
        "stationuuid": "test-uuid-null-strings",
        "name": "null",
        "homepage": "null",
        "codec": "  ",
        "url": "http://stream.test/audio"
      }
      ''';

        final map = jsonDecode(jsonFixture) as Map<String, dynamic>;
        final station = Station.fromJson(map);

        expect(station.name, 'Unknown station');
        expect(station.homepage, isNull);
        expect(station.codec, isNull);
      },
    );

    test('Scenario 3: Missing codec/bitrate and zero bitrate handling', () {
      const jsonFixture = '''
      {
        "stationuuid": "zero-bitrate-uuid",
        "name": "Zero Bitrate Radio",
        "url": "http://stream.test/audio",
        "codec": "",
        "bitrate": 0
      }
      ''';

      final map = jsonDecode(jsonFixture) as Map<String, dynamic>;
      final station = Station.fromJson(map);

      expect(station.codec, isNull);
      expect(station.bitrate, isNull);
    });

    test('Scenario 4: Unusual Unicode characters', () {
      const jsonFixture = '''
      {
        "stationuuid": "unicode-uuid-123",
        "name": "Radio 📻 - 日本語 - 𝓕𝓪𝓷𝓽𝓪𝓼𝔂 - Émission",
        "url": "https://stream.unicode.org/test",
        "tags": "音楽, 🇯🇵, world classical",
        "state": "東京都"
      }
      ''';

      final map = jsonDecode(jsonFixture) as Map<String, dynamic>;
      final station = Station.fromJson(map);

      expect(station.name, 'Radio 📻 - 日本語 - 𝓕𝓪𝓷𝓽𝓪𝓼𝔂 - Émission');
      expect(station.tags, ['音楽', '🇯🇵', 'world classical']);
      expect(station.state, '東京都');
    });

    test('Scenario 5: Invalid/empty JSON record is handled safely', () {
      expect(Station.tryFromJson({}), isNull);
      expect(
        Station.tryFromJson({'stationuuid': 'abc'}),
        isNull,
      ); // missing URL
      expect(
        Station.tryFromJson({'url': 'http://test.com'}),
        isNull,
      ); // missing UUID
      expect(Station.tryFromJson("not a map"), isNull);
    });
  });
}
