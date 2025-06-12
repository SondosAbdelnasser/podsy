import 'package:flutter/foundation.dart';
import '../services/recommendation_service.dart';
import '../models/episode.dart';
import '../models/user_activity.dart';

class RecommendationProvider with ChangeNotifier {
  final RecommendationService _recommendationService;
  List<Episode> _recommendations = [];
  List<Episode> _trendingEpisodes = [];
  List<Episode> _similarEpisodes = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  RecommendationProvider(this._recommendationService);

  List<Episode> get recommendations => _recommendations;
  List<Episode> get trendingEpisodes => _trendingEpisodes;
  List<Episode> get similarEpisodes => _similarEpisodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setCurrentUser(String userId) {
    _currentUserId = userId;
  }

  Future<void> loadRecommendations() async {
    if (_currentUserId == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recommendations = await _recommendationService.getRecommendations(_currentUserId!);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadTrendingEpisodes() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _trendingEpisodes = await _recommendationService.getTrendingEpisodes();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadSimilarEpisodes(String episodeId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _similarEpisodes = await _recommendationService.getSimilarEpisodes(episodeId);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> trackActivity(UserActivity activity) async {
    try {
      await _recommendationService.trackActivity(activity);
      // Optionally reload recommendations after tracking activity
      await loadRecommendations();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
} 