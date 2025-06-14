import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../models/podcast_collection.dart';
import 'podcast_details_screen.dart';
import '../models/podcast.dart';
import 'follow_requests_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PodcastService _podcastService = PodcastService();
  bool _isLoading = true;
  List<PodcastCollection> _podcasts = [];
  String? _error;
  int _followersCount = 0;
  int _followingCount = 0;

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
      final followersCount = await _podcastService.getFollowersCount(currentUser.id);
      final followingCount = await _podcastService.getFollowingCount(currentUser.id);

      print('DEBUG: _loadPodcasts called.');
      print('DEBUG: Fetched followersCount: $followersCount');
      print('DEBUG: Fetched followingCount: $followingCount');

      setState(() {
        _podcasts = podcasts;
        _followersCount = followersCount;
        _followingCount = followingCount;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('ERROR in _loadPodcasts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading podcasts: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadPodcasts,
        child: CustomScrollView(
          slivers: [
            // Profile Header
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.black),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  currentUser?.name ?? 'Profile',
                  style: TextStyle(color: Colors.black),
                ),
                background: Container(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        child: Text(
                          (currentUser?.name ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 40,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        currentUser?.email ?? '',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.logout),
                  color: Colors.black87,
                  onPressed: () async {
                    await authProvider.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),

            // Action buttons (Follow Requests & Create Podcast)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: _showFollowersList,
                          child: Column(
                            children: [
                              Text(
                                _followersCount.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Followers',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _showFollowingList,
                          child: Column(
                            children: [
                              Text(
                                _followingCount.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                'Following',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FollowRequestsScreen(),
                          ),
                        );
                        _loadPodcasts();
                      },
                      icon: Icon(Icons.person_add),
                      label: Text('Follow Requests'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // My Podcasts Section
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Podcasts',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: Theme.of(context).primaryColor),
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/createPodcast');
                        _loadPodcasts();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Podcasts List
            _isLoading
                ? SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Error loading podcasts',
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _error!,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 14),
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
                        ),
                      )
                    : _podcasts.isEmpty
                        ? SliverFillRemaining(
                            child: Center(
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
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final podcastCollection = _podcasts[index];
                                final podcastModel = Podcast(
                                  id: podcastCollection.id,
                                  title: podcastCollection.title,
                                  author: 'You',
                                  description: podcastCollection.description ?? '',
                                  imageUrl: podcastCollection.imageUrl ?? '',
                                  feedUrl: '',
                                  episodes: [],
                                  category: 'Personal',
                                  rating: 0.0,
                                  episodeCount: podcastCollection.episodeCount,
                                  userId: podcastCollection.userId,
                                );
                                return Card(
                                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PodcastDetailsScreen(
                                            podcast: podcastModel,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: podcastCollection.imageUrl != null && podcastCollection.imageUrl!.isNotEmpty
                                                ? Image.network(
                                                    podcastCollection.imageUrl!,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[300],
                                                    child: Icon(
                                                      Icons.mic,
                                                      size: 40,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  podcastCollection.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  podcastCollection.description ?? 'No description',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.headphones,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      '${podcastCollection.episodeCount} Episodes',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete_outline, color: Colors.red),
                                            onPressed: () => _showDeleteConfirmationDialog(podcastCollection.id, podcastCollection.title),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _podcasts.length,
                            ),
                          ),
          ],
        ),
      ),
    );
  }

  void _showFollowersList() {
    // Implement navigation or dialog for followers list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Followers list coming soon')),
    );
  }

  void _showFollowingList() {
    // Implement navigation or dialog for following list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Following list coming soon')),
    );
  }

  void _showDeleteConfirmationDialog(String id, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Podcast'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _podcastService.softDeletePodcast(id);
                  _loadPodcasts(); // Refresh the list
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Podcast "$title" deleted.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete podcast: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
        );
      },
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Color(0xFFF3E5F5), // Light purple color
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
                    color: Colors.black54,
                  ),
                ],
              ),
              if (podcast.description != null &&
                  podcast.description!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8, left: 36),
                  child: Text(
                    podcast.description!,
                    style: TextStyle(
                      color: Colors.black87,
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
                    color: Colors.black54,
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
