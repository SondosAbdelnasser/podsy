import 'package:flutter/material.dart';
import '../models/like.dart';
import '../services/like_service.dart';

class LikeProvider with ChangeNotifier {
  final LikeService _likeService = LikeService();
  List<Like> _likes = [];

  List<Like> get likes => _likes;

  Future<void> loadLikes(String userId) async {
    _likes = await _likeService.fetchLikesByUser(userId);
    notifyListeners();
  }

  bool isEpisodeLiked(String episodeId) {
    return _likes.any((like) => like.episodeId == episodeId);
  }

  Future<void> toggleLike(String userId, String episodeId) async {
    final isLiked = isEpisodeLiked(episodeId);
    if (isLiked) {
      await _likeService.removeLike(userId, episodeId);
      _likes.removeWhere((like) => like.episodeId == episodeId);
    } else {
      await _likeService.addLike(userId, episodeId);
      await loadLikes(userId); // Refresh from backend
    }
    notifyListeners();
  }
}
