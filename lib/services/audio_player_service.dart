import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  String? _currentAudioUrl;

  AudioPlayerService() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading = state.processingState == ProcessingState.loading ||
                   state.processingState == ProcessingState.buffering;
      notifyListeners();
    });
  }

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  String? get currentAudioUrl => _currentAudioUrl;

  Future<void> playAudio(String url) async {
    try {
      // If the same audio is already loaded, just resume playback
      if (_currentAudioUrl == url) {
        await _audioPlayer.play();
        return;
      }

      _isLoading = true;
      notifyListeners();

      // Stop any currently playing audio
      await _audioPlayer.stop();
      
      // Set the new audio source
      await _audioPlayer.setUrl(url);
      _currentAudioUrl = url;
      
      // Start playback
      await _audioPlayer.play();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print("Error playing audio: $e");
      rethrow;
    }
  }

  void pauseAudio() {
    _audioPlayer.pause();
  }

  void stopAudio() {
    _audioPlayer.stop();
    _currentAudioUrl = null;
  }

  // ==== two function al kona fakrnhom ready w tl3o ehna albn3mlhom =======

  Future<void> skipForward() async {
    final duration = _audioPlayer.duration ?? Duration.zero;
    final newPosition = _currentPosition + Duration(seconds: 10);
    await _audioPlayer.seek(newPosition > duration ? duration : newPosition);
  }

  Future<void> skipBackward() async {
    final newPosition = _currentPosition - Duration(seconds: 10);
    await _audioPlayer.seek(newPosition.isNegative ? Duration.zero : newPosition);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
