// lib/services/like_service.dart

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

    final response = await Supabase.instance.client
        .from('likes')
        .insert(like.toMap())
        .execute();

    if (response.error == null) {
      _isLiked = true;
      notifyListeners();
      print('Like saved');
    } else {
      print('Error saving like: ${response.error?.message}');
    }
  }

  Future<void> checkIfLiked(String episodeId) async {
    final response = await Supabase.instance.client
        .from('likes')
        .select('id')
        .eq('user_id', userId)
        .eq('episode_id', episodeId)
        .single()
        .execute();

    _isLiked = response.data != null;
    notifyListeners();
  }
}