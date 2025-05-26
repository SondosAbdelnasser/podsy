import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/like.dart';

class LikeService {
  final supabase = Supabase.instance.client;

  Future<void> addLike(String userId, String episodeId) async {
    await supabase.from('likes').insert({
      'user_id': userId,
      'episode_id': episodeId,
    });
  }

  Future<void> removeLike(String userId, String episodeId) async {
    await supabase
        .from('likes')
        .delete()
        .eq('user_id', userId)
        .eq('episode_id', episodeId);
  }

  Future<List<Like>> fetchLikesByUser(String userId) async {
    final response =
        await supabase.from('likes').select().eq('user_id', userId);
    return (response as List)
        .map((data) => Like.fromMap(data, data['id']))
        .toList();
  }

  Future<bool> isLiked(String userId, String episodeId) async {
    final response = await supabase
        .from('likes')
        .select()
        .eq('user_id', userId)
        .eq('episode_id', episodeId);

    return response.isNotEmpty;
  }
}

