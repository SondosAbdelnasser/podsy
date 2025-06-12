import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/podcast_card.dart' as widgets;
import '../models/podcast.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
      final podcastResults = await supabase
          .from('podcast_collections')
          .select('''
            *,
            episodes(*)
          ''')
          .ilike('title', '%$query%')
          .order('created_at', ascending: false);

      setState(() {
        searchResults = (podcastResults as List).map((doc) {
          final episodes = (doc['episodes'] as List? ?? [])
              .map((episode) => Episode(
                    id: episode['id'] as String? ?? '',
                    title: episode['title'] as String? ?? '',
                    description: episode['description'] as String? ?? '',
                    audioUrl: episode['audio_url'] as String? ?? '',
                    publishDate: episode['published_at'] != null 
                        ? DateTime.parse(episode['published_at'] as String)
                        : DateTime.now(),
                    duration: (episode['duration'] as int? ?? 0) * 1000,
                    imageUrl: '', // No image URL in episodes table
                  ))
              .toList();

          return Podcast(
            id: doc['id'] as String? ?? '',
            title: doc['title'] as String? ?? '',
            author: 'User', // Default author
            description: doc['description'] as String? ?? '',
            imageUrl: '', // No cover URL in schema
            feedUrl: '', // No feed URL in schema
            episodes: episodes,
            category: 'Personal', // Default category
            rating: 0.0, // Default rating
            episodeCount: episodes.length,
          );
        }).toList();
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
            hintText: 'Search podcasts...',
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
                      'Search for podcasts',
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
              child: ListView.builder(
                padding: EdgeInsets.all(16),
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
              ),
            ),
        ],
      ),
    );
  }
} 