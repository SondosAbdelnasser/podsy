import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/episode.dart';
import '../models/user_activity.dart';
import '../services/interest_service.dart';

class RecommendationService {
  final SupabaseClient _supabase;
  final InterestService _interestService;
  static const int _embeddingDimension = 1536; // OpenAI embedding dimension

  RecommendationService(this._supabase) : _interestService = InterestService(_supabase);

  // Track user activity
  Future<void> trackActivity(UserActivity activity) async {
    try {
      await _supabase.from('user_activity').insert(activity.toJson());
      
      // Update interest scores based on activity
      if (activity.type == ActivityType.listen || 
          activity.type == ActivityType.like || 
          activity.type == ActivityType.share || 
          activity.type == ActivityType.complete) {
        await _interestService.calculateInterestScore(activity.userId, activity.episodeId);
      }
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }

  // Get user's recent activities
  Future<List<UserActivity>> getUserActivities(String userId, {int limit = 50}) async {
    try {
      final response = await _supabase
          .from('user_activity')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return response.map((json) => UserActivity.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user activities: $e');
      return [];
    }
  }

  // Get personalized recommendations
  Future<List<Episode>> getPersonalizedRecommendations(String userId, {int limit = 20}) async {
    try {
      // Get user's top interests
      final topInterests = await _interestService.getUserTopInterests(userId);
      final interestIds = topInterests.map((i) => i.id).toList();

      // Get episodes from user's interests
      final response = await _supabase
          .from('episodes')
          .select('*, podcast_collections!inner(*)')
          .inFilter('category_id', interestIds)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((data) => Episode.fromMap(data, data['id'])).toList();
    } catch (e) {
      print('Error getting personalized recommendations: $e');
      return [];
    }
  }

  // Get trending episodes
  Future<List<Episode>> getTrendingEpisodes({int limit = 20}) async {
    try {
      // Get episodes with highest engagement in last 7 days
      final response = await _supabase.rpc('get_trending_episodes', params: {
        'days': 7,
        'limit': limit,
      });

      return response.map((data) => Episode.fromMap(data, data['id'])).toList();
    } catch (e) {
      print('Error getting trending episodes: $e');
      return [];
    }
  }

  // Get similar episodes based on content
  Future<List<Episode>> getSimilarEpisodes(String episodeId, {int limit = 20}) async {
    try {
      // Get episode embedding
      final episode = await _supabase
          .from('episodes')
          .select('embedding')
          .eq('id', episodeId)
          .single();

      if (episode['embedding'] == null) {
        return [];
      }

      // Find similar episodes using vector similarity
      final response = await _supabase.rpc('get_similar_episodes', params: {
        'episode_id': episodeId,
        'limit': limit,
      });

      return response.map((data) => Episode.fromMap(data, data['id'])).toList();
    } catch (e) {
      print('Error getting similar episodes: $e');
      return [];
    }
  }

  // Get recommendations for new users
  Future<List<Episode>> getNewUserRecommendations({int limit = 20}) async {
    try {
      // Get most popular episodes across all categories
      final response = await _supabase.rpc('get_popular_episodes', params: {
        'limit': limit,
      });

      return response.map((data) => Episode.fromMap(data, data['id'])).toList();
    } catch (e) {
      print('Error getting new user recommendations: $e');
      return [];
    }
  }

  // Get recommendations based on listening history
  Future<List<Episode>> getRecommendationsFromHistory(String userId, {int limit = 20}) async {
    try {
      // Get user's recent listening history
      final history = await getUserActivities(userId, limit: 50);
      final episodeIds = history
          .where((activity) => activity.type == ActivityType.listen)
          .map((activity) => activity.episodeId)
          .toList();

      if (episodeIds.isEmpty) {
        return getNewUserRecommendations(limit: limit);
      }

      // Get similar episodes to those in history
      final response = await _supabase.rpc('get_recommendations_from_history', params: {
        'user_id': userId,
        'episode_ids': episodeIds,
        'limit': limit,
      });

      return response.map((data) => Episode.fromMap(data, data['id'])).toList();
    } catch (e) {
      print('Error getting recommendations from history: $e');
      return [];
    }
  }
} 