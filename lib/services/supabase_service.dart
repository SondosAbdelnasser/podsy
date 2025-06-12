import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  Future<void> storeEmbedding({
    required String episodeId,
    required List<double> embedding,
    required String transcript,
  }) async {
    try {
      await _client.from('episode_embeddings').insert({
        'episode_id': episodeId,
        'embedding': embedding,
        'transcript': transcript,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to store embedding: $e');
    }
  }

  Future<List<Map<String, dynamic>>> searchSimilarEpisodes(
    List<double> queryEmbedding, {
    int limit = 5,
  }) async {
    try {
      final response = await _client.rpc(
        'match_episodes',
        params: {
          'query_embedding': queryEmbedding,
          'match_threshold': 0.7,
          'match_count': limit,
        },
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search similar episodes: $e');
    }
  }
} 