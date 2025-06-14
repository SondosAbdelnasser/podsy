import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/like_service.dart';
import '../services/share_service.dart';
import '../models/episode.dart';
import '../widgets/play_controls.dart';
import '../widgets/like_button.dart';
import '../widgets/podcast_details.dart';

class PlayScreen extends StatefulWidget {
  final Episode episode;
  const PlayScreen({required this.episode});

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final ShareService _shareService = ShareService();

  @override
  void initState() {
    super.initState();
    final likeService = Provider.of<LikeService>(context, listen: false);
    likeService.checkIfLiked(widget.episode.id!);
    
    // // Ensure the episode is playing when the screen opens
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   final audioPlayerService = Provider.of<AudioPlayerService>(context, listen: false);
    //   if (audioPlayerService.currentAudioUrl != widget.episode.audioUrl) {
    //     audioPlayerService.playAudio(widget.episode.audioUrl);
    //   }
    // });
  }

  Future<void> _shareEpisode() async {
    try {
      await _shareService.shareEpisode(
        episodeId: widget.episode.id!,
        title: widget.episode.title,
        description: widget.episode.description ?? '',
        audioUrl: widget.episode.audioUrl,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing episode: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);
    final likeService = Provider.of<LikeService>(context);

    if (!audioPlayerService.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.episode.title),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PodcastDetails(
              title: widget.episode.title,
              description: widget.episode.description,
              imageUrl: widget.episode.imageUrl,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                LikeButton(
                  isLiked: likeService.isLiked,
                  onPressed: () => likeService.toggleLike(widget.episode.id!),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.deepPurple),
                  onPressed: _shareEpisode,
                ),
              ],
            ),

            const SizedBox(height: 20),

            PlayControls(
              isPlaying: audioPlayerService.isPlaying,
              isLoading: audioPlayerService.isLoading,
              onPlayPausePressed: () {
                if (audioPlayerService.isPlaying) {
                  audioPlayerService.pauseAudio();
                } else {
                  audioPlayerService.playAudio(widget.episode.audioUrl, episode: widget.episode);
                }
              },
              onSkipForwardPressed: () {
                audioPlayerService.skipForward();
              },
              onSkipBackwardPressed: () {
                audioPlayerService.skipBackward();
              },
            ),
          ],
        ),
      ),
    );
  }
}
