import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/podcast.dart';
import '../services/podcast_service.dart';
import '../services/embedding_service.dart';
import '../config/api_keys.dart';
import '../widgets/podcast_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final PodcastService _podcastService;
  List<Podcast> _podcasts = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadPodcasts();
  }

  void _initializeServices() {
    final embeddingService = EmbeddingService(
      apiKey: ApiKeys.huggingFaceApiKey,
      provider: EmbeddingProvider.huggingFace,
    );

    _podcastService = PodcastService(
      client: Supabase.instance.client,
      embeddingService: embeddingService,
    );
  }

  Future<void> _loadPodcasts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final collections = await _podcastService.getUserCollections(
        Supabase.instance.client.auth.currentUser?.id ?? '',
      );

      setState(() {
        _podcasts = collections.map((collection) => Podcast(
          id: collection.id,
          title: collection.title,
          author: collection.userId, // Using userId as author for now
          description: collection.description ?? '',
          imageUrl: collection.imageUrl ?? '',
          feedUrl: '', // Not using feed URLs in our app
          episodes: [], // Will be loaded separately
          category: 'Personal', // Default category
          rating: 0.0, // Default rating
          episodeCount: 0, // Will be updated when episodes are loaded
        )).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load podcasts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Podcasts'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter podcast title or description',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (query) async {
            if (query.isEmpty) return;

            try {
              // For now, we'll just filter the existing podcasts
              final results = _podcasts.where((podcast) {
                final title = podcast.title.toLowerCase();
                final description = podcast.description.toLowerCase();
                final searchQuery = query.toLowerCase();
                return title.contains(searchQuery) || description.contains(searchQuery);
              }).toList();

              if (!mounted) return;

              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/search-results',
                arguments: results,
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Search failed: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Podcasts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPodcasts,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPodcasts,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _podcasts.length,
                    itemBuilder: (context, index) {
                      final podcast = _podcasts[index];
                      return PodcastCard(
                        podcast: podcast,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/podcast-details',
                            arguments: podcast,
                          );
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
