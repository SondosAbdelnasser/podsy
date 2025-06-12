import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/like_service.dart';
import '../services/share_service.dart';
import '../models/episode.dart';
import '../widgets/play_controls.dart';
import '../widgets/like_button.dart';
import '../widgets/podcast_details.dart';
import 'transcription_screen.dart';

class PlayScreen extends StatefulWidget {
  final Episode episode;
  const PlayScreen({super.key, required this.episode});

  @override
  _PlayScreenState createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  final ShareService _shareService = ShareService();
  String? _transcript;

  @override
  void initState() {
    super.initState();
    final likeService = Provider.of<LikeService>(context, listen: false);
    likeService.checkIfLiked(widget.episode.id);
  }

  Future<void> _shareEpisode() async {
    try {
      await _shareService.shareEpisode(
        episodeId: widget.episode.id,
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

  Future<void> _transcribeEpisode() async {
    try {
      final transcript = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => TranscriptionScreen(
            audioUrl: widget.episode.audioUrl,
            episodeId: widget.episode.id,
            initialTranscript: _transcript,
          ),
        ),
      );

      if (transcript != null) {
        setState(() => _transcript = transcript);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);
    final likeService = Provider.of<LikeService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.episode.title),
        actions: [
          IconButton(
            icon: Icon(Icons.transcribe),
            onPressed: _transcribeEpisode,
            tooltip: 'Transcribe Episode',
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  onPressed: () => likeService.toggleLike(widget.episode.id),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share),
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
                  audioPlayerService.playAudio(widget.episode.audioUrl);
                }
              },
              onSkipForwardPressed: () {
                audioPlayerService.skipForward();
              },
              onSkipBackwardPressed: () {
                audioPlayerService.skipBackward();
              },
            ),

            if (_transcript != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Transcript:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(_transcript!),
            ],
          ],
        ),
      ),
    );
  }
}
