import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interest.dart';

class InterestService {
  final SupabaseClient _supabase;

  InterestService(this._supabase);

  // Get all interests
  Future<List<Interest>> getInterests() async {
    final response = await _supabase.from('categories').select();
    return (response as List)
        .map((item) => Interest.fromMap(item))
        .toList();
  }

  // Update interest scores based on user actions
  Future<void> updateInterestScores(String userId, String categoryId, double score) async {
    try {
      // Get current score
      final currentScore = await _supabase
          .from('user_interests')
          .select('score')
          .eq('user_id', userId)
          .eq('category_id', categoryId)
          .maybeSingle();

      if (currentScore != null) {
        // Update existing score with weighted average
        final newScore = (currentScore['score'] * 0.7) + (score * 0.3);
        await _supabase
            .from('user_interests')
            .update({'score': newScore})
            .eq('user_id', userId)
            .eq('category_id', categoryId);
      } else {
        // Create new interest entry
        await _supabase.from('user_interests').insert({
          'user_id': userId,
          'category_id': categoryId,
          'score': score,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error updating interest scores: $e');
    }
  }

  // Get user's top interests
  Future<List<Interest>> getUserTopInterests(String userId, {int limit = 5}) async {
    try {
      final response = await _supabase
          .from('user_interests')
          .select('category_id, score')
          .eq('user_id', userId)
          .order('score', ascending: false)
          .limit(limit);

      final categoryIds = response.map((item) => item['category_id']).toList();
      
      final categories = await _supabase
          .from('categories')
          .select()
          .inFilter('id', categoryIds);

      return categories.map((item) => Interest.fromMap(item)).toList();
    } catch (e) {
      print('Error getting user top interests: $e');
      return [];
    }
  }

  // Calculate interest score based on user activity
  Future<void> calculateInterestScore(String userId, String episodeId) async {
    try {
      // Get episode categories
      final episodeCategories = await _supabase
          .from('episode_categories')
          .select('category_id')
          .eq('episode_id', episodeId);

      // Get user activity for this episode
      final userActivity = await _supabase
          .from('user_activity')
          .select()
          .eq('user_id', userId)
          .eq('episode_id', episodeId)
          .order('timestamp', ascending: false)
          .limit(1)
          .single();

      // Calculate score based on activity type
      double score = 0;
      switch (userActivity['type']) {
        case 'listen':
          score = 0.5;
          break;
        case 'like':
          score = 1.0;
          break;
        case 'share':
          score = 1.5;
          break;
        case 'complete':
          score = 2.0;
          break;
      }

      // Update scores for each category
      for (var category in episodeCategories) {
        await updateInterestScores(userId, category['category_id'], score);
      }
    } catch (e) {
      print('Error calculating interest score: $e');
    }
  }

  // Get recommended categories based on user interests
  Future<List<Interest>> getRecommendedCategories(String userId) async {
    try {
      // Get user's current interests
      final userInterests = await _supabase
          .from('user_interests')
          .select('category_id, score')
          .eq('user_id', userId)
          .order('score', ascending: false);

      // Get categories that user hasn't shown interest in
      final userCategoryIds = userInterests.map((i) => i['category_id']).toList();
      
      final recommendedCategories = await _supabase
          .from('categories')
          .select()
          .filter('id', 'not.in', userCategoryIds)
          .limit(5);

      return recommendedCategories.map((item) => Interest.fromMap(item)).toList();
    } catch (e) {
      print('Error getting recommended categories: $e');
      return [];
    }
  }
}
