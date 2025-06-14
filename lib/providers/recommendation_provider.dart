import 'package:flutter/foundation.dart';
import '../services/recommendation_service.dart';
import '../models/episode.dart';
import '../models/user_activity.dart';
import '../providers/auth_provider.dart';
import 'package:flutter/material.dart';

class RecommendationProvider extends ChangeNotifier {
  final RecommendationService _recommendationService;
  final AuthProvider _authProvider;
  List<Episode> _recommendations = [];
  List<Episode> _trendingEpisodes = [];
  List<Episode> _similarEpisodes = [];
  bool _isLoading = false;
  String? _error;

  RecommendationProvider(this._recommendationService, this._authProvider);

  List<Episode> get recommendations => _recommendations;
  List<Episode> get trendingEpisodes => _trendingEpisodes;
  List<Episode> get similarEpisodes => _similarEpisodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadRecommendations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _authProvider.currentUser?.id;
      if (userId == null) {
        _error = 'User not authenticated';
        return;
      }

      _recommendations = await _recommendationService.getPersonalizedRecommendations(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
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

  Future<void> refreshRecommendations() async {
    await loadRecommendations();
  }

  Future<void> trackEpisodeInteraction(String episodeId, ActivityType type) async {
    try {
      final userId = _authProvider.currentUser?.id;
      if (userId == null) return;

      await _recommendationService.trackActivity(UserActivity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        episodeId: episodeId,
        type: type,
        timestamp: DateTime.now(),
      ));

      // Refresh recommendations after tracking activity
      await loadRecommendations();
    } catch (e) {
      debugPrint('Error tracking episode interaction: $e');
    }
  }
} 