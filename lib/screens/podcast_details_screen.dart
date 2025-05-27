import 'package:flutter/material.dart';
import '../models/podcast.dart';
import '../models/episode.dart' as episode_model;
import '../services/podcast_service.dart';
import 'package:just_audio/just_audio.dart';
import '../screens/play_screen.dart';

class PodcastDetailsScreen extends StatefulWidget {
  final Podcast podcast;

  const PodcastDetailsScreen({
    Key? key,
    required this.podcast,
  }) : super(key: key);

  @override
  State<PodcastDetailsScreen> createState() => _PodcastDetailsScreenState();
}

class _PodcastDetailsScreenState extends State<PodcastDetailsScreen> {
  final PodcastService _podcastService = PodcastService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<episode_model.Episode> _episodes = [];
  bool _isLoading = true;
  String? _error;
  int? _currentEpisodeIndex;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final episodes = await _podcastService.getCollectionEpisodes(widget.podcast.id);
      setState(() {
        _episodes = episodes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _playEpisode(episode_model.Episode episode, int index) async {
    try {
      // Navigate to PlayScreen first
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayScreen(episode: episode),
        ),
      );

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
      body: CustomScrollView(
        slivers: [
          // Podcast Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black),
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
                          Colors.black.withOpacity(0.7),
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
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.podcast.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.podcast.author,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 4),
                      Text(
                        widget.podcast.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        widget.podcast.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.podcast.description,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
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
                              'Error loading episodes',
                              style: TextStyle(color: Colors.black87, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _error!,
                              style: TextStyle(color: Colors.red, fontSize: 14),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadEpisodes,
                              child: Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _episodes.isEmpty
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
                                  'No episodes yet',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Be the first to upload an episode!',
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
                              final episode = _episodes[index];
                              final isCurrentEpisode = _currentEpisodeIndex == index;
                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                color: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isCurrentEpisode
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () => _playEpisode(episode, index),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              isCurrentEpisode && _isPlaying
                                                  ? Icons.pause_circle_filled
                                                  : Icons.play_circle_filled,
                                              size: 32,
                                              color: Theme.of(context).primaryColor,
                                            ),
                                            SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    episode.title,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    _formatDuration(episode.duration),
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (episode.description != null &&
                                            episode.description!.isNotEmpty) ...[
                                          SizedBox(height: 8),
                                          Text(
                                            episode.description!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
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
}