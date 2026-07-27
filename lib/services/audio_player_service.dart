import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:open_station/models/station.dart';
import 'package:open_station/services/audio_player_adapter.dart';
import 'package:open_station/services/recent_stations_service.dart';

enum AudioPlayerState { idle, connecting, playing, paused, stopped, failed }

class AudioPlayerService extends ChangeNotifier {
  static const Duration stationConnectionTimeout = Duration(seconds: 10);
  static const Duration errorSettleDuration = Duration(milliseconds: 100);
  static const String stableFailureMessage =
      'This station could not be reached. Try again or choose another station.';
  static const String postConnectionFailureMessage =
      'Playback stopped because this station encountered an error. Try again or choose another station.';

  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayerAdapter? _player;
  AudioPlayerState _state = AudioPlayerState.idle;
  Station? _currentStation;
  String _lastError = '';
  double _volume = 1.0;
  int _playRequestToken = 0;
  int _activePlaybackToken = -1;
  String? _pendingFatalError;
  Timer? _errorSettleTimer;
  bool _disposed = false;

  Duration _connectionTimeout = stationConnectionTimeout;
  Duration _errorSettleDuration = errorSettleDuration;
  void Function(Station)? _recentStationCallback;

  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<PlayerLog>? _logSub;
  StreamSubscription<Track>? _trackSub;

  final ValueNotifier<String?> currentMetadata = ValueNotifier<String?>(null);

  AudioPlayerService._internal({
    AudioPlayerAdapter? adapter,
    Duration connectionTimeout = stationConnectionTimeout,
    Duration errorSettle = errorSettleDuration,
    void Function(Station)? recentStationCallback,
  }) : _player = adapter {
    _connectionTimeout = connectionTimeout;
    _errorSettleDuration = errorSettle;
    _recentStationCallback = recentStationCallback;
  }

  @visibleForTesting
  static AudioPlayerService createForTesting({
    required AudioPlayerAdapter adapter,
    Duration connectionTimeout = stationConnectionTimeout,
    Duration errorSettleDuration = AudioPlayerService.errorSettleDuration,
    void Function(Station)? recentStationCallback,
  }) {
    final service = AudioPlayerService._internal(
      adapter: adapter,
      connectionTimeout: connectionTimeout,
      errorSettle: errorSettleDuration,
      recentStationCallback: recentStationCallback,
    );
    service.init();
    return service;
  }

  AudioPlayerState get state => _state;
  Station? get currentStation => _currentStation;
  String get lastError => _lastError;
  double get volume => _volume;

  Future<void> init() async {
    _player ??= MediaKitPlayerAdapter();
  }

  void _bindPlayerEvents(int token) {
    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _completedSub?.cancel();
    _errorSub?.cancel();
    _trackSub?.cancel();
    _logSub?.cancel();

    // The token prevents callbacks owned by superseded listeners from acting.
    // media_kit events are not tagged with a station or request identity, so a
    // post-connection error is finalized only after active playback also stops.
    _playingSub = _player!.playing.listen((playing) {
      if (_disposed || token != _playRequestToken) return;

      if (playing) {
        if (!_player!.isBuffering && _state != AudioPlayerState.playing) {
          _setState(AudioPlayerState.playing);
        }
        if (_pendingFatalError != null) {
          _clearPendingFatalError();
        }
        return;
      }

      if (_state == AudioPlayerState.connecting) {
        return;
      }

      if (_pendingFatalError != null && _activePlaybackToken == token) {
        _finalizeFatalError(token);
      } else if (_state == AudioPlayerState.playing) {
        _setState(AudioPlayerState.paused);
      }
    });

    _bufferingSub = _player!.buffering.listen((buffering) {
      if (_disposed || token != _playRequestToken) return;
      if (buffering) {
        _setState(AudioPlayerState.connecting);
      } else if (_player!.isPlaying) {
        _setState(AudioPlayerState.playing);
      }
    });

    _completedSub = _player!.completed.listen((completed) {
      if (_disposed || token != _playRequestToken) return;
      if (completed) {
        _activePlaybackToken = -1;
        _clearPendingFatalError();
        currentMetadata.value = null;
        _setState(AudioPlayerState.stopped);
      }
    });

    _errorSub = _player!.error.listen((errorStr) {
      if (_disposed || token != _playRequestToken) return;
      if (errorStr.isEmpty || _activePlaybackToken != token) return;

      _pendingFatalError = errorStr;
      _errorSettleTimer?.cancel();
      _errorSettleTimer = Timer(_errorSettleDuration, () {
        if (_disposed || token != _playRequestToken) return;
        if (_pendingFatalError == null || _activePlaybackToken != token) return;

        if (_player!.isPlaying) {
          _clearPendingFatalError();
        } else {
          _finalizeFatalError(token);
        }
      });
    });

    _trackSub = _player!.track.listen((track) {
      if (_disposed || token != _playRequestToken) return;
      String? title = track.audio.title?.trim();
      if (title != null && title.isEmpty) title = null;
      currentMetadata.value = title;
    });

    _logSub = _player!.log.listen((event) {
      if (_disposed || token != _playRequestToken) return;
      final text = event.text.toLowerCase();
      if (!text.contains('icy-title:')) return;

      final parts = event.text.split(
        RegExp(r'icy-title:\s*', caseSensitive: false),
      );
      if (parts.length <= 1) return;

      final title = parts[1].trim();
      currentMetadata.value = title.isEmpty ? null : title;
    });
  }

  void _clearPendingFatalError() {
    _pendingFatalError = null;
    _errorSettleTimer?.cancel();
    _errorSettleTimer = null;
  }

  void _finalizeFatalError(int token) {
    if (_disposed || token != _playRequestToken) return;
    if (_activePlaybackToken != token || _pendingFatalError == null) return;

    _activePlaybackToken = -1;
    _clearPendingFatalError();
    currentMetadata.value = null;
    _lastError = postConnectionFailureMessage;
    _setState(AudioPlayerState.failed);

    // The stop future is intentionally detached; request ownership has already
    // been cleared and Failed is established before playing=false can arrive.
    unawaited(_player!.stop());
  }

  void _recordRecentStation(Station station) {
    if (_recentStationCallback != null) {
      _recentStationCallback!(station);
    } else {
      RecentStationsService().addRecentStation(station);
    }
  }

  void _setState(AudioPlayerState state) {
    if (_disposed || _state == state) return;
    _state = state;
    notifyListeners();
  }

  Future<void> playStation(Station station) async {
    _activePlaybackToken = -1;
    _clearPendingFatalError();

    _currentStation = station;
    final currentToken = ++_playRequestToken;

    final resolved = station.resolvedUrl.trim();
    final original = station.url.trim();
    final candidates = <String>[];
    if (resolved.isNotEmpty) candidates.add(resolved);
    if (original.isNotEmpty && original != resolved) candidates.add(original);

    if (candidates.isEmpty) {
      _lastError = stableFailureMessage;
      currentMetadata.value = null;
      _setState(AudioPlayerState.failed);
      return;
    }

    _lastError = '';
    currentMetadata.value = null;

    if (_player == null) {
      await init();
    } else {
      await _player!.stop();
    }

    if (_disposed || currentToken != _playRequestToken) return;

    _bindPlayerEvents(currentToken);
    _setState(AudioPlayerState.connecting);

    var success = false;
    for (var index = 0; index < candidates.length; index++) {
      if (_disposed || currentToken != _playRequestToken) return;

      currentMetadata.value = null;
      final attemptSuccess = await _attemptCandidate(
        candidates[index],
        currentToken,
      );
      if (_disposed || currentToken != _playRequestToken) return;

      if (attemptSuccess) {
        success = true;
        break;
      }

      if (index < candidates.length - 1) {
        await _player!.stop();
        currentMetadata.value = null;
      }
    }

    if (_disposed || currentToken != _playRequestToken) return;

    if (success) {
      _activePlaybackToken = currentToken;
      _setState(AudioPlayerState.playing);
      _recordRecentStation(_currentStation!);
    } else {
      _activePlaybackToken = -1;
      _clearPendingFatalError();
      currentMetadata.value = null;
      _lastError = stableFailureMessage;
      _setState(AudioPlayerState.failed);
    }
  }

  Future<bool> _attemptCandidate(String url, int token) async {
    if (_disposed || token != _playRequestToken) return false;

    final completer = Completer<bool>();
    Timer? timer;
    StreamSubscription<bool>? playSub;
    StreamSubscription<String>? errorSub;

    void cleanup() {
      timer?.cancel();
      playSub?.cancel();
      errorSub?.cancel();
    }

    void finish(bool value) {
      if (completer.isCompleted) return;
      cleanup();
      completer.complete(value);
    }

    playSub = _player!.playing.listen((playing) {
      if (_disposed || token != _playRequestToken) {
        finish(false);
      } else if (playing) {
        finish(true);
      }
    });

    errorSub = _player!.error.listen((error) {
      if (_disposed || token != _playRequestToken) {
        finish(false);
      } else if (error.isNotEmpty) {
        finish(false);
      }
    });

    timer = Timer(_connectionTimeout, () => finish(false));

    try {
      await _player!.open(
        Media(url, httpHeaders: const {'User-Agent': 'OpenStation/0.1'}),
      );

      if (_disposed || token != _playRequestToken) {
        finish(false);
        return false;
      }

      await _player!.setVolume(_volume * 100);
      if (_player!.isPlaying) finish(true);
    } catch (_) {
      finish(false);
    }

    final result = await completer.future;
    cleanup();
    return result;
  }

  Future<void> playUrl(String url) async {
    await playStation(
      Station(
        uuid: 'direct-url',
        name: 'Direct URL',
        url: url,
        resolvedUrl: url,
      ),
    );
  }

  Future<void> pause() async {
    if (_player == null) return;
    await _player!.pause();
    _setState(AudioPlayerState.paused);
  }

  Future<void> resume() async {
    if (_player == null) return;
    await _player!.play();
    _setState(AudioPlayerState.playing);
  }

  Future<void> stop() async {
    _activePlaybackToken = -1;
    _clearPendingFatalError();
    _playRequestToken++;
    currentMetadata.value = null;

    if (_player != null) {
      await _player!.stop();
      _setState(AudioPlayerState.stopped);
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (_player != null) {
      await _player!.setVolume(volume * 100);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _activePlaybackToken = -1;
    _clearPendingFatalError();

    _playingSub?.cancel();
    _bufferingSub?.cancel();
    _completedSub?.cancel();
    _errorSub?.cancel();
    _logSub?.cancel();
    _trackSub?.cancel();

    _playingSub = null;
    _bufferingSub = null;
    _completedSub = null;
    _errorSub = null;
    _logSub = null;
    _trackSub = null;

    currentMetadata.dispose();
    unawaited(_player?.dispose() ?? Future<void>.value());
    _player = null;
    _state = AudioPlayerState.idle;
    super.dispose();
  }
}
