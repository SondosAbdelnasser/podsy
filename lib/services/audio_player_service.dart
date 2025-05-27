import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;

  AudioPlayerService() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
  }

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;

  Future<void> playAudio(String url) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
      _isPlaying = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Error playing audio: $e");
    }
  }

  void pauseAudio() {
    _audioPlayer.pause();
    _isPlaying = false;
    notifyListeners();
  }

  void stopAudio() {
    _audioPlayer.stop();
    _isPlaying = false;
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
    _audioPlayer.dispose();
  }
}
