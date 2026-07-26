import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to handle game sound effects.
///
/// Requires audio files in `assets/audio/`:
/// - success.mp3
/// - error.mp3
/// - victory.mp3
/// - game_start.mp3
class SoundManager {
  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;

  bool get isMuted => _muted;

  void toggleMute() {
    _muted = !_muted;
  }

  Future<void> playSuccess() async {
    if (_muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/success.mp3'));
    } catch (e) {
      if (kDebugMode) debugPrint('Error playing success sound: $e');
    }
  }

  Future<void> playError() async {
    if (_muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/error.mp3'));
    } catch (e) {
      if (kDebugMode) debugPrint('Error playing error sound: $e');
    }
  }

  Future<void> playVictory() async {
    if (_muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/victory.mp3'));
    } catch (e) {
      if (kDebugMode) debugPrint('Error playing victory sound: $e');
    }
  }

  Future<void> playGameStart() async {
    if (_muted) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('audio/game_start.mp3'));
    } catch (e) {
      if (kDebugMode) debugPrint('Error playing game start sound: $e');
    }
  }
}

final soundManagerProvider = Provider<SoundManager>((ref) {
  return SoundManager();
});
