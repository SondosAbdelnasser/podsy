import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../models/podcast.dart' as itunes;
import '../models/episode.dart' as episode_model;
import '../widgets/podcast_card.dart' as widgets;
import '../widgets/episode_tile.dart';
import 'profile_screen.dart';
import 'podcast_details_screen.dart';
import 'users_list_page.dart';
import '../services/audio_player_service.dart';
import '../models/episode.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Home> {
  final PodcastService _podcastService = PodcastService();
  List<itunes.Podcast> _podcasts = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

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
      final podcasts = await _podcastService.getTopPodcasts();
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

  Future<void> _searchPodcasts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchQuery = '';
      });
      await _loadPodcasts();
      return;
    }

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      final results = await _podcastService.searchPodcasts(query);
      setState(() {
        _podcasts = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Text(
              'Podsy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.mic, color: Theme.of(context).primaryColor, size: 20),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      currentUser?.name?.split(' ')[0] ?? 'User',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      (currentUser?.name ?? 'U')[0].toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Text(
                        (currentUser?.name ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      currentUser?.name ?? 'User',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser?.email ?? '',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.account_circle, color: Colors.black87),
                title: Text('Profile', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.mic, color: Colors.black87),
                title: Text('My Podcasts', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.pushNamed(context, '/myPodcasts');
                },
              ),
              ListTile(
                leading: Icon(Icons.add_circle_outline, color: Colors.black87),
                title: Text('Create Podcast', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.pushNamed(context, '/createPodcast');
                },
              ),
            ],
          ),
        ),
      ),
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
                              'Be the first to create a podcast!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Followed Users' Episodes Section
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'From People You Follow',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            FutureBuilder<List<itunes.Podcast>>(
                              future: _podcastService.getFollowedUsersEpisodes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading followed episodes',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final followedPodcasts = snapshot.data ?? [];
                                
                                if (followedPodcasts.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Follow some users to see their episodes here!',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }

                                return Container(
                                  height: 280,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: followedPodcasts.length,
                                    itemBuilder: (context, index) {
                                      final podcast = followedPodcasts[index];
                                      return Container(
                                        width: 200,
                                        margin: EdgeInsets.only(right: 16),
                                        child: widgets.PodcastCard(
                                          podcast: podcast,
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => PodcastDetailsScreen(podcast: podcast),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 24),
                            // All Podcasts Section
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'All Podcasts',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Container(
                              height: 280, // Fixed height for horizontal scrolling
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _podcasts.length,
                                itemBuilder: (context, index) {
                                  final podcast = _podcasts[index];
                                  return Container(
                                    width: 200,
                                    margin: EdgeInsets.only(right: 16),
                                    child: widgets.PodcastCard(
                                      podcast: podcast,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PodcastDetailsScreen(podcast: podcast),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 24),
                            // Latest Episodes Feed Section
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'Latest Episodes',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            FutureBuilder<List<itunes.Podcast>>(
                              future: _podcastService.getFollowedUsersEpisodes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                
                                if (snapshot.hasError) {
                                  return Center(
                                    child: Text(
                                      'Error loading episodes',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                final followedPodcasts = snapshot.data ?? [];
                                final allEpisodes = followedPodcasts
                                    .expand((podcast) => podcast.episodes)
                                    .toList();
                                  //..sort((a, b) => b.publishedAt!.compareTo(a.publishedAt!));

                                if (allEpisodes.isEmpty) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16),
                                    child: Text(
                                      'Follow some users to see their latest episodes here!',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: allEpisodes.length,
                                  itemBuilder: (context, index) {
                                    final episode = allEpisodes[index];
                                    final podcast = followedPodcasts.firstWhere(
                                      (p) => p.episodes.contains(episode),
                                      orElse: () => followedPodcasts.first,
                                    );
                                    return Card(
                                      margin: EdgeInsets.only(bottom: 12),
                                      color: Color(0xFFF3E5F5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        contentPadding: EdgeInsets.all(12),
                                        leading: CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.white,
                                          child: Text(
                                            podcast.title[0].toUpperCase(),
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
                                            Text(
                                              podcast.title,
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${_formatDuration(Duration(milliseconds: episode.duration))} • ${_formatDate(episode.publishDate)}',
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
                                            final audioPlayerService = Provider.of<AudioPlayerService>(context, listen: false);
                                            // Convert iTunes Episode to our database Episode format
                                            final dbEpisode = Episode(
                                              collectionId: podcast.id,
                                              title: episode.title,
                                              description: episode.description,
                                              audioUrl: episode.audioUrl,
                                              duration: Duration(milliseconds: episode.duration),
                                              createdAt: DateTime.now(),
                                              updatedAt: DateTime.now(),
                                            );
                                            audioPlayerService.playAudio(episode.audioUrl, episode: dbEpisode);
                                          },
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PodcastDetailsScreen(podcast: podcast),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
