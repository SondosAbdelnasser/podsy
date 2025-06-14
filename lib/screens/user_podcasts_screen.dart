import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../models/podcast_collection.dart';
import '../models/podcast.dart';
import 'podcast_details_screen.dart';
import '../widgets/podcast_card.dart';

class UserPodcastsScreen extends StatefulWidget {
  @override
  _UserPodcastsScreenState createState() => _UserPodcastsScreenState();
}

class _UserPodcastsScreenState extends State<UserPodcastsScreen> {
  final PodcastService _podcastService = PodcastService();
  bool _isLoading = true;
  List<PodcastCollection> _podcasts = [];
  String? _error;
  String? _currentUserId;

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

      _currentUserId = currentUser.id;
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

  Future<void> _showDeleteConfirmationDialog(String podcastId, String podcastTitle) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Podcast'),
          content: Text('Are you sure you want to delete "${podcastTitle}"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _podcastService.softDeletePodcast(podcastId);
                  await _loadPodcasts(); // Reload podcasts after deletion
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Podcast deleted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete podcast: ${e.toString()}')),
                  );
                }
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Podcasts'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
      backgroundColor: Colors.white,
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
                          style: TextStyle(color: Colors.black87, fontSize: 16),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
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
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No podcasts yet',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first podcast!',
                              style: TextStyle(
                                color: Colors.grey[600],
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
                                backgroundColor: Theme.of(context).primaryColor,
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
                          final isMyPodcast = _currentUserId == podcast.userId;
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
                                userId: podcast.userId,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PodcastDetailsScreen(podcast: podcastModel),
                                ),
                              ).then((_) => _loadPodcasts());
                            },
                            trailing: isMyPodcast
                                ? IconButton(
                                    icon: Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmationDialog(podcast.id, podcast.title),
                                  )
                                : null,
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
  final Widget? trailing;

  const PodcastCard({
    Key? key,
    required this.podcast,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!, width: 1),
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
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              if (podcast.description != null && podcast.description!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 36),
                  child: Text(
                    podcast.description!,
                    style: TextStyle(
                      color: Colors.grey[600],
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
                    color: Colors.grey[500],
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
<<<<<<< Updated upstream
    return '${date.day}/${date.month}/${date.year}';
=======
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
>>>>>>> Stashed changes
  }
} 