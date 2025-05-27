import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../models/like.dart';

class LikeService extends ChangeNotifier {
  final String userId;
  bool _isLiked = false;

  LikeService({required this.userId});

  bool get isLiked => _isLiked;

  Future<void> toggleLike(String episodeId) async {
    if (_isLiked) {
      print("User already liked this episode.");
      return;
    }

    final like = Like(
      id: '',
      userId: userId,
      episodeId: episodeId,
      createdAt: DateTime.now(),
    );

    try {
      final response = await Supabase.instance.client
          .from('likes')
          .insert(like.toMap())
          .select();

      if (response.isEmpty) {
        print('Insertion failed');
      } else {
        _isLiked = true;
        notifyListeners();
        print('Like saved: $response');
      }
    } catch (e) {
      print('Error inserting like: $e');
    }
  }

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
      print('Error checking like: $e');
    }
  }
}
