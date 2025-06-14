import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/episode.dart';

class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final supabase = Supabase.instance.client;
  late Stream<Uri> _linkStream;

  void init(BuildContext context) {
    _linkStream = _appLinks.uriLinkStream;
    _linkStream.listen((Uri uri) {
      _handleDeepLink(uri, context);
    });
  }

  Future<Episode?> _fetchEpisode(String episodeId) async {
    try {
      final response = await supabase
          .from('episodes')
          .select('*, podcast_collections!inner(*)')
          .eq('id', episodeId)
          .single();

      if (response == null) return null;

      // Parse duration string (format: "HH:MM:SS")
      int durationInSeconds = 0;
      if (response['duration'] != null) {
        final durationStr = response['duration'] as String;
        final parts = durationStr.split(':');
        if (parts.length == 3) {
          durationInSeconds = int.parse(parts[0]) * 3600 + // hours
                            int.parse(parts[1]) * 60 +    // minutes
                            int.parse(parts[2]);          // seconds
        }
      }

      return Episode(
        id: response['id'] as String? ?? '',
        collectionId: response['collection_id'] as String? ?? '',
        title: response['title'] as String? ?? '',
        description: response['description'] as String?,
        audioUrl: response['audio_url'] as String? ?? '',
        imageUrl: response['image_url'] as String?,
        duration: Duration(seconds: durationInSeconds),
        publishedAt: response['published_at'] != null 
            ? DateTime.parse(response['published_at'] as String)
            : null,
        createdAt: DateTime.parse(response['created_at'] as String),
        updatedAt: DateTime.parse(response['updated_at'] as String),
      );
    } catch (e) {
      print('Error fetching episode: $e');
      return null;
    }
  }

  Future<void> _handleDeepLink(Uri uri, BuildContext context) async {
    if (uri.scheme == 'podsy' && uri.host == 'episode') {
      final episodeId = uri.pathSegments.last;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch episode data
      final episode = await _fetchEpisode(episodeId);
      
      // Remove loading indicator
      Navigator.of(context).pop();

      if (episode != null) {
        // Navigate to the episode screen
        Navigator.pushNamed(
          context,
          '/episode',
          arguments: {'episode': episode},
        );
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find the episode'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 