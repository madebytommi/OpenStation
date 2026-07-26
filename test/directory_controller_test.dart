import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:open_station/controllers/directory_controller.dart';
import 'package:open_station/services/radio_browser_service.dart';

void main() {
  group('DirectoryController Unit Tests', () {
    test(
      '1 & 12: Typed query triggers search after 300ms debounce and is trimmed',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.queryParameters['name'], 'jazz');
          return http.Response('[]', 200);
        });

        final service = RadioBrowserService(client: mockClient);
        service.setServers(['srv1.example.com']);
        final controller = DirectoryController(service: service);

        controller.onSearchChanged('  jazz  ');
        expect(controller.isLoading, false);

        await Future.delayed(const Duration(milliseconds: 350));
        expect(controller.searchQuery, '  jazz  ');
      },
    );

    test(
      '2, 3, 4: Name and tag results are merged name-first and deduplicated',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.queryParameters['name'] == 'rock') {
            return http.Response(
              jsonEncode([
                {
                  'stationuuid': 'st-1',
                  'name': 'Rock Name 1',
                  'url': 'http://rock1.stream',
                },
              ]),
              200,
            );
          }
          if (request.url.queryParameters['tag'] == 'rock') {
            return http.Response(
              jsonEncode([
                {
                  'stationuuid': 'st-1',
                  'name': 'Rock Name 1 Dup',
                  'url': 'http://rock1.stream',
                },
                {
                  'stationuuid': 'st-2',
                  'name': 'Rock Tag 2',
                  'url': 'http://rock2.stream',
                },
              ]),
              200,
            );
          }
          return http.Response('[]', 200);
        });

        final service = RadioBrowserService(client: mockClient);
        service.setServers(['srv1.example.com']);
        final controller = DirectoryController(service: service);

        controller.onSearchChanged('rock');
        await Future.delayed(const Duration(milliseconds: 350));

        expect(controller.stations.length, 2);
        expect(controller.stations[0].uuid, 'st-1');
        expect(controller.stations[1].uuid, 'st-2');
      },
    );

    test('5: Combined results capped at 50', () async {
      final mockClient = MockClient((request) async {
        if (request.url.queryParameters.containsKey('name')) {
          final list = List.generate(
            40,
            (i) => {
              'stationuuid': 'name-id-$i',
              'name': 'Name Station $i',
              'url': 'http://s$i.stream',
            },
          );
          return http.Response(jsonEncode(list), 200);
        } else {
          final list = List.generate(
            40,
            (i) => {
              'stationuuid': 'tag-id-$i',
              'name': 'Tag Station $i',
              'url': 'http://t$i.stream',
            },
          );
          return http.Response(jsonEncode(list), 200);
        }
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      controller.onSearchChanged('pop');
      await Future.delayed(const Duration(milliseconds: 350));

      expect(controller.stations.length, 50);
    });

    test(
      '6 & 7: Partial failure returns valid results without error state',
      () async {
        final mockClient = MockClient((request) async {
          if (request.url.queryParameters.containsKey('name')) {
            return http.Response(
              jsonEncode([
                {
                  'stationuuid': 'name-only',
                  'name': 'Name Only Station',
                  'url': 'http://name.stream',
                },
              ]),
              200,
            );
          }
          return http.Response('Server Error', 500);
        });

        final service = RadioBrowserService(client: mockClient);
        service.setServers(['srv1.example.com']);
        final controller = DirectoryController(service: service);

        controller.onSearchChanged('partial');
        await Future.delayed(const Duration(milliseconds: 350));

        expect(controller.errorMessage, isNull);
        expect(controller.stations.length, 1);
        expect(controller.stations.first.name, 'Name Only Station');
      },
    );

    test('8: Both failures enter error state', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      controller.onSearchChanged('fail');
      await Future.delayed(const Duration(milliseconds: 350));

      expect(controller.errorMessage, isNotNull);
      expect(controller.stations, isEmpty);
    });

    test('9: Older slow query cannot replace newer query', () async {
      final mockClient = MockClient((request) async {
        final q =
            request.url.queryParameters['name'] ??
            request.url.queryParameters['tag'];
        if (q == 'slow') {
          await Future.delayed(const Duration(milliseconds: 200));
          return http.Response(
            jsonEncode([
              {
                'stationuuid': 'slow-uuid',
                'name': 'Slow Station',
                'url': 'http://slow.stream',
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'stationuuid': 'fast-uuid',
              'name': 'Fast Station',
              'url': 'http://fast.stream',
            },
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      controller.onSearchChanged('slow');
      await Future.delayed(const Duration(milliseconds: 100));
      controller.onSearchChanged('fast');

      await Future.delayed(const Duration(milliseconds: 600));
      expect(controller.stations.length, 1);
      expect(controller.stations.first.name, 'Fast Station');
    });

    test('10: Selecting tag invalidates older pending typed search', () async {
      final mockClient = MockClient((request) async {
        if (request.url.queryParameters.containsKey('tag') &&
            request.url.queryParameters['tag'] == 'jazz') {
          return http.Response(
            jsonEncode([
              {
                'stationuuid': 'jazz-tag',
                'name': 'Jazz Tag Station',
                'url': 'http://jazz.stream',
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'stationuuid': 'typed-id',
              'name': 'Typed Station',
              'url': 'http://typed.stream',
            },
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      controller.onSearchChanged('typed');
      controller.selectTag('jazz');

      await Future.delayed(const Duration(milliseconds: 400));
      expect(controller.selectedTag, 'jazz');
      expect(controller.stations.first.name, 'Jazz Tag Station');
    });

    test('11: Empty or whitespace input loads Popular', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['order'], 'clickcount');
        return http.Response(
          jsonEncode([
            {
              'stationuuid': 'pop-1',
              'name': 'Popular Station',
              'url': 'http://pop.stream',
            },
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      controller.onSearchChanged('   ');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.stations.first.name, 'Popular Station');
    });

    test('13: Failed Popular Retry calls Popular again', () async {
      int attempt = 0;
      final mockClient = MockClient((request) async {
        attempt++;
        if (attempt == 1) {
          return http.Response('Server Error', 500);
        }
        return http.Response(
          jsonEncode([
            {
              'stationuuid': 'pop-ok',
              'name': 'Popular Recovered',
              'url': 'http://pop.stream',
            },
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      await controller.loadPopularStations();
      expect(controller.errorMessage, isNotNull);

      await controller.retry();
      expect(controller.errorMessage, isNull);
      expect(controller.stations.first.name, 'Popular Recovered');
    });

    test(
      '14: Failed combined typed-search Retry repeats query immediately',
      () async {
        int attempt = 0;
        final mockClient = MockClient((request) async {
          attempt++;
          if (attempt <= 2) {
            return http.Response('Server Error', 500);
          }
          return http.Response(
            jsonEncode([
              {
                'stationuuid': 'retry-ok',
                'name': 'Retry Station',
                'url': 'http://retry.stream',
              },
            ]),
            200,
          );
        });

        final service = RadioBrowserService(client: mockClient);
        service.setServers(['srv1.example.com']);
        final controller = DirectoryController(service: service);

        controller.onSearchChanged('retryquery');
        await Future.delayed(const Duration(milliseconds: 350));
        expect(controller.errorMessage, isNotNull);

        // Retry immediately
        await controller.retry();
        expect(controller.errorMessage, isNull);
        expect(controller.stations.first.name, 'Retry Station');
      },
    );

    test(
      '15 & 16: Failed tag Retry repeats tag immediately and does not load Popular',
      () async {
        int attempt = 0;
        final mockClient = MockClient((request) async {
          attempt++;
          if (attempt == 1) {
            return http.Response('Server Error', 500);
          }
          expect(request.url.queryParameters['tag'], 'rock');
          return http.Response(
            jsonEncode([
              {
                'stationuuid': 'rock-tag',
                'name': 'Rock Tag Station',
                'url': 'http://rock.stream',
              },
            ]),
            200,
          );
        });

        final service = RadioBrowserService(client: mockClient);
        service.setServers(['srv1.example.com']);
        final controller = DirectoryController(service: service);

        controller.selectTag('rock');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(controller.errorMessage, isNotNull);
        expect(controller.selectedTag, 'rock');

        // Retry should keep selectedTag and repeat rock tag search
        await controller.retry();
        expect(controller.selectedTag, 'rock');
        expect(controller.stations.first.name, 'Rock Tag Station');
      },
    );

    test('17: Retry executes immediately without typing debounce', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      controller.onSearchChanged('quickretry');
      await Future.delayed(const Duration(milliseconds: 350));

      final future = controller.retry();
      expect(controller.isLoading, true); // Immediate
      await future;
    });

    test('18: User re-clicking active tag toggles back to Popular', () async {
      final mockClient = MockClient((request) async {
        if (request.url.queryParameters['order'] == 'clickcount') {
          return http.Response(
            jsonEncode([
              {
                'stationuuid': 'pop-1',
                'name': 'Popular Station',
                'url': 'http://pop.stream',
              },
            ]),
            200,
          );
        }
        return http.Response(
          jsonEncode([
            {
              'stationuuid': 'tag-1',
              'name': 'Tag Station',
              'url': 'http://tag.stream',
            },
          ]),
          200,
        );
      });

      final service = RadioBrowserService(client: mockClient);
      service.setServers(['srv1.example.com']);
      final controller = DirectoryController(service: service);

      controller.selectTag('rock');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.selectedTag, 'rock');

      // Re-click tag toggles off
      controller.selectTag('rock');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(controller.selectedTag, isNull);
      expect(controller.stations.first.name, 'Popular Station');
    });
  });
}
