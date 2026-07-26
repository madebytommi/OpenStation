import 'dart:async';
import 'package:media_kit/media_kit.dart';

abstract class AudioPlayerAdapter {
  Stream<bool> get playing;
  Stream<bool> get buffering;
  Stream<bool> get completed;
  Stream<String> get error;
  Stream<Track> get track;
  Stream<PlayerLog> get log;
  bool get isPlaying;
  bool get isBuffering;

  Future<void> open(Media media);
  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

class MediaKitPlayerAdapter implements AudioPlayerAdapter {
  final Player _player;

  MediaKitPlayerAdapter({Player? player})
    : _player =
          player ??
          Player(
            configuration: const PlayerConfiguration(
              logLevel: MPVLogLevel.trace,
            ),
          );

  @override
  Stream<bool> get playing => _player.stream.playing;

  @override
  Stream<bool> get buffering => _player.stream.buffering;

  @override
  Stream<bool> get completed => _player.stream.completed;

  @override
  Stream<String> get error => _player.stream.error;

  @override
  Stream<Track> get track => _player.stream.track;

  @override
  Stream<PlayerLog> get log => _player.stream.log;

  @override
  bool get isPlaying => _player.state.playing;

  @override
  bool get isBuffering => _player.state.buffering;

  @override
  Future<void> open(Media media) => _player.open(media);

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() => _player.dispose();
}
