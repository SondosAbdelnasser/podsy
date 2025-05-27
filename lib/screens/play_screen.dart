import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_pla';
import '../services/like_service.dart';
import '../models/episode.dart';
import '../widgets/play_controls.dart';
import '../widgets/like_button.dart';
import '../widgets/podcast_details.dart';

class PlayScreen extends StatelessWidget {
  final Episode episode;

  PlayScreen({required this.episode});

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);
    final likeService = Provider.of<LikeService>(context);

    // تحقق من حالة اللايك
    likeService.checkIfLiked(episode.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(episode.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PodcastDetails(
              title: episode.title,
              description: episode.description,
              imageUrl: episode.imageUrl,
            ),
            SizedBox(height: 20),

            LikeButton(
              isLiked: likeService.isLiked,
              onPressed: () => likeService.toggleLike(episode.id),
            ),

            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {
                // إضافة وظيفة المشاركة هنا
              },
            ),

            SizedBox(height: 20),

            PlayControls(
              isPlaying: audioPlayerService.isPlaying,
              isLoading: audioPlayerService.isLoading,
              onPlayPausePressed: () {
                if (audioPlayerService.isPlaying) {
                  audioPlayerService.pauseAudio();
                } else {
                  audioPlayerService.playAudio(episode.audioUrl);
                }
              },
              onSkipForwardPressed: () {
                //
                audioPlayerService.skipForward();
              },
              onSkipBackwardPressed: () {
                // 
                audioPlayerService.skipBackward();
              },
            ),
          ],
        ),
      ),
    );
  }
}
