import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  // Streams for UI updates
  final ValueNotifier<bool> isPlayingNotifier = ValueNotifier(false);
  final ValueNotifier<Duration> positionNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);
  final ValueNotifier<String?> currentUrlNotifier = ValueNotifier(null);

  void initialize() {
    _audioPlayer.onPositionChanged.listen((position) {
      positionNotifier.value = position;
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      durationNotifier.value = duration;
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      _isPlaying = false;
      isPlayingNotifier.value = false;
      positionNotifier.value = Duration.zero;
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      isPlayingNotifier.value = _isPlaying;
    });
  }

  // ✅ FIXED: Play voice with speaker on
  Future<void> playVoice(File audioFile) async {
    try {
      await stop();

      // ✅ Force speaker on
      await _audioPlayer.setSource(DeviceFileSource(audioFile.path));
      await _audioPlayer.setVolume(1.0);  // Max volume
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);  // Use media player mode
      await _audioPlayer.resume();

      debugPrint('▶️ Playing: ${audioFile.path}');
    } catch (e) {
      debugPrint('❌ Error playing audio: $e');
      rethrow;
    }
  }

  // Alternative: Play from URL directly (without downloading)
  Future<void> playVoiceFromUrl(String url) async {
    try {
      await stop();
      await _audioPlayer.setSource(UrlSource(url));
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
      await _audioPlayer.resume();
      debugPrint('▶️ Playing from URL: $url');
    } catch (e) {
      debugPrint('❌ Error playing from URL: $e');
      rethrow;
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isPlaying = false;
    isPlayingNotifier.value = false;
    positionNotifier.value = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  void dispose() {
    _audioPlayer.dispose();
    isPlayingNotifier.dispose();
    positionNotifier.dispose();
    durationNotifier.dispose();
    currentUrlNotifier.dispose();
  }
}