import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:open_station/models/station.dart';
import 'package:open_station/services/audio_player_adapter.dart';
import 'package:open_station/services/audio_player_service.dart';

class FakeAudioPlayerAdapter implements AudioPlayerAdapter {
  final StreamController<bool> _playingController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _bufferingController =
      StreamController<bool>.broadcast();
  final StreamController<bool> _completedController =
      StreamController<bool>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<Track> _trackController =
      StreamController<Track>.broadcast();
  final StreamController<PlayerLog> _logController =
      StreamController<PlayerLog>.broadcast();

  final List<String> openedUrls = [];
  bool _isPlaying = false;
  final bool _isBuffering = false;

  Future<void> Function(Media media)? onOpen;

  @override
  Stream<bool> get playing => _playingController.stream;
  @override
  Stream<bool> get buffering => _bufferingController.stream;
  @override
  Stream<bool> get completed => _completedController.stream;
  @override
  Stream<String> get error => _errorController.stream;
  @override
  Stream<Track> get track => _trackController.stream;
  @override
  Stream<PlayerLog> get log => _logController.stream;

  @override
  bool get isPlaying => _isPlaying;
  @override
  bool get isBuffering => _isBuffering;

  void emitPlaying(bool p) {
    _isPlaying = p;
    _playingController.add(p);
  }

  void emitError(String err) {
    _errorController.add(err);
  }

  void emitLog(PlayerLog log) {
    _logController.add(log);
  }

  @override
  Future<void> open(Media media) async {
    openedUrls.add(media.uri);
    if (onOpen != null) {
      await onOpen!(media);
    }
  }

  @override
  Future<void> play() async {
    emitPlaying(true);
  }

  @override
  Future<void> pause() async {
    emitPlaying(false);
  }

  @override
  Future<void> stop() async {
    emitPlaying(false);
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> dispose() async {
    await _playingController.close();
    await _bufferingController.close();
    await _completedController.close();
    await _errorController.close();
    await _trackController.close();
    await _logController.close();
  }
}

void main() {
  group('AudioPlayerService Unit Tests', () {
    late FakeAudioPlayerAdapter adapter;
    late List<Station> recentAdded;

    setUp(() {
      adapter = FakeAudioPlayerAdapter();
      recentAdded = [];
    });

    AudioPlayerService createService({
      Duration timeout = const Duration(milliseconds: 50),
    }) {
      return AudioPlayerService.createForTesting(
        adapter: adapter,
        connectionTimeout: timeout,
        recentStationCallback: (s) => recentAdded.add(s),
      );
    }

    test(
      '1: Resolved URL succeeds, original never attempted, state Playing',
      () async {
        final service = createService();
        const station = Station(
          uuid: 's-1',
          name: 'Station 1',
          url: 'http://orig.stream',
          resolvedUrl: 'http://resolved.stream',
        );

        adapter.onOpen = (media) async {
          if (media.uri == 'http://resolved.stream') {
            scheduleMicrotask(() => adapter.emitPlaying(true));
          }
        };

        await service.playStation(station);

        expect(adapter.openedUrls, ['http://resolved.stream']);
        expect(service.state, AudioPlayerState.playing);
        expect(recentAdded.length, 1);
      },
    );

    test('2: Resolved URL throws before playback, original succeeds', () async {
      final service = createService();
      const station = Station(
        uuid: 's-2',
        name: 'Station 2',
        url: 'http://orig.stream',
        resolvedUrl: 'http://resolved.stream',
      );

      final List<AudioPlayerState> states = [];
      service.addListener(() => states.add(service.state));

      adapter.onOpen = (media) async {
        if (media.uri == 'http://resolved.stream') {
          throw Exception('Connection refused');
        } else if (media.uri == 'http://orig.stream') {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        }
      };

      await service.playStation(station);

      expect(adapter.openedUrls, [
        'http://resolved.stream',
        'http://orig.stream',
      ]);
      expect(service.state, AudioPlayerState.playing);
      expect(states.contains(AudioPlayerState.failed), false);
      expect(recentAdded.length, 1);
    });

    test('3: Resolved URL times out, original succeeds', () async {
      final service = createService(timeout: const Duration(milliseconds: 30));
      const station = Station(
        uuid: 's-3',
        name: 'Station 3',
        url: 'http://orig.stream',
        resolvedUrl: 'http://resolved.stream',
      );

      adapter.onOpen = (media) async {
        if (media.uri == 'http://orig.stream') {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        }
      };

      await service.playStation(station);

      expect(adapter.openedUrls, [
        'http://resolved.stream',
        'http://orig.stream',
      ]);
      expect(service.state, AudioPlayerState.playing);
    });

    test(
      '4: Resolved and original URLs identical: attempted exactly once',
      () async {
        final service = createService();
        const station = Station(
          uuid: 's-4',
          name: 'Station 4',
          url: 'http://same.stream',
          resolvedUrl: 'http://same.stream',
        );

        adapter.onOpen = (media) async {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        };

        await service.playStation(station);
        expect(adapter.openedUrls, ['http://same.stream']);
      },
    );

    test('5: Blank resolved URL: Original URL attempted directly', () async {
      final service = createService();
      const station = Station(
        uuid: 's-5',
        name: 'Station 5',
        url: 'http://orig.stream',
        resolvedUrl: '',
      );

      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(station);
      expect(adapter.openedUrls, ['http://orig.stream']);
    });

    test(
      '6: Both URLs unusable: no open attempt, state Failed with stable message',
      () async {
        final service = createService();
        const station = Station(
          uuid: 's-6',
          name: 'Station 6',
          url: '  ',
          resolvedUrl: '',
        );

        await service.playStation(station);

        expect(adapter.openedUrls, isEmpty);
        expect(service.state, AudioPlayerState.failed);
        expect(service.lastError, AudioPlayerService.stableFailureMessage);
      },
    );

    test(
      '7: Resolved and original both throw: each attempted once, state Failed',
      () async {
        final service = createService();
        const station = Station(
          uuid: 's-7',
          name: 'Station 7',
          url: 'http://orig.stream',
          resolvedUrl: 'http://resolved.stream',
        );

        adapter.onOpen = (media) async {
          throw Exception('Stream unavailable');
        };

        await service.playStation(station);

        expect(adapter.openedUrls, [
          'http://resolved.stream',
          'http://orig.stream',
        ]);
        expect(service.state, AudioPlayerState.failed);
        expect(service.lastError, AudioPlayerService.stableFailureMessage);
      },
    );

    test(
      '8: Resolved times out and original errors: state Failed, no 3rd attempt',
      () async {
        final service = createService(
          timeout: const Duration(milliseconds: 30),
        );
        const station = Station(
          uuid: 's-8',
          name: 'Station 8',
          url: 'http://orig.stream',
          resolvedUrl: 'http://resolved.stream',
        );

        adapter.onOpen = (media) async {
          if (media.uri == 'http://orig.stream') {
            scheduleMicrotask(() => adapter.emitError('404 Not Found'));
          }
        };

        await service.playStation(station);

        expect(adapter.openedUrls, [
          'http://resolved.stream',
          'http://orig.stream',
        ]);
        expect(service.state, AudioPlayerState.failed);
      },
    );

    test(
      '9: One unique URL times out: state Failed after one attempt',
      () async {
        final service = createService(
          timeout: const Duration(milliseconds: 30),
        );
        const station = Station(
          uuid: 's-9',
          name: 'Station 9',
          url: 'http://single.stream',
          resolvedUrl: 'http://single.stream',
        );

        await service.playStation(station);

        expect(adapter.openedUrls, ['http://single.stream']);
        expect(service.state, AudioPlayerState.failed);
      },
    );

    test(
      '10: Stop during resolved connection: no fallback attempt, state Stopped',
      () async {
        final service = createService(
          timeout: const Duration(milliseconds: 200),
        );
        const station = Station(
          uuid: 's-10',
          name: 'Station 10',
          url: 'http://orig.stream',
          resolvedUrl: 'http://resolved.stream',
        );

        final future = service.playStation(station);
        await Future.delayed(const Duration(milliseconds: 20));
        await service.stop();
        await future;

        expect(adapter.openedUrls, ['http://resolved.stream']);
        expect(service.state, AudioPlayerState.stopped);
      },
    );

    test(
      '11: New station selected during first station resolved attempt',
      () async {
        final service = createService(
          timeout: const Duration(milliseconds: 200),
        );
        const station1 = Station(
          uuid: 's-11a',
          name: 'Station 11a',
          url: 'http://orig1.stream',
          resolvedUrl: 'http://res1.stream',
        );
        const station2 = Station(
          uuid: 's-11b',
          name: 'Station 11b',
          url: 'http://orig2.stream',
          resolvedUrl: 'http://res2.stream',
        );

        adapter.onOpen = (media) async {
          if (media.uri == 'http://res2.stream') {
            scheduleMicrotask(() => adapter.emitPlaying(true));
          }
        };

        final f1 = service.playStation(station1);
        await Future.delayed(const Duration(milliseconds: 20));
        final f2 = service.playStation(station2);

        await Future.wait([f1, f2]);

        expect(service.currentStation?.uuid, 's-11b');
        expect(service.state, AudioPlayerState.playing);
      },
    );

    test(
      '12: New station selected while first station is on fallback',
      () async {
        final service = createService(
          timeout: const Duration(milliseconds: 20),
        );
        const station1 = Station(
          uuid: 's-12a',
          name: 'Station 12a',
          url: 'http://orig1.stream',
          resolvedUrl: 'http://res1.stream',
        );
        const station2 = Station(
          uuid: 's-12b',
          name: 'Station 12b',
          url: 'http://orig2.stream',
          resolvedUrl: 'http://res2.stream',
        );

        adapter.onOpen = (media) async {
          if (media.uri == 'http://res2.stream') {
            scheduleMicrotask(() => adapter.emitPlaying(true));
          }
        };

        final f1 = service.playStation(station1);
        await Future.delayed(
          const Duration(milliseconds: 30),
        ); // triggers fallback
        final f2 = service.playStation(station2);

        await Future.wait([f1, f2]);

        expect(service.currentStation?.uuid, 's-12b');
        expect(service.state, AudioPlayerState.playing);
      },
    );

    test(
      '13 & 14: Resolved failure followed by original success never emits Failed and clears metadata',
      () async {
        final service = createService();
        const station = Station(
          uuid: 's-13',
          name: 'Station 13',
          url: 'http://orig.stream',
          resolvedUrl: 'http://resolved.stream',
        );

        final List<AudioPlayerState> states = [];
        service.addListener(() => states.add(service.state));

        adapter.onOpen = (media) async {
          if (media.uri == 'http://resolved.stream') {
            service.currentMetadata.value = 'Stale Metadata';
            throw Exception('Fail resolved');
          } else if (media.uri == 'http://orig.stream') {
            expect(service.currentMetadata.value, isNull);
            scheduleMicrotask(() => adapter.emitPlaying(true));
          }
        };

        await service.playStation(station);

        expect(states.contains(AudioPlayerState.failed), false);
        expect(service.state, AudioPlayerState.playing);
      },
    );

    test('15: Timeout does not record Recently Played', () async {
      final service = createService(timeout: const Duration(milliseconds: 20));
      const station = Station(
        uuid: 's-15',
        name: 'Station 15',
        url: 'http://time.stream',
        resolvedUrl: 'http://time.stream',
      );

      await service.playStation(station);

      expect(service.state, AudioPlayerState.failed);
      expect(recentAdded, isEmpty);
    });

    test(
      '16: Fallback success causes only one Recently Played addition after playback begins',
      () async {
        final service = createService();
        const station = Station(
          uuid: 's-16',
          name: 'Station 16',
          url: 'http://orig.stream',
          resolvedUrl: 'http://resolved.stream',
        );

        adapter.onOpen = (media) async {
          if (media.uri == 'http://resolved.stream') {
            throw Exception('Fail resolved');
          } else if (media.uri == 'http://orig.stream') {
            scheduleMicrotask(() => adapter.emitPlaying(true));
          }
        };

        await service.playStation(station);

        expect(recentAdded.length, 1);
        expect(recentAdded.first.uuid, 's-16');
      },
    );

    test(
      '17 & 18: Timers and subscriptions are cleaned up on success/failure/stop',
      () async {
        final service = createService(
          timeout: const Duration(milliseconds: 30),
        );
        const station = Station(
          uuid: 's-17',
          name: 'Station 17',
          url: 'http://orig.stream',
          resolvedUrl: 'http://resolved.stream',
        );

        adapter.onOpen = (media) async {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        };

        await service.playStation(station);
        expect(service.state, AudioPlayerState.playing);

        await service.stop();
        expect(service.state, AudioPlayerState.stopped);
      },
    );

    test('19: Non-fatal logs do not transition state to Failed', () async {
      final service = createService();
      const station = Station(
        uuid: 's-19',
        name: 'Station 19',
        url: 'http://orig.stream',
        resolvedUrl: 'http://orig.stream',
      );

      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(station);
      expect(service.state, AudioPlayerState.playing);

      adapter.emitLog(const PlayerLog(prefix: 'test', level: 'error', text: 'Some harmless error string'));
      await Future.delayed(Duration.zero);

      expect(service.state, AudioPlayerState.playing); // Must not fail
    });

    test('20: Fatal post-connection error correctly fails and stops player', () async {
      final service = createService();
      const station = Station(
        uuid: 's-20',
        name: 'Station 20',
        url: 'http://orig.stream',
        resolvedUrl: 'http://orig.stream',
      );

      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(station);
      expect(service.state, AudioPlayerState.playing);

      adapter.emitError('Fatal decode error');
      await Future.delayed(Duration.zero);

      expect(service.state, AudioPlayerState.failed);
      expect(service.lastError, AudioPlayerService.postConnectionFailureMessage);
      expect(adapter.isPlaying, false); // Ensures stop was called
    });
  });
}
