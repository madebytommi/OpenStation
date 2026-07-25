import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_station/models/station.dart';
import 'package:open_station/services/recent_stations_service.dart';

void main() {
  group('RecentStationsService', () {
    late RecentStationsService service;
    late File tmpFile;

    const testStation1 = Station(
      uuid: 'uuid-1',
      name: 'Station 1',
      url: 'http://url1',
      resolvedUrl: 'http://url1',
    );

    const testStation2 = Station(
      uuid: 'uuid-2',
      name: 'Station 2',
      url: 'http://url2',
      resolvedUrl: 'http://url2',
    );

    Station getNumberedStation(int i) {
      return Station(
        uuid: 'uuid-$i',
        name: 'Station $i',
        url: 'http://url$i',
        resolvedUrl: 'http://url$i',
      );
    }

    setUp(() async {
      // Isolate tests using a temporary file
      final directory = Directory.systemTemp.createTempSync(
        'openstation_test_recents',
      );
      tmpFile = File('${directory.path}/recent_stations.json');

      service = RecentStationsService();
      service.customStorageFile = tmpFile;
      service.clearMemory();
    });

    tearDown(() async {
      if (tmpFile.existsSync()) {
        tmpFile.deleteSync();
      }
    });

    test('loads and saves JSON correctly', () async {
      await service.init();
      expect(service.recentStations, isEmpty);

      await service.addRecentStation(testStation1);

      expect(service.recentStations.length, 1);
      expect(service.recentStations.first.uuid, 'uuid-1');

      final contents = tmpFile.readAsStringSync();
      final decoded = jsonDecode(contents);
      expect((decoded['recentStations'] as List).length, 1);
      expect(decoded['recentStations'][0]['stationuuid'], 'uuid-1');
    });

    test('strictly enforces the 10-item limit', () async {
      await service.init();

      for (int i = 1; i <= 15; i++) {
        await service.addRecentStation(getNumberedStation(i));
      }

      // Should only have 10 items
      expect(service.recentStations.length, 10);

      // The most recent is 15, so it should be at the front
      expect(service.recentStations.first.uuid, 'uuid-15');
      // The oldest that survived should be 6
      expect(service.recentStations.last.uuid, 'uuid-6');
    });

    test('successfully bumps duplicates to the front of the list', () async {
      await service.init();

      await service.addRecentStation(testStation1);
      await service.addRecentStation(testStation2);

      // Order: [Station 2, Station 1]
      expect(service.recentStations.length, 2);
      expect(service.recentStations.first.uuid, 'uuid-2');

      // Play station 1 again
      await service.addRecentStation(testStation1);

      // Order: [Station 1, Station 2]
      expect(service.recentStations.length, 2);
      expect(service.recentStations.first.uuid, 'uuid-1');
      expect(service.recentStations[1].uuid, 'uuid-2');
    });

    test(
      'handles a missing or corrupted recent_stations.json file safely without crashing',
      () async {
        // Write garbage to file
        tmpFile.writeAsStringSync('{ corrupted json...]');

        await service.init();

        // Should not throw, should just be empty
        expect(service.recentStations, isEmpty);

        // Should still be able to save new data
        await service.addRecentStation(testStation1);
        expect(service.recentStations.length, 1);
      },
    );

    test(
      'ignores corrupted station entries but loads valid ones up to 10',
      () async {
        final badData = {
          'recentStations': [
            testStation1.toJson(),
            {'name': 'Missing UUID Station'}, // Invalid format
            testStation2.toJson(),
            ...List.generate(10, (i) => getNumberedStation(i + 10).toJson()),
          ],
        };

        tmpFile.writeAsStringSync(jsonEncode(badData));

        await service.init();

        // 1 valid + 1 valid + 10 valid = 12 total. Limit should enforce 10.
        expect(service.recentStations.length, 10);
        // First one should be testStation1
        expect(service.recentStations.first.uuid, 'uuid-1');
        // 2nd is testStation2
        expect(service.recentStations[1].uuid, 'uuid-2');
      },
    );
  });
}
