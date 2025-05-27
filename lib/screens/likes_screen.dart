import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/episode.dart';
import '../widgets/episode_card.dart';

class LikesScreen extends StatefulWidget {
  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final supabase = Supabase.instance.client;
  List<Episode> likedEpisodes = [];
  bool isLoading = true;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    loadLikedEpisodes();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> loadLikedEpisodes() async {
    if (!_mounted) return;
    setState(() => isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final likes = await supabase
          .from('likes')
          .select('episode_id')
          .eq('user_id', currentUser.id);

      if (likes.isEmpty) {
        if (!_mounted) return;
        setState(() {
          likedEpisodes = [];
          isLoading = false;
        });
        return;
      }

      final episodeIds = likes.map((like) => like['episode_id']).toList();
      
      final episodes = await supabase
          .from('episodes')
          .select('*, podcast_collections!inner(*)')
          .filter('id', 'in', episodeIds)
          .order('created_at', ascending: false);

      if (!_mounted) return;
      setState(() {
        likedEpisodes = (episodes as List).map((episode) {
          // Parse duration string (format: "HH:MM:SS")
          int durationInSeconds = 0;
          if (episode['duration'] != null) {
            final durationStr = episode['duration'] as String;
            final parts = durationStr.split(':');
            if (parts.length == 3) {
              durationInSeconds = int.parse(parts[0]) * 3600 + // hours
                                int.parse(parts[1]) * 60 +    // minutes
                                int.parse(parts[2]);          // seconds
            }
          }

          return Episode(
            id: episode['id'] as String? ?? '',
            collectionId: episode['collection_id'] as String? ?? '',
            title: episode['title'] as String? ?? '',
            description: episode['description'] as String?,
            audioUrl: episode['audio_url'] as String? ?? '',
            imageUrl: episode['image_url'] as String?,
            duration: Duration(seconds: durationInSeconds),
            publishedAt: episode['published_at'] != null 
                ? DateTime.parse(episode['published_at'] as String)
                : null,
            createdAt: DateTime.parse(episode['created_at'] as String),
            updatedAt: DateTime.parse(episode['updated_at'] as String),
          );
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading liked episodes: $e');
      if (!_mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Liked Episodes',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: loadLikedEpisodes,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : likedEpisodes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No liked episodes yet',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Like some episodes to see them here',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: likedEpisodes.length,
                    itemBuilder: (context, index) {
                      final episode = likedEpisodes[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        color: Color(0xFFF3E5F5), // Light purple color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Text(
                              episode.title[0].toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          title: Text(
                            episode.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (episode.description != null && episode.description!.isNotEmpty)
                                Text(
                                  episode.description!,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              SizedBox(height: 4),
                              Text(
                                '${_formatDuration(episode.duration)} • ${_formatDate(episode.publishedAt ?? episode.createdAt)}',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.play_circle_outline),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              // TODO: Implement episode playback
                            },
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}