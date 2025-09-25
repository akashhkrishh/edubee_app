import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class BackgroundMusicService {
  static final BackgroundMusicService _instance = BackgroundMusicService._internal();
  factory BackgroundMusicService() => _instance;
  BackgroundMusicService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _wasPlaying = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.setVolume(0.5);
    _isInitialized = true;
  }

  Future<void> playBackgroundMusic() async {
    try {
      await initialize();
      await _audioPlayer.play(AssetSource('bgm.mp3'));
      _wasPlaying = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error playing background music: $e');
      }
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      if (_isInitialized) {
        _wasPlaying = _audioPlayer.state == PlayerState.playing;
        await _audioPlayer.pause();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error pausing background music: $e');
      }
    }
  }

  Future<void> resumeBackgroundMusic() async {
    try {
      if (_isInitialized && _wasPlaying) {
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resuming background music: $e');
      }
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _audioPlayer.stop();
      _wasPlaying = false;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping background music: $e');
      }
    }
  }

  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _isInitialized = false;
    _wasPlaying = false;
  }
}