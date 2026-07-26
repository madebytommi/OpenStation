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
  bool _isBuffering = false;
  int stopCallCount = 0;
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

  void emitPlaying(bool value) {
    _isPlaying = value;
    if (!_playingController.isClosed) _playingController.add(value);
  }

  void emitBuffering(bool value) {
    _isBuffering = value;
    if (!_bufferingController.isClosed) _bufferingController.add(value);
  }

  void emitCompleted(bool value) {
    if (!_completedController.isClosed) _completedController.add(value);
  }

  void emitError(String value) {
    if (!_errorController.isClosed) _errorController.add(value);
  }

  void emitLog(PlayerLog value) {
    if (!_logController.isClosed) _logController.add(value);
  }

  @override
  Future<void> open(Media media) async {
    openedUrls.add(media.uri);
    await onOpen?.call(media);
  }

  @override
  Future<void> play() async => emitPlaying(true);

  @override
  Future<void> pause() async => emitPlaying(false);

  @override
  Future<void> stop() async {
    stopCallCount++;
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

const stationA = Station(
  uuid: 'station-a',
  name: 'Station A',
  url: 'http://original-a.stream',
  resolvedUrl: 'http://resolved-a.stream',
);

const stationB = Station(
  uuid: 'station-b',
  name: 'Station B',
  url: 'http://original-b.stream',
  resolvedUrl: 'http://resolved-b.stream',
);

void main() {
  group('AudioPlayerService', () {
    late FakeAudioPlayerAdapter adapter;
    late List<Station> recentAdded;

    setUp(() {
      adapter = FakeAudioPlayerAdapter();
      recentAdded = [];
    });

    AudioPlayerService createService({
      Duration timeout = const Duration(milliseconds: 50),
      Duration settle = const Duration(milliseconds: 5),
    }) {
      return AudioPlayerService.createForTesting(
        adapter: adapter,
        connectionTimeout: timeout,
        errorSettleDuration: settle,
        recentStationCallback: recentAdded.add,
      );
    }

    Future<void> waitForSettle([
      Duration duration = const Duration(milliseconds: 10),
    ]) async {
      await Future<void>.delayed(duration);
    }

    test('1: resolved URL succeeds and original is not attempted', () async {
      final service = createService();
      adapter.onOpen = (media) async {
        if (media.uri == stationA.resolvedUrl) {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        }
      };

      await service.playStation(stationA);

      expect(adapter.openedUrls, [stationA.resolvedUrl]);
      expect(service.state, AudioPlayerState.playing);
      expect(recentAdded, [stationA]);
    });

    test('2: resolved exception falls back to original', () async {
      final service = createService();
      final states = <AudioPlayerState>[];
      service.addListener(() => states.add(service.state));
      adapter.onOpen = (media) async {
        if (media.uri == stationA.resolvedUrl) {
          throw Exception('resolved failed');
        }
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(stationA);

      expect(adapter.openedUrls, [stationA.resolvedUrl, stationA.url]);
      expect(service.state, AudioPlayerState.playing);
      expect(states, isNot(contains(AudioPlayerState.failed)));
    });

    test('3: resolved timeout falls back to original', () async {
      final service = createService(
        timeout: const Duration(milliseconds: 15),
      );
      adapter.onOpen = (media) async {
        if (media.uri == stationA.url) {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        }
      };

      await service.playStation(stationA);

      expect(adapter.openedUrls, [stationA.resolvedUrl, stationA.url]);
      expect(service.state, AudioPlayerState.playing);
    });

    test(
      '4: identical resolved and original URL is attempted once',
      () async {
        const station = Station(
          uuid: 'same',
          name: 'Same',
          url: 'http://same.stream',
          resolvedUrl: 'http://same.stream',
        );
        final service = createService();
        adapter.onOpen = (_) async {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        };

        await service.playStation(station);

        expect(adapter.openedUrls, ['http://same.stream']);
      },
    );

    test('5: blank resolved URL attempts original directly', () async {
      const station = Station(
        uuid: 'original-only',
        name: 'Original only',
        url: 'http://original.stream',
        resolvedUrl: '',
      );
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(station);

      expect(adapter.openedUrls, ['http://original.stream']);
      expect(service.state, AudioPlayerState.playing);
    });

    test('6: blank candidate URLs fail without opening media', () async {
      const station = Station(
        uuid: 'blank',
        name: 'Blank',
        url: ' ',
        resolvedUrl: '',
      );
      final service = createService();

      await service.playStation(station);

      expect(adapter.openedUrls, isEmpty);
      expect(service.state, AudioPlayerState.failed);
      expect(service.lastError, AudioPlayerService.stableFailureMessage);
    });

    test('7: both candidates throwing enters Failed once', () async {
      final service = createService();
      adapter.onOpen = (_) async => throw Exception('unavailable');

      await service.playStation(stationA);

      expect(adapter.openedUrls, [stationA.resolvedUrl, stationA.url]);
      expect(service.state, AudioPlayerState.failed);
      expect(service.lastError, AudioPlayerService.stableFailureMessage);
    });

    test('8: resolved timeout plus original error makes no third attempt', () async {
      final service = createService(
        timeout: const Duration(milliseconds: 15),
      );
      adapter.onOpen = (media) async {
        if (media.uri == stationA.url) {
          scheduleMicrotask(() => adapter.emitError('original failed'));
        }
      };

      await service.playStation(stationA);

      expect(adapter.openedUrls, [stationA.resolvedUrl, stationA.url]);
      expect(service.state, AudioPlayerState.failed);
    });

    test('9: one unique URL times out after one attempt', () async {
      const station = Station(
        uuid: 'one',
        name: 'One',
        url: 'http://one.stream',
        resolvedUrl: 'http://one.stream',
      );
      final service = createService(
        timeout: const Duration(milliseconds: 15),
      );

      await service.playStation(station);

      expect(adapter.openedUrls, ['http://one.stream']);
      expect(service.state, AudioPlayerState.failed);
    });

    test('10: Stop during connection prevents fallback', () async {
      final service = createService(
        timeout: const Duration(milliseconds: 100),
      );

      final playFuture = service.playStation(stationA);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await service.stop();
      await playFuture;

      expect(adapter.openedUrls, [stationA.resolvedUrl]);
      expect(service.state, AudioPlayerState.stopped);
    });

    test('11: newer station wins while first is connecting', () async {
      final service = createService(
        timeout: const Duration(milliseconds: 100),
      );
      adapter.onOpen = (media) async {
        if (media.uri == stationB.resolvedUrl) {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        }
      };

      final first = service.playStation(stationA);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final second = service.playStation(stationB);
      await Future.wait([first, second]);

      expect(service.currentStation, stationB);
      expect(service.state, AudioPlayerState.playing);
      expect(recentAdded, [stationB]);
    });

    test('12: newer station wins while first is on fallback', () async {
      final service = createService(
        timeout: const Duration(milliseconds: 10),
      );
      adapter.onOpen = (media) async {
        if (media.uri == stationB.resolvedUrl) {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        }
      };

      final first = service.playStation(stationA);
      await Future<void>.delayed(const Duration(milliseconds: 15));
      final second = service.playStation(stationB);
      await Future.wait([first, second]);

      expect(service.currentStation, stationB);
      expect(service.state, AudioPlayerState.playing);
    });

    test('13 and 14: fallback stays Connecting and clears metadata', () async {
      final service = createService();
      final states = <AudioPlayerState>[];
      service.addListener(() => states.add(service.state));
      adapter.onOpen = (media) async {
        if (media.uri == stationA.resolvedUrl) {
          service.currentMetadata.value = 'stale';
          throw Exception('resolved failed');
        }
        expect(service.currentMetadata.value, isNull);
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(stationA);

      expect(states, isNot(contains(AudioPlayerState.failed)));
      expect(service.state, AudioPlayerState.playing);
    });

    test('15: timeout does not record Recently Played', () async {
      final service = createService(
        timeout: const Duration(milliseconds: 10),
      );
      const station = Station(
        uuid: 'timeout',
        name: 'Timeout',
        url: 'http://timeout.stream',
        resolvedUrl: 'http://timeout.stream',
      );

      await service.playStation(station);

      expect(service.state, AudioPlayerState.failed);
      expect(recentAdded, isEmpty);
    });

    test('16: fallback success records Recently Played once', () async {
      final service = createService();
      adapter.onOpen = (media) async {
        if (media.uri == stationA.resolvedUrl) {
          throw Exception('resolved failed');
        }
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(stationA);

      expect(recentAdded, [stationA]);
    });

    test('17 and 18: success subscriptions remain safe through Stop', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(stationA);
      await service.stop();

      expect(service.state, AudioPlayerState.stopped);
    });

    test('19: raw error log does not enter Failed', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      adapter.emitLog(
        const PlayerLog(
          prefix: 'test',
          level: 'error',
          text: 'harmless error text',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.state, AudioPlayerState.playing);
      expect(service.lastError, isEmpty);
    });

    test('20: dedicated error plus playing=false enters Failed', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);
      service.currentMetadata.value = 'metadata';

      adapter.emitError('fatal decode error');
      await Future<void>.delayed(Duration.zero);
      expect(service.state, AudioPlayerState.playing);

      adapter.emitPlaying(false);
      await Future<void>.delayed(Duration.zero);

      expect(service.state, AudioPlayerState.failed);
      expect(
        service.lastError,
        AudioPlayerService.postConnectionFailureMessage,
      );
      expect(service.currentMetadata.value, isNull);
    });

    test('21: A plays, B replaces it, and stale error does not fail B', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };

      await service.playStation(stationA);
      expect(service.currentStation, stationA);
      expect(service.state, AudioPlayerState.playing);

      await service.playStation(stationB);
      expect(service.currentStation, stationB);
      expect(service.state, AudioPlayerState.playing);
      service.currentMetadata.value = 'B metadata';

      adapter.emitError('late untagged error from A');
      await waitForSettle();

      expect(service.currentStation, stationB);
      expect(service.state, AudioPlayerState.playing);
      expect(service.currentMetadata.value, 'B metadata');
      expect(service.lastError, isEmpty);
    });

    test('22: dedicated error is ignored while playback continues', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      adapter.emitError('recoverable backend error');
      await waitForSettle();

      expect(service.state, AudioPlayerState.playing);
      expect(service.lastError, isEmpty);
    });

    test('23: completion followed by delayed error remains Stopped', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      adapter.emitCompleted(true);
      await Future<void>.delayed(Duration.zero);
      adapter.emitError('late error');
      await waitForSettle();

      expect(service.state, AudioPlayerState.stopped);
      expect(service.lastError, isEmpty);
    });

    test('24: user Stop followed by delayed error remains Stopped', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      await service.stop();
      adapter.emitError('late error');
      await waitForSettle();

      expect(service.state, AudioPlayerState.stopped);
      expect(service.lastError, isEmpty);
    });

    test('25: duplicate errors finalize one player stop', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);
      final stopCountBeforeFailure = adapter.stopCallCount;

      adapter.emitError('error one');
      adapter.emitError('error two');
      adapter.emitPlaying(false);
      await waitForSettle();

      expect(service.state, AudioPlayerState.failed);
      expect(
        service.lastError,
        AudioPlayerService.postConnectionFailureMessage,
      );
      expect(adapter.stopCallCount - stopCountBeforeFailure, 1);
    });

    test('26: valid ICY metadata remains supported', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      adapter.emitLog(
        const PlayerLog(
          prefix: 'test',
          level: 'info',
          text: 'icy-title: Cool Song - Artist',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.currentMetadata.value, 'Cool Song - Artist');
    });

    test('27: malformed ICY metadata remains nonfatal', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      adapter.emitLog(
        const PlayerLog(
          prefix: 'test',
          level: 'info',
          text: 'icy-title:',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(service.state, AudioPlayerState.playing);
      expect(service.currentMetadata.value, isNull);
    });

    test('28: duplicate playing=true does not duplicate Recently Played', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      adapter.emitPlaying(true);
      adapter.emitPlaying(true);
      await Future<void>.delayed(Duration.zero);

      expect(recentAdded, [stationA]);
    });

    test('29: dispose makes late events inert', () async {
      final service = createService();
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(true));
      };
      await service.playStation(stationA);

      service.dispose();
      adapter.emitError('late error');
      adapter.emitPlaying(false);
      adapter.emitLog(
        const PlayerLog(
          prefix: 'test',
          level: 'info',
          text: 'icy-title: Song',
        ),
      );
      await waitForSettle();

      expect(service.state, AudioPlayerState.idle);
    });

    test('30: playing=false while Connecting does not expose Paused', () async {
      final service = createService(
        timeout: const Duration(milliseconds: 15),
      );
      adapter.onOpen = (_) async {
        scheduleMicrotask(() => adapter.emitPlaying(false));
      };

      final playFuture = service.playStation(stationA);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(service.state, AudioPlayerState.connecting);

      await playFuture;
      expect(service.state, AudioPlayerState.failed);
    });

    test(
      '31: successful connection transitions to Playing without buffering event',
      () async {
        final service = createService();
        adapter.onOpen = (_) async {
          scheduleMicrotask(() => adapter.emitPlaying(true));
        };

        await service.playStation(stationA);

        expect(service.state, AudioPlayerState.playing);
        expect(recentAdded, [stationA]);
      },
    );
  });
}
