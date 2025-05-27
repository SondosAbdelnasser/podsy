import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikeProvider with ChangeNotifier {
  final String userId;
  bool _isLiked = false;

  LikeProvider({required this.userId});

  bool get isLiked => _isLiked;

  /// already clicked like wla laa
  Future<void> checkIfLiked(String episodeId) async {
    try {
      final response = await Supabase.instance.client
          .from('likes')
          .select('id')
          .eq('user_id', userId)
          .eq('episode_id', episodeId)
          .maybeSingle();

      _isLiked = response != null;
      notifyListeners();
    } catch (e) {
      print("Error checking like status: $e");
    }
  }

  /// like tany lw msh mawgod 
  Future<void> toggleLike(String episodeId) async {
    if (_isLiked) {
      print('User already liked this episode');
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('likes')
          .insert({
            'user_id': userId,
            'episode_id': episodeId,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select(); // مهم لجلب البيانات بعد الإدخال

      if (response.isEmpty) {
        print('Insert failed');
      } else {
        _isLiked = true;
        notifyListeners();
        print('Like added successfully');
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  /// حذف اللايك (إذا كان موجودًا)
  Future<void> removeLike(String episodeId) async {
    if (!_isLiked) {
      print('User hasn’t liked this episode');
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('episode_id', episodeId);

      if (response == null || (response is List && response.isEmpty)) {
        print('Delete failed');
      } else {
        _isLiked = false;
        notifyListeners();
        print('Like removed successfully');
      }
    } catch (e) {
      print("Error removing like: $e");
    }
  }
}
