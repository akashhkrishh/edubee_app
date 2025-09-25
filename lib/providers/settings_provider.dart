import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:edubee_app/services/background_music_service.dart';

class SettingsProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _fontScaleKey = 'font_scale';
  static const String _isMusicEnabledKey = 'is_music_enabled';
  static const String _isSfxEnabledKey = 'is_sfx_enabled';

  late SharedPreferences _prefs;
  bool _isInitialized = false;
  final BackgroundMusicService _musicService = BackgroundMusicService();

  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;
  bool _isMusicEnabled = true;
  bool _isSfxEnabled = true;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSfxEnabled => _isSfxEnabled;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final themeModeString = _prefs.getString(_themeModeKey);
      if (themeModeString != null) {
        _themeMode = ThemeMode.values.firstWhere(
              (e) => e.toString() == themeModeString,
          orElse: () => ThemeMode.system,
        );
      }
      _fontScale = _prefs.getDouble(_fontScaleKey) ?? 1.0;
      _isMusicEnabled = _prefs.getBool(_isMusicEnabledKey) ?? true;
      _isSfxEnabled = _prefs.getBool(_isSfxEnabledKey) ?? true;
      _isInitialized = true;
      if (_isMusicEnabled) {
        await _musicService.playBackgroundMusic();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
      _themeMode = ThemeMode.system;
      _fontScale = 1.0;
      _isMusicEnabled = true;
      _isSfxEnabled = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.toString());
    notifyListeners();
  }

  Future<void> setFontScale(double scale) async {
    _fontScale = scale;
    await _prefs.setDouble(_fontScaleKey, scale);
    notifyListeners();
  }

  Future<void> setMusicEnabled(bool enabled) async {
    _isMusicEnabled = enabled;
    await _prefs.setBool(_isMusicEnabledKey, enabled);
    if (enabled) {
      await _musicService.playBackgroundMusic();
    } else {
      await _musicService.stopBackgroundMusic();
    }
    notifyListeners();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _isSfxEnabled = enabled;
    await _prefs.setBool(_isSfxEnabledKey, enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _musicService.dispose();
    super.dispose();
  }
}