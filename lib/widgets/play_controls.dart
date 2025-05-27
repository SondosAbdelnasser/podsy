import 'package:flutter/material.dart';

class PlayControls extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final Function onPlayPausePressed;
  final Function onSkipForwardPressed;
  final Function onSkipBackwardPressed;

  PlayControls({
    required this.isPlaying,
    required this.isLoading,
    required this.onPlayPausePressed,
    required this.onSkipForwardPressed,
    required this.onSkipBackwardPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Play / Pause Button
        if (isLoading)
          CircularProgressIndicator()
        else
          IconButton(
            iconSize: 60,
            icon: Icon(
              isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              color: Colors.blue,
            ),
            onPressed: () => onPlayPausePressed(),
          ),

        // Skip Forward and Skip Backward Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.replay_10),
              onPressed: () => onSkipBackwardPressed(),
            ),
            IconButton(
              icon: Icon(Icons.forward_10),
              onPressed: () => onSkipForwardPressed(),
            ),
          ],
        ),
      ],
    );
  }
}
