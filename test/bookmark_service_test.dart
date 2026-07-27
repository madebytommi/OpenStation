import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_station/models/bookmark.dart';
import 'package:open_station/models/station.dart';
import 'package:open_station/services/bookmark_service.dart';

void main() {
  group('BookmarkService', () {
    late BookmarkService service;
    late Directory tmpDirectory;
    late File tmpFile;

    final fixedNow = DateTime.utc(2026, 7, 26, 23, 30);

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

    List<File> corruptStorageFiles() {
      final files = tmpDirectory.listSync().whereType<File>().where((file) {
        final name = file.uri.pathSegments.last;
        return name.startsWith('bookmarks.corrupt-') && name.endsWith('.json');
      }).toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      return files;
    }

    void resetService() {
      service.clearMemory();
      service.customStorageFile = tmpFile;
      service.customNow = () => fixedNow;
    }

    setUp(() {
      tmpDirectory = Directory.systemTemp.createTempSync('openstation_test');
      tmpFile = File('${tmpDirectory.path}/bookmarks.json');

      service = BookmarkService();
      resetService();
    });

    tearDown(() {
      service.clearMemory();
      service.customStorageFile = null;
      if (tmpDirectory.existsSync()) {
        tmpDirectory.deleteSync(recursive: true);
      }
    });

    test(
      'starts with empty bookmarks and default volume when file is missing',
      () async {
        await service.init();

        expect(service.bookmarks, isEmpty);
        expect(service.lastVolume, 1.0);
      },
    );

    test('starts with empty bookmarks when file is empty', () async {
      tmpFile.writeAsStringSync('');

      await service.init();

      expect(service.bookmarks, isEmpty);
      expect(corruptStorageFiles(), isEmpty);
    });

    test('adds a dated bookmark and saves the versioned format', () async {
      await service.init();
      await service.addBookmark(testStation1);

      expect(service.bookmarks, hasLength(1));
      expect(service.bookmarks.first.station, testStation1);
      expect(service.bookmarks.first.bookmarkedAt, fixedNow);
      expect(service.isBookmarked(testStation1.uuid), isTrue);

      final decoded = jsonDecode(tmpFile.readAsStringSync());
      final storedBookmarks = decoded['bookmarks'] as List<dynamic>;
      final storedBookmark = storedBookmarks.single as Map<String, dynamic>;

      expect(decoded['schemaVersion'], BookmarkService.storageSchemaVersion);
      expect(storedBookmark['station']['stationuuid'], 'uuid-1');
      expect(storedBookmark['bookmarkedAt'], fixedNow.toIso8601String());
      expect(storedBookmark.containsKey('stationuuid'), isFalse);
    });

    test('removes a bookmark and saves the new format', () async {
      await service.init();
      await service.addBookmark(testStation1);
      await service.addBookmark(testStation2);

      await service.removeBookmark('uuid-1');

      expect(service.bookmarks, hasLength(1));
      expect(service.bookmarks.first.station.uuid, 'uuid-2');

      final decoded = jsonDecode(tmpFile.readAsStringSync());
      final storedBookmarks = decoded['bookmarks'] as List<dynamic>;
      expect(storedBookmarks, hasLength(1));
      expect(storedBookmarks.first['station']['stationuuid'], 'uuid-2');
    });

    test('prevents duplicate UUIDs and keeps the original record', () async {
      await service.init();
      await service.addBookmark(testStation1);
      final original = service.bookmarks.single;

      service.customNow = () => fixedNow.add(const Duration(days: 1));
      await service.addBookmark(
        const Station(
          uuid: 'uuid-1',
          name: 'Duplicate Name',
          url: 'http://duplicate',
          resolvedUrl: 'http://duplicate',
        ),
      );

      expect(service.bookmarks, hasLength(1));
      expect(service.bookmarks.single, original);
      expect(service.bookmarks.single.station.name, 'Station 1');
      expect(service.bookmarks.single.bookmarkedAt, fixedNow);
    });

    test(
      'loads new-format bookmarks with their original dates and order',
      () async {
        final firstDate = DateTime.utc(2024, 1, 2, 3, 4, 5);
        final secondDate = DateTime.utc(2025, 6, 7, 8, 9, 10);
        final data = {
          'schemaVersion': BookmarkService.storageSchemaVersion,
          'volume': 0.5,
          'bookmarks': [
            Bookmark(station: testStation1, bookmarkedAt: firstDate).toJson(),
            Bookmark(station: testStation2, bookmarkedAt: secondDate).toJson(),
          ],
        };
        tmpFile.writeAsStringSync(jsonEncode(data));

        await service.init();

        expect(service.lastVolume, 0.5);
        expect(service.bookmarks.map((bookmark) => bookmark.station.uuid), [
          'uuid-1',
          'uuid-2',
        ]);
        expect(service.bookmarks[0].bookmarkedAt, firstDate);
        expect(service.bookmarks[1].bookmarkedAt, secondDate);
        expect(corruptStorageFiles(), isEmpty);
      },
    );

    test('migrates station-only bookmarks using the file date', () async {
      final legacyFileDate = DateTime.utc(2023, 4, 5, 6, 7, 8);
      final legacyData = {
        'volume': 0.75,
        'bookmarks': [testStation1.toJson(), testStation2.toJson()],
      };
      tmpFile.writeAsStringSync(jsonEncode(legacyData));
      tmpFile.setLastModifiedSync(legacyFileDate);

      await service.init();

      expect(service.lastVolume, 0.75);
      expect(service.bookmarks.map((bookmark) => bookmark.station.uuid), [
        'uuid-1',
        'uuid-2',
      ]);
      expect(
        service.bookmarks.every(
          (bookmark) => bookmark.bookmarkedAt == legacyFileDate,
        ),
        isTrue,
      );

      final migrated = jsonDecode(tmpFile.readAsStringSync());
      final migratedBookmarks = migrated['bookmarks'] as List<dynamic>;
      expect(migrated['schemaVersion'], BookmarkService.storageSchemaVersion);
      expect(migratedBookmarks[0]['station']['stationuuid'], 'uuid-1');
      expect(
        migratedBookmarks[0]['bookmarkedAt'],
        legacyFileDate.toIso8601String(),
      );
      expect(migratedBookmarks[0].containsKey('stationuuid'), isFalse);
      expect(corruptStorageFiles(), isEmpty);
    });

    test(
      'loads mixed records, skips invalid data, and deduplicates by UUID',
      () async {
        final newDate = DateTime.utc(2026, 1, 1);
        final data = {
          'bookmarks': [
            Bookmark(station: testStation1, bookmarkedAt: newDate).toJson(),
            {'station': testStation2.toJson(), 'bookmarkedAt': 'invalid'},
            testStation2.toJson(),
            testStation1.toJson(),
            {'name': 'Missing UUID Station'},
          ],
        };
        tmpFile.writeAsStringSync(jsonEncode(data));

        await service.init();

        expect(service.bookmarks, hasLength(2));
        expect(service.bookmarks[0].station.uuid, 'uuid-1');
        expect(service.bookmarks[0].bookmarkedAt, newDate);
        expect(service.bookmarks[1].station.uuid, 'uuid-2');
        expect(corruptStorageFiles(), isEmpty);
      },
    );

    test('persists bookmark metadata across a service restart', () async {
      await service.init();
      await service.addBookmark(testStation1);

      resetService();
      await service.init();

      expect(service.bookmarks, hasLength(1));
      expect(service.bookmarks.single.station, testStation1);
      expect(service.bookmarks.single.bookmarkedAt, fixedNow);
    });

    test(
      'quarantines malformed JSON without crashing and preserves its bytes',
      () async {
        const malformedData = '{ corrupted json...]';
        tmpFile.writeAsStringSync(malformedData);

        await service.init();

        expect(service.bookmarks, isEmpty);
        expect(service.lastVolume, 1.0);
        expect(tmpFile.existsSync(), isFalse);

        final recoveryFiles = corruptStorageFiles();
        expect(recoveryFiles, hasLength(1));
        expect(
          recoveryFiles.single.uri.pathSegments.last,
          'bookmarks.corrupt-20260726T233000000Z.json',
        );
        expect(recoveryFiles.single.readAsStringSync(), malformedData);
      },
    );

    test(
      'saves valid data after recovery and reloads it after restart',
      () async {
        tmpFile.writeAsStringSync('{ bad json');
        await service.init();

        await service.addBookmark(testStation1);
        await service.setVolume(0.42);

        final replacement = jsonDecode(tmpFile.readAsStringSync());
        expect(
          replacement['schemaVersion'],
          BookmarkService.storageSchemaVersion,
        );
        expect(replacement['volume'], 0.42);
        expect(replacement['bookmarks'][0]['station']['stationuuid'], 'uuid-1');
        expect(corruptStorageFiles(), hasLength(1));

        resetService();
        await service.init();

        expect(service.bookmarks, hasLength(1));
        expect(service.bookmarks.single.station, testStation1);
        expect(service.bookmarks.single.bookmarkedAt, fixedNow);
        expect(service.lastVolume, 0.42);
      },
    );

    test('uses unique recovery names for repeated corruption', () async {
      tmpFile.writeAsStringSync('{ first bad file');
      await service.init();

      resetService();
      tmpFile.writeAsStringSync('{ second bad file');
      await service.init();

      final recoveryFiles = corruptStorageFiles();
      expect(recoveryFiles, hasLength(2));
      expect(
        recoveryFiles.map((file) => file.uri.pathSegments.last),
        containsAll([
          'bookmarks.corrupt-20260726T233000000Z.json',
          'bookmarks.corrupt-20260726T233000000Z-1.json',
        ]),
      );
      expect(
        recoveryFiles.map((file) => file.readAsStringSync()),
        containsAll(['{ first bad file', '{ second bad file']),
      );
    });

    test('does not quarantine a healthy bookmark file', () async {
      final data = {
        'schemaVersion': BookmarkService.storageSchemaVersion,
        'volume': 0.6,
        'bookmarks': [
          Bookmark(station: testStation1, bookmarkedAt: fixedNow).toJson(),
        ],
      };
      tmpFile.writeAsStringSync(jsonEncode(data));

      await service.init();

      expect(service.bookmarks, hasLength(1));
      expect(service.lastVolume, 0.6);
      expect(tmpFile.existsSync(), isTrue);
      expect(corruptStorageFiles(), isEmpty);
    });

    test(
      'skips one invalid record without quarantining the whole file',
      () async {
        final data = {
          'schemaVersion': BookmarkService.storageSchemaVersion,
          'volume': 0.7,
          'bookmarks': [
            Bookmark(station: testStation1, bookmarkedAt: fixedNow).toJson(),
            {
              'station': {'name': 'Missing UUID'},
              'bookmarkedAt': 'invalid',
            },
            Bookmark(
              station: testStation2,
              bookmarkedAt: fixedNow.add(const Duration(minutes: 1)),
            ).toJson(),
          ],
        };
        tmpFile.writeAsStringSync(jsonEncode(data));

        await service.init();

        expect(service.bookmarks, hasLength(2));
        expect(service.bookmarks.map((bookmark) => bookmark.station.uuid), [
          'uuid-1',
          'uuid-2',
        ]);
        expect(service.lastVolume, 0.7);
        expect(tmpFile.existsSync(), isTrue);
        expect(corruptStorageFiles(), isEmpty);
      },
    );

    test(
      'saves and clamps volume without altering bookmark metadata',
      () async {
        await service.init();
        await service.addBookmark(testStation1);

        await service.setVolume(0.8);
        expect(service.lastVolume, 0.8);

        await service.setVolume(1.5);
        expect(service.lastVolume, 1.0);

        await service.setVolume(-0.5);
        expect(service.lastVolume, 0.0);

        final decoded = jsonDecode(tmpFile.readAsStringSync());
        expect(decoded['volume'], 0.0);
        expect(
          decoded['bookmarks'][0]['bookmarkedAt'],
          fixedNow.toIso8601String(),
        );
      },
    );
  });
}
