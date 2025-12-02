import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _movePlayer = AudioPlayer();
  final AudioPlayer _capturePlayer = AudioPlayer();
  final AudioPlayer _kingPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  final AudioPlayer _losePlayer = AudioPlayer();
  final AudioPlayer _selectPlayer = AudioPlayer();

  SharedPreferences? _prefs;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _soundEnabled = _prefs?.getBool('soundEnabled') ?? true;
    _vibrationEnabled = _prefs?.getBool('vibrationEnabled') ?? true;

    // Set players to low latency mode
    await _movePlayer.setReleaseMode(ReleaseMode.stop);
    await _capturePlayer.setReleaseMode(ReleaseMode.stop);
    await _kingPlayer.setReleaseMode(ReleaseMode.stop);
    await _winPlayer.setReleaseMode(ReleaseMode.stop);
    await _losePlayer.setReleaseMode(ReleaseMode.stop);
    await _selectPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _prefs?.setBool('soundEnabled', enabled);
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _prefs?.setBool('vibrationEnabled', enabled);
  }

  // Sound effects using system sounds for reliability
  Future<void> playMove() async {
    if (!_soundEnabled) return;
    try {
      // Use short click sound
      await _movePlayer.play(
        AssetSource('sounds/move.mp3'),
        volume: 0.5,
      );
    } catch (e) {
      // Fallback to system haptic
      HapticFeedback.lightImpact();
    }
  }

  Future<void> playCapture() async {
    if (!_soundEnabled) return;
    try {
      await _capturePlayer.play(
        AssetSource('sounds/capture.mp3'),
        volume: 0.7,
      );
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> playKing() async {
    if (!_soundEnabled) return;
    try {
      await _kingPlayer.play(
        AssetSource('sounds/king.mp3'),
        volume: 0.8,
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> playWin() async {
    if (!_soundEnabled) return;
    try {
      await _winPlayer.play(
        AssetSource('sounds/win.mp3'),
        volume: 0.8,
      );
    } catch (e) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> playLose() async {
    if (!_soundEnabled) return;
    try {
      await _losePlayer.play(
        AssetSource('sounds/lose.mp3'),
        volume: 0.6,
      );
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> playSelect() async {
    if (!_soundEnabled) return;
    try {
      await _selectPlayer.play(
        AssetSource('sounds/select.mp3'),
        volume: 0.3,
      );
    } catch (e) {
      HapticFeedback.selectionClick();
    }
  }

  // Haptic feedback
  Future<void> vibrateLight() async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator() == true;
      if (hasVibrator) {
        Vibration.vibrate(duration: 20, amplitude: 50);
      } else {
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> vibrateMedium() async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator() == true;
      if (hasVibrator) {
        Vibration.vibrate(duration: 40, amplitude: 100);
      } else {
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> vibrateHeavy() async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator() == true;
      if (hasVibrator) {
        Vibration.vibrate(duration: 80, amplitude: 200);
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
    }
  }

  Future<void> vibratePattern(List<int> pattern) async {
    if (!_vibrationEnabled) return;
    try {
      final hasVibrator = await Vibration.hasVibrator() == true;
      if (hasVibrator) {
        Vibration.vibrate(pattern: pattern);
      }
    } catch (e) {
      // Ignore
    }
  }

  void dispose() {
    _movePlayer.dispose();
    _capturePlayer.dispose();
    _kingPlayer.dispose();
    _winPlayer.dispose();
    _losePlayer.dispose();
    _selectPlayer.dispose();
  }
}
