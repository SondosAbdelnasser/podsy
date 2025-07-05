import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/podcast_card.dart' as widgets;
import '../models/podcast.dart';
import '../widgets/episode_card.dart';
import '../models/episode.dart' as episode_model;

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class SearchResultItem {
  final Podcast? podcast;
  final episode_model.Episode? episode;
  SearchResultItem.podcast(this.podcast) : episode = null;
  SearchResultItem.episode(this.episode) : podcast = null;
}

class _SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;
  List<SearchResultItem> searchResults = [];
  bool isLoading = false;
  String searchQuery = '';

  Future<void> performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        searchResults = [];
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Search in podcast_collections table
      final podcastResults = await supabase
          .from('podcast_collections')
          .select('''
            *,
            episodes(*)
          ''')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      // Search in episodes table
      final episodeResults = await supabase
          .from('episodes')
          .select('''
            *,
            podcast_collections!inner(*)
          ''')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .eq('is_deleted', false)
          .order('created_at', ascending: false);

      final List<SearchResultItem> results = [];
      final Set<String> seenPodcastIds = {};
      final Set<String> seenEpisodeIds = {};

      // Process podcast results
      for (var doc in podcastResults) {
        final episodes = (doc['episodes'] as List? ?? [])
            .where((episode) => episode['is_deleted'] == false)
            .map((episode) {
              int durationInSeconds = 0;
              if (episode['duration'] != null) {
                final durationStr = episode['duration'].toString();
                final parts = durationStr.split(':');
                if (parts.length == 3) {
                  durationInSeconds = int.parse(parts[0]) * 3600 +
                                    int.parse(parts[1]) * 60 +
                                    int.parse(parts[2]);
                }
              }
              return episode_model.Episode(
                id: episode['id'] as String? ?? '',
                collectionId: episode['collection_id'] ?? '',
                title: episode['title'] as String? ?? '',
                description: episode['description'] as String?,
                audioUrl: episode['audio_url'] as String? ?? '',
                imageUrl: episode['image_url'] as String?,
                duration: Duration(milliseconds: durationInSeconds * 1000),
                publishedAt: episode['published_at'] != null
                    ? DateTime.parse(episode['published_at'] as String)
                    : null,
                createdAt: episode['created_at'] != null ? DateTime.parse(episode['created_at']) : DateTime.now(),
                updatedAt: episode['updated_at'] != null ? DateTime.parse(episode['updated_at']) : DateTime.now(),
                categories: List<String>.from(episode['categories'] ?? []),
                isDeleted: episode['is_deleted'] ?? false,
              );
            })
            .toList();

        final podcast = Podcast(
          id: doc['id'] as String? ?? '',
          title: doc['title'] as String? ?? '',
          author: 'User',
          description: doc['description'] as String? ?? '',
          imageUrl: doc['image_url'] as String? ?? '',
          feedUrl: '',
          episodes: episodes,
          category: 'Personal',
          rating: 0.0,
          episodeCount: episodes.length,
        );
        if (!seenPodcastIds.contains(podcast.id)) {
          results.add(SearchResultItem.podcast(podcast));
          seenPodcastIds.add(podcast.id);
        }
      }

      // Process episode results
      for (var episodeDoc in episodeResults) {
        final podcastDoc = episodeDoc['podcast_collections'];
        int durationInSeconds = 0;
        if (episodeDoc['duration'] != null) {
          final durationStr = episodeDoc['duration'].toString();
          final parts = durationStr.split(':');
          if (parts.length == 3) {
            durationInSeconds = int.parse(parts[0]) * 3600 +
                              int.parse(parts[1]) * 60 +
                              int.parse(parts[2]);
          }
        }
        final episode = episode_model.Episode(
          id: episodeDoc['id'] as String? ?? '',
          collectionId: episodeDoc['collection_id'] ?? '',
          title: episodeDoc['title'] as String? ?? '',
          description: episodeDoc['description'] as String?,
          audioUrl: episodeDoc['audio_url'] as String? ?? '',
          imageUrl: episodeDoc['image_url'] as String?,
          duration: Duration(milliseconds: durationInSeconds * 1000),
          publishedAt: episodeDoc['published_at'] != null
              ? DateTime.parse(episodeDoc['published_at'] as String)
              : null,
          createdAt: episodeDoc['created_at'] != null ? DateTime.parse(episodeDoc['created_at']) : DateTime.now(),
          updatedAt: episodeDoc['updated_at'] != null ? DateTime.parse(episodeDoc['updated_at']) : DateTime.now(),
          categories: List<String>.from(episodeDoc['categories'] ?? []),
          isDeleted: episodeDoc['is_deleted'] ?? false,
        );
        if (!seenEpisodeIds.contains(episode.id)) {
          results.add(SearchResultItem.episode(episode));
          seenEpisodeIds.add(episode.id!);
        }
      }

      setState(() {
        searchResults = results;
        isLoading = false;
      });
    } catch (e) {
      print('Error searching: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextField(
          onChanged: (value) {
            setState(() {
              searchQuery = value;
            });
            performSearch(value);
          },
          decoration: InputDecoration(
            hintText: 'Search podcasts and episodes...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.grey[400]),
          ),
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          if (searchQuery.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Search for podcasts and episodes',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (searchResults.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: searchResults.map((result) => Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: result.podcast != null
                        ? widgets.PodcastCard(
                            podcast: result.podcast!,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/podcast-details',
                                arguments: result.podcast!,
                              );
                            },
                          )
                        : EpisodeCard(
                            episode: result.episode!,
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/play',
                                arguments: result.episode!,
                              );
                            },
                          ),
                    )).toList(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 