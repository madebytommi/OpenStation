import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:open_station/models/station.dart';
import 'package:open_station/services/audio_player_adapter.dart';
import 'package:open_station/services/recent_stations_service.dart';

enum AudioPlayerState { idle, connecting, playing, paused, stopped, failed }

class AudioPlayerService extends ChangeNotifier {
  static const Duration stationConnectionTimeout = Duration(seconds: 10);
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

  Duration _connectionTimeout = stationConnectionTimeout;
  void Function(Station)? _recentStationCallback;

  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _logSub;
  StreamSubscription? _trackSub;

  final ValueNotifier<String?> currentMetadata = ValueNotifier<String?>(null);

  AudioPlayerService._internal({
    AudioPlayerAdapter? adapter,
    Duration connectionTimeout = stationConnectionTimeout,
    void Function(Station)? recentStationCallback,
  }) : _player = adapter {
    _connectionTimeout = connectionTimeout;
    _recentStationCallback = recentStationCallback;
  }

  @visibleForTesting
  static AudioPlayerService createForTesting({
    required AudioPlayerAdapter adapter,
    Duration connectionTimeout = stationConnectionTimeout,
    void Function(Station)? recentStationCallback,
  }) {
    final service = AudioPlayerService._internal(
      adapter: adapter,
      connectionTimeout: connectionTimeout,
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

    // Note on request-token binding and shared-player events:
    // 1. The token prevents callbacks owned by superseded listeners from acting.
    // 2. The underlying player events are not tagged with a station or request identity.
    // 3. Post-connection error handling must therefore confirm that the current active 
    //    playback actually stopped or became unusable before failing the active station.

    _playingSub = _player!.playing.listen((playing) {
      if (token != _playRequestToken) return;

      if (_state == AudioPlayerState.connecting) {
        return; // playing=false should not expose Paused while connecting.
      }

      if (playing) {
        if (!_player!.isBuffering) {
          _setState(AudioPlayerState.playing);
          if (_pendingFatalError != null) {
            _pendingFatalError = null;
            _errorSettleTimer?.cancel();
          }
        }
      } else {
        if (_pendingFatalError != null && _activePlaybackToken == token) {
          _finalizeFatalError(token);
        } else if (_state == AudioPlayerState.playing) {
          _setState(AudioPlayerState.paused);
        }
      }
    });

    _bufferingSub = _player!.buffering.listen((buffering) {
      if (token != _playRequestToken) return;
      if (buffering) {
        _setState(AudioPlayerState.connecting);
      } else if (_player!.isPlaying) {
        _setState(AudioPlayerState.playing);
      }
    });

    _completedSub = _player!.completed.listen((completed) {
      if (token != _playRequestToken) return;
      if (completed) {
        _activePlaybackToken = -1;
        _pendingFatalError = null;
        _errorSettleTimer?.cancel();
        currentMetadata.value = null;
        _setState(AudioPlayerState.stopped);
      }
    });

    _errorSub = _player!.error.listen((errorStr) {
      if (token != _playRequestToken) return;
      if (errorStr.isNotEmpty && _activePlaybackToken == token) {
        _pendingFatalError = errorStr;
        // A short bounded backend-settling window is required because the shared stream
        // might emit an error shortly before emitting playing=false, or it might be a spurious
        // error while playback successfully continues. We wait 100ms to observe if the player
        // actually stopped.
        _errorSettleTimer?.cancel();
        _errorSettleTimer = Timer(const Duration(milliseconds: 100), () {
          if (_pendingFatalError != null && _activePlaybackToken == token) {
            if (!_player!.isPlaying) {
              _finalizeFatalError(token);
            } else {
              _pendingFatalError = null; // Active playback continues normally
            }
          }
        });
      }
    });

    _trackSub = _player!.track.listen((track) {
      if (token != _playRequestToken) return;
      String? title = track.audio.title;
      if (title != null) {
        title = title.trim();
        if (title.isEmpty) title = null;
      }
      currentMetadata.value = title;
    });

    _logSub = _player!.log.listen((event) {
      if (token != _playRequestToken) return;
      final text = event.text.toLowerCase();
      if (text.contains('icy-title:')) {
        final parts = event.text.split(
          RegExp(r'icy-title:\s*', caseSensitive: false),
        );
        if (parts.length > 1) {
          String title = parts[1].trim();
          if (title.isEmpty) {
            currentMetadata.value = null;
          } else {
            currentMetadata.value = title;
          }
        }
      }
    });
  }

  void _finalizeFatalError(int token) {
    if (token != _playRequestToken) return;
    if (_activePlaybackToken != token) return;
    if (_pendingFatalError == null) return;

    _activePlaybackToken = -1;
    _pendingFatalError = null;
    _errorSettleTimer?.cancel();

    currentMetadata.value = null;
    
    // Stop the player without allowing the resulting stop event to overwrite Failed.
    // ignore: unawaited_futures
    _player!.stop();
    
    _lastError = postConnectionFailureMessage;
    _setState(AudioPlayerState.failed);
  }

  void _recordRecentStation(Station station) {
    if (_recentStationCallback != null) {
      _recentStationCallback!(station);
    } else {
      RecentStationsService().addRecentStation(station);
    }
  }

  void _setState(AudioPlayerState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> playStation(Station station) async {
    _activePlaybackToken = -1;
    _pendingFatalError = null;
    _errorSettleTimer?.cancel();
    
    _currentStation = station;
    final currentToken = ++_playRequestToken;

    final resolved = station.resolvedUrl.trim();
    final original = station.url.trim();

    final List<String> candidates = [];
    if (resolved.isNotEmpty) {
      candidates.add(resolved);
    }
    if (original.isNotEmpty && original != resolved) {
      candidates.add(original);
    }

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

    if (currentToken != _playRequestToken) return;

    _bindPlayerEvents(currentToken);

    _setState(AudioPlayerState.connecting);

    bool success = false;

    for (int i = 0; i < candidates.length; i++) {
      if (currentToken != _playRequestToken) return;

      currentMetadata.value = null;
      final candidateUrl = candidates[i];

      final attemptSuccess = await _attemptCandidate(
        candidateUrl,
        currentToken,
      );
      if (currentToken != _playRequestToken) return;

      if (attemptSuccess) {
        success = true;
        break;
      } else {
        if (i < candidates.length - 1) {
          await _player!.stop();
          currentMetadata.value = null;
        }
      }
    }

    if (currentToken != _playRequestToken) return;

    if (success) {
      _activePlaybackToken = currentToken;
      _recordRecentStation(_currentStation!);
    } else {
      _activePlaybackToken = -1;
      _pendingFatalError = null;
      _errorSettleTimer?.cancel();
      currentMetadata.value = null;
      _lastError = stableFailureMessage;
      _setState(AudioPlayerState.failed);
    }
  }

  Future<bool> _attemptCandidate(String url, int token) async {
    if (token != _playRequestToken) return false;

    final Completer<bool> completer = Completer<bool>();
    Timer? timer;
    StreamSubscription? playSub;
    StreamSubscription? errSub;

    void cleanup() {
      timer?.cancel();
      playSub?.cancel();
      errSub?.cancel();
    }

    void finish(bool val) {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete(val);
      }
    }

    playSub = _player!.playing.listen((playing) {
      if (token != _playRequestToken) {
        finish(false);
      } else if (playing) {
        finish(true);
      }
    });

    errSub = _player!.error.listen((err) {
      if (token != _playRequestToken) {
        finish(false);
      } else if (err.isNotEmpty) {
        finish(false);
      }
    });

    timer = Timer(_connectionTimeout, () {
      finish(false);
    });

    try {
      await _player!.open(
        Media(url, httpHeaders: const {'User-Agent': 'OpenStation/0.1'}),
      );

      if (token != _playRequestToken) {
        finish(false);
        return false;
      }

      await _player!.setVolume(_volume * 100);

      if (_player!.isPlaying) {
        finish(true);
      }
    } catch (e) {
      finish(false);
    }

    final result = await completer.future;
    cleanup();
    return result;
  }

  Future<void> playUrl(String url) async {
    final station = Station(
      uuid: 'direct-url',
      name: 'Direct URL',
      url: url,
      resolvedUrl: url,
    );
    await playStation(station);
  }

  Future<void> pause() async {
    if (_player != null) {
      await _player!.pause();
      _setState(AudioPlayerState.paused);
    }
  }

  Future<void> resume() async {
    if (_player != null) {
      await _player!.play();
      _setState(AudioPlayerState.playing);
    }
  }

  Future<void> stop() async {
    _activePlaybackToken = -1;
    _pendingFatalError = null;
    _errorSettleTimer?.cancel();
    
    _playRequestToken++;
    currentMetadata.value = null;
    if (_player != null) {
      await _player!.stop();
      _setState(AudioPlayerState.stopped);
    }
  }

  Future<void> setVolume(double vol) async {
    _volume = vol;
    if (_player != null) {
      await _player!.setVolume(vol * 100);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _activePlaybackToken = -1;
    _pendingFatalError = null;
    _errorSettleTimer?.cancel();
    
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

    _player?.dispose();
    _player = null;
    _state = AudioPlayerState.idle;
    super.dispose();
  }
}
