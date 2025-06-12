import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../models/podcast.dart';
import '../widgets/podcast_card.dart' as widgets;
import 'profile_screen.dart';
import 'podcast_details_screen.dart';
import '../services/audio_player_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Home> {
  late final PodcastService _podcastService;
  final AudioPlayerService _audioPlayerService = AudioPlayerService();
  List<Podcast> _podcasts = [];
  bool _isLoading = true;
  String? _error;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _podcastService = Provider.of<PodcastService>(context, listen: false);
    _loadPodcasts();
  }

  @override
  void dispose() {
    _mounted = false;
    _audioPlayerService.dispose();
    super.dispose();
  }

  Future<void> _loadPodcasts() async {
    if (!_mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final podcasts = await _podcastService.getAllPodcasts();
      if (!_mounted) return;
      setState(() {
        _podcasts = podcasts;
        _isLoading = false;
      });
    } catch (e) {
      if (!_mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _playEpisode(String audioUrl) async {
    try {
      await _audioPlayerService.playAudio(audioUrl);
      if (!mounted) return;
      
      // Show a snackbar to indicate playback started
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playing episode...'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to play episode: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            icon: const Icon(Icons.menu, color: Colors.black),
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
            const SizedBox(width: 8),
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
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      currentUser?.name.split(' ')[0] ?? 'User',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfileScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Theme.of(context).primaryColor.withAlpha(51), // 0.2 * 255 ≈ 51
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
                  color: Theme.of(context).primaryColor.withAlpha(26), // 0.1 * 255 ≈ 26
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor.withAlpha(51), // 0.2 * 255 ≈ 51
                      child: Text(
                        (currentUser?.name ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentUser?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      currentUser?.email ?? '',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.account_circle, color: Colors.black87),
                title: const Text('Profile', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic, color: Colors.black87),
                title: const Text('My Podcasts', style: TextStyle(color: Colors.black87)),
                onTap: () {
                  Navigator.pushNamed(context, '/myPodcasts');
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.black87),
                title: const Text('Create Podcast', style: TextStyle(color: Colors.black87)),
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
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Error loading podcasts',
                          style: TextStyle(color: Colors.black87, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPodcasts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text('Retry'),
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
                            const SizedBox(height: 16),
                            const Text(
                              'No podcasts yet',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to create a podcast!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/createPodcast');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Podcast'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _podcasts.length,
                        itemBuilder: (context, index) {
                          final podcast = _podcasts[index];
                          return widgets.PodcastCard(
                            podcast: podcast,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PodcastDetailsScreen(podcast: podcast),
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
