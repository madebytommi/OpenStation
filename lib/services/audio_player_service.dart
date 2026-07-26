import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:open_station/models/station.dart';
import 'package:open_station/services/recent_stations_service.dart';

enum AudioPlayerState { idle, connecting, playing, paused, stopped, failed }

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  Player? _player;
  AudioPlayerState _state = AudioPlayerState.idle;
  Station? _currentStation;
  String _lastError = '';
  double _volume = 1.0;
  int _playRequestToken = 0;

  StreamSubscription? _playingSub;
  StreamSubscription? _bufferingSub;
  StreamSubscription? _completedSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _logSub;
  StreamSubscription? _trackSub;

  final ValueNotifier<String?> currentMetadata = ValueNotifier<String?>(null);

  AudioPlayerService._internal();

  AudioPlayerState get state => _state;
  Station? get currentStation => _currentStation;
  String get lastError => _lastError;
  double get volume => _volume;

  Future<void> init() async {
    if (_player != null) return;

    _player = Player(
      configuration: const PlayerConfiguration(logLevel: MPVLogLevel.trace),
    );

    _playingSub = _player!.stream.playing.listen((playing) {
      if (playing) {
        if (!_player!.state.buffering) {
          _setState(AudioPlayerState.playing);
          if (_currentStation != null) {
            RecentStationsService().addRecentStation(_currentStation!);
          }
        }
      } else if (_state == AudioPlayerState.playing ||
          _state == AudioPlayerState.connecting) {
        _setState(AudioPlayerState.paused);
      }
    });

    _bufferingSub = _player!.stream.buffering.listen((buffering) {
      if (buffering) {
        _setState(AudioPlayerState.connecting);
      } else if (_player!.state.playing) {
        _setState(AudioPlayerState.playing);
      }
    });

    _completedSub = _player!.stream.completed.listen((completed) {
      if (completed) {
        currentMetadata.value = null;
        _setState(AudioPlayerState.stopped);
      }
    });

    _errorSub = _player!.stream.error.listen((errorStr) {
      if (errorStr.isNotEmpty) {
        currentMetadata.value = null;
        _lastError = errorStr;
        _setState(AudioPlayerState.failed);
      }
    });

    _trackSub = _player!.stream.track.listen((track) {
      String? title = track.audio.title;
      if (title != null) {
        title = title.trim();
        if (title.isEmpty) title = null;
      }
      currentMetadata.value = title;
    });

    _logSub = _player!.stream.log.listen((event) {
      final text = event.text.toLowerCase();
      if (event.level == 'error' ||
          text.contains('error') ||
          text.contains('failed')) {
        _lastError = event.text;
        currentMetadata.value = null;
        notifyListeners();
      } else if (text.contains('icy-title:')) {
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

  void _setState(AudioPlayerState s) {
    _state = s;
    notifyListeners();
  }

  Future<void> playStation(Station station) async {
    _currentStation = station;

    await playUrl(
      station.resolvedUrl.isNotEmpty ? station.resolvedUrl : station.url,
    );
  }

  Future<void> playUrl(String url) async {
    final currentToken = ++_playRequestToken;
    _lastError = '';
    currentMetadata.value = null;

    if (_player == null) {
      await init();
    } else {
      await _player!.stop();
    }

    if (currentToken != _playRequestToken) return;

    _setState(AudioPlayerState.connecting);

    try {
      await _player!.open(
        Media(url, httpHeaders: {'User-Agent': 'OpenStation/0.1'}),
      );

      if (currentToken != _playRequestToken) {
        await _player!.stop();
        return;
      }

      await _player!.setVolume(_volume * 100);
    } catch (e) {
      if (currentToken != _playRequestToken) return;
      _lastError = e.toString();
      _setState(AudioPlayerState.failed);
    }
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
