import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../services/podcast_service.dart';
import '../widgets/podcast_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PodcastService _podcastService = PodcastService();
  List<Podcast> _podcasts = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  Future<void> _loadPodcasts() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // TODO: Implement getAllPodcasts method in PodcastService
      // For now, we'll use a dummy list
      setState(() {
        _podcasts = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load podcasts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Podcasts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
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
