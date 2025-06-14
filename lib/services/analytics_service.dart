import 'package:supabase_flutter/supabase_flutter.dart';

class AnalyticsService {
  final SupabaseClient _supabase;

  AnalyticsService(this._supabase);

  // Track user behavior
  Future<void> trackUserBehavior(String userId, String action, Map<String, dynamic> data) async {
    try {
      await _supabase.from('user_analytics').insert({
        'user_id': userId,
        'action': action,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error tracking user behavior: $e');
    }
  }

  // Get user insights
  Future<Map<String, dynamic>> getUserInsights(String userId) async {
    try {
      // Get listening history
      final listeningHistory = await _supabase
          .from('user_activity')
          .select()
          .eq('user_id', userId)
          .eq('type', 'listen')
          .order('timestamp', ascending: false)
          .limit(100);

      // Get category preferences
      final categoryPreferences = await _supabase
          .from('user_interests')
          .select('category_id, score')
          .eq('user_id', userId)
          .order('score', ascending: false);

      // Get active hours
      final activeHours = await _supabase
          .from('user_activity')
          .select('timestamp')
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(1000);

      // Calculate insights
      final insights = {
        'total_listening_time': _calculateTotalListeningTime(listeningHistory),
        'preferred_categories': _getTopCategories(categoryPreferences),
        'active_hours': _calculateActiveHours(activeHours),
        'engagement_score': _calculateEngagementScore(userId),
      };

      return insights;
    } catch (e) {
      print('Error getting user insights: $e');
      return {};
    }
  }

  // Calculate total listening time
  double _calculateTotalListeningTime(List<dynamic> listeningHistory) {
    double totalTime = 0;
    for (var activity in listeningHistory) {
      totalTime += activity['listen_duration'] ?? 0;
    }
    return totalTime;
  }

  // Get top categories
  List<String> _getTopCategories(List<dynamic> categoryPreferences) {
    return categoryPreferences
        .take(5)
        .map((pref) => pref['category_id'].toString())
        .toList();
  }

  // Calculate active hours
  Map<int, int> _calculateActiveHours(List<dynamic> activities) {
    Map<int, int> hourCounts = {};
    for (var activity in activities) {
      final hour = DateTime.parse(activity['timestamp']).hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }
    return hourCounts;
  }

  // Calculate engagement score
  Future<double> _calculateEngagementScore(String userId) async {
    try {
      // Get all user activities
      final activities = await _supabase
          .from('user_activity')
          .select()
          .eq('user_id', userId)
          .order('timestamp', ascending: false)
          .limit(1000);

      // Calculate score based on different activities
      double score = 0;
      for (var activity in activities) {
        switch (activity['type']) {
          case 'listen':
            score += 1;
            break;
          case 'like':
            score += 2;
            break;
          case 'share':
            score += 3;
            break;
          case 'complete':
            score += 5;
            break;
        }
      }

      return score;
    } catch (e) {
      print('Error calculating engagement score: $e');
      return 0;
    }
  }
} 