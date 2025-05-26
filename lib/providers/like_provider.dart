// lib/providers/like_provider.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikeProvider with ChangeNotifier {
  final String userId;
  bool _isLiked = false;

  LikeProvider({required this.userId});

  bool get isLiked => _isLiked;

  // Check if the user already liked the episode
  Future<void> checkIfLiked(String episodeId) async {
    try {
      final response = await Supabase.instance.client
          .from('likes')
          .select('id')
          .eq('user_id', userId)
          .eq('episode_id', episodeId)
          .single()
          .execute();

      _isLiked = response.data != null;
      notifyListeners(); // Notifies listeners about the state change
    } catch (e) {
      print("Error checking like status: $e");
    }
  }

  // Toggle the like status (like/unlike)
  Future<void> toggleLike(String episodeId) async {
    if (_isLiked) {
      print('User already liked this episode');
      return;
    }

    // Add like to Supabase
    try {
      final response = await Supabase.instance.client
          .from('likes')
          .insert({
            'user_id': userId,
            'episode_id': episodeId,
            'created_at': DateTime.now().toIso8601String(),
          })
         // .execute();

      if (response.error == null) {
        _isLiked = true;
        notifyListeners(); // Notifies listeners that the like state changed
        print('Like added successfully');
      } else {
        print('Error adding like: ${response.error?.message}');
      }
    } catch (e) {
      print("Error toggling like: $e");
    }
  }

  // Unlike an episode (remove like)
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
          .eq('episode_id', episodeId)
          //.execute();

      if (response.error == null) {
        _isLiked = false;
        notifyListeners(); // Notifies listeners that the like state changed
        print('Like removed successfully');
      } else {
        print('Error removing like: ${response.error?.message}');
      }
    } catch (e) {
      print("Error removing like: $e");
    }
  }
}
