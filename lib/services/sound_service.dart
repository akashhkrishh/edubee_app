import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:edubee_app/core/error/error_service.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  final AudioPlayer _correctPlayer = AudioPlayer();
  final AudioPlayer _incorrectPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isCorrectPlayerReady = false;
  bool _isIncorrectPlayerReady = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Set release mode and volume
      await _correctPlayer.setReleaseMode(ReleaseMode.release);
      await _incorrectPlayer.setReleaseMode(ReleaseMode.release);
      await _correctPlayer.setVolume(0.7);
      await _incorrectPlayer.setVolume(0.7);

      // Preload audio assets
      await _correctPlayer.setSource(AssetSource('correct.mp3'));
      await _incorrectPlayer.setSource(AssetSource('incorrect.mp3'));

      _isCorrectPlayerReady = true;
      _isIncorrectPlayerReady = true;
      _isInitialized = true;

      if (kDebugMode) {
        print('SoundService initialized successfully');
      }
    } catch (e, stackTrace) {
      _isInitialized = false;
      _isCorrectPlayerReady = false;
      _isIncorrectPlayerReady = false;
      ErrorService.handleError(e, stackTrace);
      if (kDebugMode) {
        print('Error initializing SoundService: $e');
      }
    }
  }

  Future<void> playCorrectSound() async {
    if (!_isInitialized || !_isCorrectPlayerReady) {
      await initialize();
      if (!_isInitialized) {
        if (kDebugMode) {
          print('Cannot play correct sound: SoundService not initialized');
        }
        return;
      }
    }

    try {
      await _correctPlayer.stop();
      await _correctPlayer.play(AssetSource('correct.mp3'));
      if (kDebugMode) {
        print('Playing correct sound');
      }
    } catch (e, stackTrace) {
      _isCorrectPlayerReady = false;
      ErrorService.handleError(e, stackTrace);
      if (kDebugMode) {
        print('Error playing correct sound: $e');
      }
    }
  }

  Future<void> playIncorrectSound() async {
    if (!_isInitialized || !_isIncorrectPlayerReady) {
      await initialize();
      if (!_isInitialized) {
        if (kDebugMode) {
          print('Cannot play incorrect sound: SoundService not initialized');
        }
        return;
      }
    }

    try {
      await _incorrectPlayer.stop();
      await _incorrectPlayer.play(AssetSource('incorrect.mp3'));
      if (kDebugMode) {
        print('Playing incorrect sound');
      }
    } catch (e, stackTrace) {
      _isIncorrectPlayerReady = false;
      ErrorService.handleError(e, stackTrace);
      if (kDebugMode) {
        print('Error playing incorrect sound: $e');
      }
    }
  }

  Future<void> dispose() async {
    try {
      await _correctPlayer.stop();
      await _incorrectPlayer.stop();
      await _correctPlayer.release();
      await _incorrectPlayer.release();
      await _correctPlayer.dispose();
      await _incorrectPlayer.dispose();
      _isInitialized = false;
      _isCorrectPlayerReady = false;
      _isIncorrectPlayerReady = false;
      if (kDebugMode) {
        print('SoundService disposed');
      }
    } catch (e, stackTrace) {
      ErrorService.handleError(e, stackTrace);
      if (kDebugMode) {
        print('Error disposing SoundService: $e');
      }
    }
  }
}