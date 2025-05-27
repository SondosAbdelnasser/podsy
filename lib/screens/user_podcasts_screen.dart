import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../models/podcast_collection.dart';
import '../models/podcast.dart';
import 'podcast_details_screen.dart';

class UserPodcastsScreen extends StatefulWidget {
  @override
  _UserPodcastsScreenState createState() => _UserPodcastsScreenState();
}

class _UserPodcastsScreenState extends State<UserPodcastsScreen> {
  final PodcastService _podcastService = PodcastService();
  bool _isLoading = true;
  List<PodcastCollection> _podcasts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPodcasts();
  }

  Future<void> _loadPodcasts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final podcasts = await _podcastService.getUserCollections(currentUser.id);
      setState(() {
        _podcasts = podcasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Podcasts'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              await Navigator.pushNamed(context, '/createPodcast');
              _loadPodcasts(); // Refresh the list after returning
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _loadPodcasts,
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading podcasts',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPodcasts,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _podcasts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.mic_none,
                              size: 64,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No podcasts yet',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first podcast!',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await Navigator.pushNamed(
                                    context, '/createPodcast');
                                _loadPodcasts();
                              },
                              icon: Icon(Icons.add),
                              label: Text('Create Podcast'),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: _podcasts.length,
                        itemBuilder: (context, index) {
                          final podcast = _podcasts[index];
                          return PodcastCard(
                            podcast: podcast,
                            onTap: () {
                              final podcastModel = Podcast(
                                id: podcast.id,
                                title: podcast.title,
                                author: 'User',
                                description: podcast.description ?? '',
                                imageUrl: '',
                                feedUrl: '',
                                episodes: [],
                                category: 'Personal',
                                rating: 0.0,
                                episodeCount: 0,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PodcastDetailsScreen(podcast: podcastModel),
                                ),
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class PodcastCard extends StatelessWidget {
  final PodcastCollection podcast;
  final VoidCallback onTap;

  const PodcastCard({
    Key? key,
    required this.podcast,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.white10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      podcast.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                ],
              ),
              if (podcast.description != null && podcast.description!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 36),
                  child: Text(
                    podcast.description!,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: 8, left: 36),
                child: Text(
                  'Created ${_formatDate(podcast.createdAt)}',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 