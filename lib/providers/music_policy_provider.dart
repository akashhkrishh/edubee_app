import 'package:flutter/foundation.dart';

class MusicPolicyProvider with ChangeNotifier {
  bool _isMusicAllowed = true;
  bool get isMusicAllowed => _isMusicAllowed;

  void setMusicAllowed(bool allowed) {
    if (_isMusicAllowed != allowed) {
      _isMusicAllowed = allowed;
      notifyListeners();
    }
  }
}