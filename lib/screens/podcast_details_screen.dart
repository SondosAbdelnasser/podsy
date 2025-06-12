import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../models/episode.dart' as episode_model;
import '../services/podcast_service.dart';
import 'package:just_audio/just_audio.dart';
import 'upload_podcast.dart';
import '../screens/play_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/embedding_service.dart';
import '../utils/supabase_config.dart';

class PodcastDetailsScreen extends StatefulWidget {
  final Podcast podcast;

  const PodcastDetailsScreen({
    super.key,
    required this.podcast,
  });

  @override
  State<PodcastDetailsScreen> createState() => _PodcastDetailsScreenState();
}

class _PodcastDetailsScreenState extends State<PodcastDetailsScreen> {
  late final PodcastService _podcastService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<episode_model.Episode> _episodes = [];
  bool _isLoading = true;
  String? _error;
  int? _currentEpisodeIndex;
  bool _isPlaying = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _podcastService = PodcastService(
      client: Supabase.instance.client,
      embeddingService: EmbeddingService(
        apiKey: SupabaseConfig.supabaseAnonKey,
        provider: EmbeddingProvider.huggingFace,
      ),
    );
    _loadEpisodes();
  }

  @override
  void dispose() {
    _mounted = false;
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes() async {
    if (!_mounted) return;
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final episodes = await _podcastService.getEpisodesForCollection(widget.podcast.id);
      if (!_mounted) return;
      setState(() {
        _episodes = episodes;
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

  Future<void> _playEpisode(episode_model.Episode episode, int index) async {
    if (!mounted) return;
    try {
      // Navigate to PlayScreen first
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayScreen(episode: episode),
        ),
      );

      if (!mounted) return;
      if (_currentEpisodeIndex == index && _isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        if (_currentEpisodeIndex != index) {
          await _audioPlayer.setUrl(episode.audioUrl);
          setState(() => _currentEpisodeIndex = index);
        }
        await _audioPlayer.play();
        setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing episode: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _episodes.isNotEmpty ? FloatingActionButton(
        onPressed: () async {
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UploadEpisodeScreen(
                podcastId: widget.podcast.id,
                podcastTitle: widget.podcast.title,
              ),
            ),
          );
          _loadEpisodes();
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ) : null,
      body: CustomScrollView(
        slivers: [
          // Podcast Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.mic,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(179), // 0.7 * 255 ≈ 179
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Podcast Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.podcast.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.podcast.author,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        widget.podcast.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        widget.podcast.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.podcast.description,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Episodes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Episodes List
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
                              'Error loading episodes',
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _episodes.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(
                            child: Text(
                              'No episodes yet',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final episode = _episodes[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  title: Text(
                                    episode.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (episode.description?.isNotEmpty ?? false)
                                        Text(
                                          episode.description!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatDuration(episode.duration)} • ${_formatDate(episode.publishedAt ?? episode.createdAt)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      _currentEpisodeIndex == index && _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    onPressed: () => _playEpisode(episode, index),
                                  ),
                                ),
                              );
                            },
                            childCount: _episodes.length,
                          ),
                        ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}