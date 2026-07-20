import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:open_station/services/radio_browser_service.dart';

void main() {
  group('RadioBrowserService Unit Tests', () {
    test('Successful popular stations request', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/json/stations/search') {
          return http.Response(
            jsonEncode([
              {
                'stationuuid': '123-abc',
                'name': 'Jazz FM',
                'url_resolved': 'http://jazz.stream',
              },
            ]),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);

      final results = await service.getPopularStations();
      expect(results.length, 1);
      expect(results.first['name'], 'Jazz FM');
      expect(results.first['stationuuid'], '123-abc');
    });

    test('Successful station name search', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['name'], 'BBC');
        return http.Response(
          jsonEncode([
            {'stationuuid': 'bbc-1', 'name': 'BBC Radio 1'},
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);

      final results = await service.searchByName('BBC');
      expect(results.length, 1);
      expect(results.first['name'], 'BBC Radio 1');
    });

    test('Successful tag search', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['tag'], 'rock');
        return http.Response(
          jsonEncode([
            {'stationuuid': 'rock-1', 'name': 'Rock Radio'},
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);

      final results = await service.searchByTag('rock');
      expect(results.length, 1);
      expect(results.first['name'], 'Rock Radio');
    });

    test(
      'First server fails (500), fails over to second server (200)',
      () async {
        int requestCount = 0;
        final mockClient = MockClient((request) async {
          requestCount++;
          if (request.url.host == 'srv1.example.com') {
            return http.Response('Internal Error', 500);
          }
          if (request.url.host == 'srv2.example.com') {
            return http.Response(
              jsonEncode([
                {'stationuuid': 'ok-1', 'name': 'Backup Server Station'},
              ]),
              200,
            );
          }
          return http.Response('Error', 400);
        });

        final service = RadioBrowserService(client: mockClient);
        service.setServers(['srv1.example.com', 'srv2.example.com']);

        final results = await service.getPopularStations();
        expect(requestCount, 2);
        expect(results.length, 1);
        expect(results.first['name'], 'Backup Server Station');
        expect(service.activeServer, 'srv2.example.com');
      },
    );

    test('First server times out, fails over to second server', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'srv1.example.com') {
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('Late response', 200);
        }
        return http.Response(
          jsonEncode([
            {'stationuuid': 'fast-1', 'name': 'Fast Server Station'},
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com', 'srv2.example.com']);

      // Trigger timeout on first server using a 20ms timeout
      final results = await service.getPopularStations(
        timeout: const Duration(milliseconds: 20),
      );
      expect(results.length, 1);
      expect(results.first['name'], 'Fast Server Station');
    });

    test(
      'Invalid response body (not a JSON list) causes failover/exception',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"error": "not a list"}', 200);
        });

        final service = RadioBrowserService(client: mockClient);
        service.setServers(['srv1.example.com']);

        expect(
          () => service.getPopularStations(),
          throwsA(isA<RadioBrowserException>()),
        );
      },
    );

    test('Empty JSON response list returns empty list cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response('[]', 200);
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);

      final results = await service.getPopularStations();
      expect(results, isEmpty);
    });

    test('All servers unavailable throws RadioBrowserException', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Service Unavailable', 503);
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com', 'srv2.example.com']);

      expect(
        () => service.getPopularStations(),
        throwsA(isA<RadioBrowserException>()),
      );
    });
  });
}
