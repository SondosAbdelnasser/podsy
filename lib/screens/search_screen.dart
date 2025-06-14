import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/podcast_card.dart' as widgets;
import '../models/podcast.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final supabase = Supabase.instance.client;
  List<Podcast> searchResults = [];
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

      // Combine and deduplicate results
      final Map<String, Podcast> uniquePodcasts = {};

      // Process podcast results
      for (var doc in podcastResults) {
        final episodes = (doc['episodes'] as List? ?? [])
            .where((episode) => episode['is_deleted'] == false)
            .map((episode) {
              // Parse duration string (format: "HH:MM:SS")
              int durationInSeconds = 0;
              if (episode['duration'] != null) {
                final durationStr = episode['duration'].toString();
                final parts = durationStr.split(':');
                if (parts.length == 3) {
                  durationInSeconds = int.parse(parts[0]) * 3600 + // hours
                                    int.parse(parts[1]) * 60 +    // minutes
                                    int.parse(parts[2]);          // seconds
                }
              }

              return Episode(
                id: episode['id'] as String? ?? '',
                title: episode['title'] as String? ?? '',
                description: episode['description'] as String? ?? '',
                audioUrl: episode['audio_url'] as String? ?? '',
                publishDate: episode['published_at'] != null 
                    ? DateTime.parse(episode['published_at'] as String)
                    : DateTime.now(),
                duration: durationInSeconds * 1000, // Convert to milliseconds
                imageUrl: '', // No image URL in episodes table
              );
            })
            .toList();

        final podcast = Podcast(
          id: doc['id'] as String? ?? '',
          title: doc['title'] as String? ?? '',
          author: 'User', // Default author
          description: doc['description'] as String? ?? '',
          imageUrl: doc['image_url'] as String? ?? '', // Populate imageUrl from 'image_url' field
          feedUrl: '', // No feed URL in schema
          episodes: episodes,
          category: 'Personal', // Default category
          rating: 0.0, // Default rating
          episodeCount: episodes.length,
        );

        uniquePodcasts[podcast.id] = podcast;
      }

      // Process episode results
      for (var episodeDoc in episodeResults) {
        final podcastDoc = episodeDoc['podcast_collections'];
        // Parse duration string (format: "HH:MM:SS")
        int durationInSeconds = 0;
        if (episodeDoc['duration'] != null) {
          final durationStr = episodeDoc['duration'].toString();
          final parts = durationStr.split(':');
          if (parts.length == 3) {
            durationInSeconds = int.parse(parts[0]) * 3600 + // hours
                              int.parse(parts[1]) * 60 +    // minutes
                              int.parse(parts[2]);          // seconds
          }
        }

        final episode = Episode(
          id: episodeDoc['id'] as String? ?? '',
          title: episodeDoc['title'] as String? ?? '',
          description: episodeDoc['description'] as String? ?? '',
          audioUrl: episodeDoc['audio_url'] as String? ?? '',
          publishDate: episodeDoc['published_at'] != null 
              ? DateTime.parse(episodeDoc['published_at'] as String)
              : DateTime.now(),
          duration: durationInSeconds * 1000, // Convert to milliseconds
          imageUrl: '', // No image URL in episodes table
        );

        final podcast = Podcast(
          id: podcastDoc['id'] as String? ?? '',
          title: podcastDoc['title'] as String? ?? '',
          author: 'User', // Default author
          description: podcastDoc['description'] as String? ?? '',
          imageUrl: podcastDoc['image_url'] as String? ?? '', // Populate imageUrl from 'image_url' field
          feedUrl: '', // No feed URL in schema
          episodes: [episode],
          category: 'Personal', // Default category
          rating: 0.0, // Default rating
          episodeCount: 1,
        );

        if (uniquePodcasts.containsKey(podcast.id)) {
          // Add episode to existing podcast if not already present
          final existingPodcast = uniquePodcasts[podcast.id]!;
          if (!existingPodcast.episodes.any((e) => e.id == episode.id)) {
            final updatedEpisodes = [...existingPodcast.episodes, episode];
            uniquePodcasts[podcast.id] = Podcast(
              id: existingPodcast.id,
              title: existingPodcast.title,
              author: existingPodcast.author,
              description: existingPodcast.description,
              imageUrl: existingPodcast.imageUrl,
              feedUrl: existingPodcast.feedUrl,
              episodes: updatedEpisodes,
              category: existingPodcast.category,
              rating: existingPodcast.rating,
              episodeCount: updatedEpisodes.length,
            );
          }
        } else {
          uniquePodcasts[podcast.id] = podcast;
        }
      }

      setState(() {
        searchResults = uniquePodcasts.values.toList();
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
          style: const TextStyle(color: Colors.black, fontSize: 16),
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
                    const SizedBox(height: 16),
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
            const Expanded(
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
                    const SizedBox(height: 16),
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
<<<<<<< Updated upstream
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: searchResults.map((result) => Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: widgets.PodcastCard(
                        podcast: result,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/podcast-details',
                            arguments: result,
                          );
                        },
                      ),
                    )).toList(),
                  ),
                ),
=======
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final result = searchResults[index];
                  return widgets.PodcastCard(
                    podcast: result,
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/podcast-details',
                        arguments: result,
                      );
                    },
                  );
                },
>>>>>>> Stashed changes
              ),
            ),
        ],
      ),
    );
  }
} 