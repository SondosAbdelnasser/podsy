import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../services/embedding_service.dart';
import '../models/podcast_collection.dart';
import 'podcast_details_screen.dart';
import '../models/podcast.dart';
import '../config/api_keys.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final PodcastService _podcastService;
  bool _isLoading = true;
  List<PodcastCollection> _podcasts = [];
  String? _error;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    final embeddingService = EmbeddingService(
      apiKey: ApiKeys.huggingFaceApiKey,
      provider: EmbeddingProvider.huggingFace,
    );
    _podcastService = PodcastService(
      client: Supabase.instance.client,
      embeddingService: embeddingService,
    );
    _loadPodcasts();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _loadPodcasts() async {
    if (!_mounted) return;
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
              iconTheme: const IconThemeData(color: Colors.black),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  currentUser?.name ?? 'Profile',
                  style: const TextStyle(color: Colors.black),
                ),
                background: Container(
                  color: Theme.of(context).primaryColor.withAlpha(26), // 0.1 * 255 ≈ 26
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(context).primaryColor.withAlpha(51), // 0.2 * 255 ≈ 51
                        child: Text(
                          (currentUser?.name ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 40,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentUser?.email ?? '',
                        style: const TextStyle(
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
                  icon: const Icon(Icons.logout),
                  color: Colors.black87,
                  onPressed: () async {
                    await authProvider.signOut();
                    if (!_mounted) return;
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),

            // My Podcasts Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
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
                        if (!_mounted) return;
                        _loadPodcasts();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Podcasts List
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Error loading podcasts',
                                style: TextStyle(
                                    color: Colors.black87, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                style:
                                    const TextStyle(color: Colors.red, fontSize: 14),
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
                                    'Create your first podcast!',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.pushNamed(
                                          context, '/createPodcast');
                                      if (!_mounted) return;
                                      _loadPodcasts();
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create Podcast'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final podcast = _podcasts[index];
                                return PodcastCard(
                                  podcast: podcast,
                                  onTap: () {
                                    final podcastModel = Podcast(
                                      id: podcast.id,
                                      title: podcast.title,
                                      author: 'User', // Default author
                                      description: podcast.description ?? '',
                                      imageUrl: '', // Default empty image
                                      feedUrl: '', // Default empty feed
                                      episodes: [], // Will be loaded in details screen
                                      category: 'Personal', // Default category
                                      rating: 0.0, // Default rating
                                      episodeCount: 0, // Will be updated in details screen
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
                              childCount: _podcasts.length,
                            ),
                          ),
          ],
        ),
      ),
    );
  }
}

class PodcastCard extends StatelessWidget {
  final PodcastCollection podcast;
  final VoidCallback onTap;

  const PodcastCard({
    super.key,
    required this.podcast,
    required this.onTap,
  });

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
