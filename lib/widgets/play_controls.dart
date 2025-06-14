import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';

class PlayControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onSkipForwardPressed;
  final VoidCallback onSkipBackwardPressed;

  const PlayControls({
    Key? key,
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPausePressed,
    required this.onSkipForwardPressed,
    required this.onSkipBackwardPressed,
  }) : super(key: key);

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
    final audioPlayerService = Provider.of<AudioPlayerService>(context);
    
    return Column(
      children: [
        // Progress Bar
        StreamBuilder<Duration?>(
          stream: audioPlayerService.durationStream,
          builder: (context, snapshot) {
            final duration = snapshot.data ?? Duration.zero;
            return Column(
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: Colors.deepPurple,
                    inactiveTrackColor: Colors.grey[300],
                    thumbColor: Colors.deepPurple,
                    overlayColor: Colors.deepPurple.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: audioPlayerService.currentPosition.inSeconds.toDouble(),
                    min: 0,
                    max: duration.inSeconds.toDouble(),
                    onChanged: (value) {
                      audioPlayerService.seekTo(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(audioPlayerService.currentPosition),
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(color: Colors.deepPurple),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        // Playback Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.replay_10, size: 48, color: Colors.deepPurple),
              onPressed: onSkipBackwardPressed,
            ),
            const SizedBox(width: 20),
            isLoading
                ? const CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  )
                : IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      size: 72,
                      color: Colors.deepPurple,
                    ),
                    onPressed: onPlayPausePressed,
                  ),
            const SizedBox(width: 20),
            IconButton(
              icon: const Icon(Icons.forward_10, size: 48, color: Colors.deepPurple),
              onPressed: onSkipForwardPressed,
            ),
          ],
        ),
      ],
    );
  }
}
