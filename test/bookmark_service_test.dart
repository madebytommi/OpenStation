import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_station/models/station.dart';
import 'package:open_station/services/bookmark_service.dart';

void main() {
  group('BookmarkService', () {
    late BookmarkService service;
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

    setUp(() async {
      // Isolate tests using a temporary file
      final directory = Directory.systemTemp.createTempSync('openstation_test');
      tmpFile = File('${directory.path}/bookmarks.json');

      service = BookmarkService();
      service.customStorageFile = tmpFile;
      service.clearMemory();
    });

    tearDown(() async {
      if (tmpFile.existsSync()) {
        tmpFile.deleteSync();
      }
    });

    test(
      'starts with empty list and default volume when file is missing',
      () async {
        await service.init();
        expect(service.bookmarks, isEmpty);
        expect(service.lastVolume, 1.0);
      },
    );

    test('starts with empty list when file is completely empty', () async {
      tmpFile.writeAsStringSync('');
      await service.init();
      expect(service.bookmarks, isEmpty);
    });

    test('adds a bookmark and saves to disk atomically', () async {
      await service.init();
      await service.addBookmark(testStation1);

      expect(service.bookmarks.length, 1);
      expect(service.isBookmarked(testStation1.uuid), isTrue);

      final contents = tmpFile.readAsStringSync();
      final decoded = jsonDecode(contents);
      expect((decoded['bookmarks'] as List).length, 1);
      expect(decoded['bookmarks'][0]['stationuuid'], 'uuid-1');
    });

    test('removes a bookmark and saves to disk', () async {
      await service.init();
      await service.addBookmark(testStation1);
      await service.addBookmark(testStation2);

      await service.removeBookmark('uuid-1');

      expect(service.bookmarks.length, 1);
      expect(service.bookmarks.first.uuid, 'uuid-2');

      final contents = tmpFile.readAsStringSync();
      final decoded = jsonDecode(contents);
      expect((decoded['bookmarks'] as List).length, 1);
      expect(decoded['bookmarks'][0]['stationuuid'], 'uuid-2');
    });

    test('prevents duplicate UUIDs from being added', () async {
      await service.init();
      await service.addBookmark(testStation1);

      // Attempt to add duplicate
      await service.addBookmark(
        const Station(
          uuid: 'uuid-1',
          name: 'Duplicate Name',
          url: 'http://duplicate',
          resolvedUrl: 'http://duplicate',
        ),
      );

      expect(service.bookmarks.length, 1);
      expect(service.bookmarks.first.name, 'Station 1'); // Keeps original
    });

    test('handles corrupted or malformed JSON gracefully', () async {
      // Write garbage to file
      tmpFile.writeAsStringSync('{ corrupted json...]');

      await service.init();

      // Should not throw, should just be empty
      expect(service.bookmarks, isEmpty);

      // Should still be able to save new data
      await service.addBookmark(testStation1);
      expect(service.bookmarks.length, 1);
    });

    test('ignores corrupted station entries but loads valid ones', () async {
      final badData = {
        'volume': 0.5,
        'bookmarks': [
          testStation1.toJson(),
          {'name': 'Missing UUID Station'}, // Invalid format
          testStation2.toJson(),
        ],
      };

      tmpFile.writeAsStringSync(jsonEncode(badData));

      await service.init();

      expect(service.lastVolume, 0.5);
      expect(
        service.bookmarks.length,
        2,
      ); // Station 1 and 2 loaded, bad entry ignored
      expect(service.bookmarks[0].uuid, 'uuid-1');
      expect(service.bookmarks[1].uuid, 'uuid-2');
    });

    test('filters out duplicate UUIDs during initial load', () async {
      final duplicateData = {
        'volume': 1.0,
        'bookmarks': [testStation1.toJson(), testStation1.toJson()],
      };

      tmpFile.writeAsStringSync(jsonEncode(duplicateData));

      await service.init();

      expect(service.bookmarks.length, 1);
      expect(service.bookmarks.first.uuid, 'uuid-1');
    });

    test('saves and clamps volume', () async {
      await service.init();

      await service.setVolume(0.8);
      expect(service.lastVolume, 0.8);

      await service.setVolume(1.5); // Over bounds
      expect(service.lastVolume, 1.0);

      await service.setVolume(-0.5); // Under bounds
      expect(service.lastVolume, 0.0);

      final contents = tmpFile.readAsStringSync();
      final decoded = jsonDecode(contents);
      expect(decoded['volume'], 0.0);
    });
  });
}
