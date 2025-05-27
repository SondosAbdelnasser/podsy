import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/share.dart';

class ShareService {
  final supabase = Supabase.instance.client;

  Future<void> shareEpisode({
    required String episodeId,
    required String title,
    required String description,
    required String audioUrl,
  }) async {
    try {
      // Create deep link to the episode
      final deepLink = 'podsy://episode/$episodeId';

      // Create share text
      final shareText = '''
🎧 Check out this podcast episode on Podsy!

$title

${description.isNotEmpty ? description : ''}

Listen here: $deepLink

Shared via Podsy
''';

      // Share using the share_plus package
      await Share.share(shareText);

      // Record the share in the database
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        await supabase.from('shares').insert({
          'user_id': currentUser.id,
          'episode_id': episodeId,
          'platform': 'app', // We don't know the actual platform, so using 'app'
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error sharing episode: $e');
      rethrow;
    }
  }

  Future<List<ShareRecord>> getUserShares(String userId) async {
    try {
      final response = await supabase
          .from('shares')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((share) {
        return ShareRecord.fromMap(share, share['id']);
      }).toList();
    } catch (e) {
      print('Error getting user shares: $e');
      rethrow;
    }
  }
} 