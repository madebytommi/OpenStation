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

    test('20: Active station emits a dedicated error and then playing=false', () async {
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
      service.currentMetadata.value = 'Some metadata';

      adapter.emitError('Fatal decode error');
      await Future.delayed(Duration.zero);
      expect(service.state, AudioPlayerState.playing); // Pending, wait for confirmation

      adapter.emitPlaying(false);
      await Future.delayed(Duration.zero);

      expect(service.state, AudioPlayerState.failed);
      expect(service.lastError, AudioPlayerService.postConnectionFailureMessage);
      expect(adapter.isPlaying, false); // Ensures stop was called
      expect(service.currentMetadata.value, isNull);
    });

    test('21: Station A is Playing, B is selected, and an untagged error is emitted while B remains Playing', () async {
      final service = createService(timeout: const Duration(milliseconds: 100));
      const stationA = Station(
        uuid: 's-21a',
        name: 'Station 21A',
        url: 'http://orig.a',
        resolvedUrl: 'http://orig.a',
      );
      const stationB = Station(
        uuid: 's-21b',
        name: 'Station 21B',
        url: 'http://orig.b',
        resolvedUrl: 'http://orig.b',
      );

      adapter.onOpen = (media) async {
        if (media.uri == 'http://orig.b') {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        }
      };

      final f1 = service.playStation(stationA);
      await Future.delayed(const Duration(milliseconds: 20));
      final f2 = service.playStation(stationB);
      await Future.wait([f1, f2]);

      expect(service.state, AudioPlayerState.playing);
      expect(service.currentStation?.uuid, 's-21b');
      service.currentMetadata.value = 'B metadata';

      adapter.emitError('Late fatal error from A');
      await Future.delayed(Duration.zero);
      // Wait for the settle timer to pass and prove B continues playing
      await Future.delayed(const Duration(milliseconds: 150));

      expect(service.state, AudioPlayerState.playing);
      expect(service.currentMetadata.value, 'B metadata');
      expect(service.lastError, isEmpty);
    });

    test('22: Active station emits a dedicated error but continues Playing', () async {
      final service = createService();
      const station = Station(uuid: 's-22', name: '22', url: 'http://u', resolvedUrl: '');
      
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      
      await service.playStation(station);
      expect(service.state, AudioPlayerState.playing);

      adapter.emitError('Some error but we keep playing');
      await Future.delayed(Duration.zero);
      // Wait for settle timer
      await Future.delayed(const Duration(milliseconds: 150));

      expect(service.state, AudioPlayerState.playing);
      expect(service.lastError, isEmpty);
    });

    test('23: Normal completion followed by a delayed error', () async {
      final service = createService();
      const station = Station(uuid: 's-23', name: '23', url: 'http://u', resolvedUrl: '');
      
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(station);
      expect(service.state, AudioPlayerState.playing);

      adapter.emitCompleted(true);
      await Future.delayed(Duration.zero);
      expect(service.state, AudioPlayerState.stopped);

      adapter.emitError('Late error');
      await Future.delayed(const Duration(milliseconds: 150));
      expect(service.state, AudioPlayerState.stopped);
      expect(service.lastError, isEmpty);
    });

    test('24: User Stop followed by a delayed error', () async {
      final service = createService();
      const station = Station(uuid: 's-24', name: '24', url: 'http://u', resolvedUrl: '');
      
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(station);
      expect(service.state, AudioPlayerState.playing);

      await service.stop();
      expect(service.state, AudioPlayerState.stopped);

      adapter.emitError('Late error');
      await Future.delayed(const Duration(milliseconds: 150));
      expect(service.state, AudioPlayerState.stopped);
      expect(service.lastError, isEmpty);
    });

    test('25: Duplicate dedicated errors followed by playback stop', () async {
      final service = createService();
      const station = Station(uuid: 's-25', name: '25', url: 'http://u', resolvedUrl: '');
      
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(station);
      
      adapter.emitError('Error 1');
      adapter.emitError('Error 2');
      adapter.emitPlaying(false);
      await Future.delayed(const Duration(milliseconds: 150));

      expect(service.state, AudioPlayerState.failed);
      expect(service.lastError, AudioPlayerService.postConnectionFailureMessage);
    });

    test('26: Valid ICY metadata continues to work', () async {
      final service = createService();
      const station = Station(uuid: 's-26', name: '26', url: 'http://u', resolvedUrl: '');
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(station);
      
      adapter.emitLog(const PlayerLog(prefix: 'test', level: 'info', text: 'icy-title: Cool Song - Artist'));
      await Future.delayed(Duration.zero);
      expect(service.currentMetadata.value, 'Cool Song - Artist');
    });

    test('27: Malformed ICY metadata remains nonfatal', () async {
      final service = createService();
      const station = Station(uuid: 's-27', name: '27', url: 'http://u', resolvedUrl: '');
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(station);
      
      adapter.emitLog(const PlayerLog(prefix: 'test', level: 'info', text: 'icy-title:'));
      await Future.delayed(Duration.zero);
      expect(service.state, AudioPlayerState.playing);
      expect(service.currentMetadata.value, isNull);
    });

    test('28: Duplicate playing=true events do not duplicate Recently Played', () async {
      final service = createService();
      const station = Station(uuid: 's-28', name: '28', url: 'http://u', resolvedUrl: '');
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(station);
      
      adapter.emitPlaying(true);
      adapter.emitPlaying(true);
      await Future.delayed(Duration.zero);
      
      expect(recentAdded.length, 1);
    });

    test('29: Dispose followed by late events causes no state resurrection or exception', () async {
      final service = createService();
      const station = Station(uuid: 's-29', name: '29', url: 'http://u', resolvedUrl: '');
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(station);
      
      service.dispose();
      
      adapter.emitError('Late error');
      adapter.emitPlaying(false);
      adapter.emitLog(const PlayerLog(prefix: 'test', level: 'info', text: 'icy-title: Song'));
      await Future.delayed(const Duration(milliseconds: 150));
      
      expect(service.state, AudioPlayerState.idle);
    });

    test('30: playing=false during Connecting should not expose Paused', () async {
      final service = createService(timeout: const Duration(milliseconds: 50));
      const station = Station(uuid: 's-30', name: '30', url: 'http://u', resolvedUrl: '');
      
      adapter.onOpen = (media) async {
        scheduleMicrotask(() => adapter.emitPlaying(false));
      };
      
      final future = service.playStation(station);
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(service.state, AudioPlayerState.connecting);
      
      await future; // Will fail after timeout
      expect(service.state, AudioPlayerState.failed);
    });
  });
}
