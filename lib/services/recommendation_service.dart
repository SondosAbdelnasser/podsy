import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/episode.dart';
import '../models/user_activity.dart';

class RecommendationService {
  final SupabaseClient _supabase;
  static const int _embeddingDimension = 1536; // OpenAI embedding dimension

  RecommendationService(this._supabase);

  // Track user activity
  Future<void> trackActivity(UserActivity activity) async {
    await _supabase.from('user_activity').insert(activity.toJson());
  }

  // Get user's recent activities
  Future<List<UserActivity>> getUserActivities(String userId, {int limit = 50}) async {
    final response = await _supabase
        .from('user_activity')
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: false)
        .limit(limit);

    return response.map((json) => UserActivity.fromJson(json)).toList();
  }

  // Get user's listening history with embeddings
  Future<List<Episode>> getUserListeningHistory(String userId) async {
    final response = await _supabase.rpc('get_user_listening_history', params: {
      'user_id': userId,
      'limit': 50,
    });

    return response.map((data) => Episode.fromMap(data, data['id'])).toList();
  }

  // Get recommendations based on user's listening history
  Future<List<Episode>> getRecommendations(String userId, {int limit = 20}) async {
    final response = await _supabase.rpc('get_episode_recommendations', params: {
      'user_id': userId,
      'limit': limit,
    });

    return response.map((data) => Episode.fromMap(data, data['id'])).toList();
  }

  // Get similar episodes to a given episode
  Future<List<Episode>> getSimilarEpisodes(String episodeId, {int limit = 20}) async {
    final response = await _supabase.rpc('get_similar_episodes', params: {
      'episode_id': episodeId,
      'limit': limit,
    });

    return response.map((data) => Episode.fromMap(data, data['id'])).toList();
  }

  // Get trending episodes based on recent activity
  Future<List<Episode>> getTrendingEpisodes({int limit = 20}) async {
    final response = await _supabase.rpc('get_trending_episodes', params: {
      'limit': limit,
    });

    return response.map((data) => Episode.fromMap(data, data['id'])).toList();
  }
} 