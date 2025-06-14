import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import '../models/episode.dart';

class AudioPlayerService extends ChangeNotifier {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _initializeAudioPlayer();
  }

  late AudioPlayer _audioPlayer;
  late AudioSession _audioSession;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  String? _currentAudioUrl;
  Episode? _currentEpisode;
  double _playbackSpeed = 1.0;
  bool _isInitialized = false;
  Timer? _positionUpdateTimer;
  Timer? _retryTimer;
  int _retryCount = 0;
  static const int maxRetries = 3;

  Future<void> _initializeAudioPlayer() async {
    print('[AudioPlayerService] Initializing audio player...');
    try {
      _audioPlayer = AudioPlayer();
      
      // Configure audio session
      _audioSession = await AudioSession.instance;
      await _audioSession.configure(const AudioSessionConfiguration.speech());
      
      // Set up position stream with throttling
      _positionUpdateTimer?.cancel();
      _positionUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isPlaying) {
          _currentPosition = _audioPlayer.position;
          notifyListeners();
        }
      });

      // Set up player state stream
      _audioPlayer.playerStateStream.listen((state) {
        _isPlaying = state.playing;
        _isLoading = state.processingState == ProcessingState.loading ||
                     state.processingState == ProcessingState.buffering;
        notifyListeners();
      });

      // Load saved state
      await _loadSavedState();
      
      _isInitialized = true;
      print('[AudioPlayerService] Initialization complete.');
    } catch (e) {
      print('[AudioPlayerService] Error initializing audio player: $e');
      _retryInitialization();
    }
  }

  void _retryInitialization() {
    if (_retryCount < maxRetries) {
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 2), () {
        _retryCount++;
        _initializeAudioPlayer();
      });
    }
  }

  Future<void> _loadSavedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('last_played_url');
      final savedPosition = prefs.getInt('last_position');
      final savedSpeed = prefs.getDouble('playback_speed');
      // Retrieve episode details if saved
      final savedEpisodeJson = prefs.getString('last_played_episode');
      if (savedEpisodeJson != null) {
        _currentEpisode = Episode.fromMap(jsonDecode(savedEpisodeJson), jsonDecode(savedEpisodeJson)['id']);
      }

      if (savedUrl != null) {
        _currentAudioUrl = savedUrl;
        _playbackSpeed = savedSpeed ?? 1.0;
        await _audioPlayer.setSpeed(_playbackSpeed);
        
        if (savedPosition != null) {
          await _audioPlayer.setUrl(savedUrl);
          await _audioPlayer.seek(Duration(milliseconds: savedPosition));
        }
      }
    } catch (e) {
      print("Error loading saved state: $e");
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentAudioUrl != null) {
        await prefs.setString('last_played_url', _currentAudioUrl!);
        await prefs.setInt('last_position', _currentPosition.inMilliseconds);
        await prefs.setDouble('playback_speed', _playbackSpeed);
        // Save episode details
        if (_currentEpisode != null && _currentEpisode!.id != null) {
          await prefs.setString('last_played_episode', jsonEncode(_currentEpisode!.toMap()));
        }
      }
    } catch (e) {
      print("Error saving state: $e");
    }
  }

  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  String? get currentAudioUrl => _currentAudioUrl;
  Episode? get currentEpisode => _currentEpisode;
  double get playbackSpeed => _playbackSpeed;
  bool get isInitialized => _isInitialized;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  Future<void> playAudio(String url, {Episode? episode}) async {
    print('[AudioPlayerService] playAudio called. isInitialized=$_isInitialized');
    if (!_isInitialized) {
      print('[AudioPlayerService] Not initialized. playAudio ignored.');
      return;
    }
    try {
      // If the same audio is already loaded, just resume playback
      if (_currentAudioUrl == url) {
        await _audioPlayer.play();
        _currentEpisode = episode ?? _currentEpisode;
        notifyListeners();
        return;
      }
      _isLoading = true;
      notifyListeners();
      // Stop any currently playing audio
      await _audioPlayer.stop();
      // Set the new audio source
      await _audioPlayer.setUrl(url);
      _currentAudioUrl = url;
      _currentEpisode = episode;
      // Start playback
      await _audioPlayer.play();
      _isLoading = false;
      notifyListeners();
      // Save state
      await _saveState();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('[AudioPlayerService] Error playing audio: $e');
      rethrow;
    }
  }

  Future<void> pauseAudio() async {
    print('[AudioPlayerService] pauseAudio called. isInitialized=$_isInitialized');
    if (!_isInitialized) {
      print('[AudioPlayerService] Not initialized. pauseAudio ignored.');
      return;
    }
    try {
      await _audioPlayer.pause();
      await _saveState();
    } catch (e) {
      print('[AudioPlayerService] Error pausing audio: $e');
    }
  }

  Future<void> stopAudio() async {
    print('[AudioPlayerService] stopAudio called. isInitialized=$_isInitialized');
    if (!_isInitialized) {
      print('[AudioPlayerService] Not initialized. stopAudio ignored.');
      return;
    }
    try {
      await _audioPlayer.stop();
      _currentAudioUrl = null;
      _currentEpisode = null;
      await _saveState();
    } catch (e) {
      print('[AudioPlayerService] Error stopping audio: $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    print('[AudioPlayerService] setPlaybackSpeed called. isInitialized=$_isInitialized');
    if (!_isInitialized) {
      print('[AudioPlayerService] Not initialized. setPlaybackSpeed ignored.');
      return;
    }
    try {
      _playbackSpeed = speed;
      await _audioPlayer.setSpeed(speed);
      await _saveState();
      notifyListeners();
    } catch (e) {
      print('[AudioPlayerService] Error setting playback speed: $e');
    }
  }

  Future<void> skipForward() async {
    print('[AudioPlayerService] skipForward called. isInitialized=$_isInitialized');
    if (!_isInitialized) {
      print('[AudioPlayerService] Not initialized. skipForward ignored.');
      return;
    }
    try {
      final duration = _audioPlayer.duration ?? Duration.zero;
      final newPosition = _currentPosition + Duration(seconds: 10);
      await _audioPlayer.seek(newPosition > duration ? duration : newPosition);
      await _saveState();
    } catch (e) {
      print('[AudioPlayerService] Error skipping forward: $e');
    }
  }

  Future<void> skipBackward() async {
    print('[AudioPlayerService] skipBackward called. isInitialized=$_isInitialized');
    if (!_isInitialized) {
      print('[AudioPlayerService] Not initialized. skipBackward ignored.');
      return;
    }
    try {
      final newPosition = _currentPosition - Duration(seconds: 10);
      await _audioPlayer.seek(newPosition.isNegative ? Duration.zero : newPosition);
      await _saveState();
    } catch (e) {
      print('[AudioPlayerService] Error skipping backward: $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    print('[AudioPlayerService] seekTo called. isInitialized=$_isInitialized');
    if (!_isInitialized) {
      print('[AudioPlayerService] Not initialized. seekTo ignored.');
      return;
    }
    try {
      await _audioPlayer.seek(position);
      await _saveState();
    } catch (e) {
      print('[AudioPlayerService] Error seeking: $e');
    }
  }

  @override
  void dispose() {
    _positionUpdateTimer?.cancel();
    _retryTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}
