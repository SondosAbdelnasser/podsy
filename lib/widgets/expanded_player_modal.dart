import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../services/audio_player_service.dart';
import '../models/episode.dart';
import '../services/podcast_service.dart';
import '../models/podcast_collection.dart';

class ExpandedPlayerModal extends StatefulWidget {
  const ExpandedPlayerModal({Key? key}) : super(key: key);

  @override
  State<ExpandedPlayerModal> createState() => _ExpandedPlayerModalState();
}

class _ExpandedPlayerModalState extends State<ExpandedPlayerModal> {
  PodcastCollection? _collection;
  bool _loadingCollection = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<AudioPlayerService>(context).addListener(_fetchCollection);
    _fetchCollection();
  }

  @override
  void dispose() {
    Provider.of<AudioPlayerService>(context, listen: false).removeListener(_fetchCollection);
    super.dispose();
  }

  Future<void> _fetchCollection() async {
    if (!mounted) return;
    final audioPlayerService = Provider.of<AudioPlayerService>(context, listen: false);
    final currentEpisode = audioPlayerService.currentEpisode;

    if (currentEpisode == null) {
      if (_collection != null) {
        setState(() {
          _collection = null;
          _loadingCollection = false;
        });
      }
      return;
    }

    if (_collection != null && _collection!.id == currentEpisode.collectionId) {
      return;
    }

    setState(() => _loadingCollection = true);
    final podcastService = PodcastService();
    try {
      final collection = await podcastService.getCollectionById(currentEpisode.collectionId);
      if (mounted) {
        setState(() {
          _collection = collection;
          _loadingCollection = false;
        });
      }
    } catch (e) {
      print("Error fetching podcast collection for expanded player: $e");
      if (mounted) {
        setState(() {
          _loadingCollection = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitHours = twoDigits(duration.inHours);
    if (duration.inHours > 0) {
      return "$twoDigitHours:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);
    final currentEpisode = audioPlayerService.currentEpisode;

    if (!audioPlayerService.isInitialized || currentEpisode == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isPlaying = audioPlayerService.isPlaying;
    final isLoading = audioPlayerService.isLoading;
    final currentPosition = audioPlayerService.currentPosition;
    final totalDuration = audioPlayerService.currentEpisode?.duration ?? Duration.zero;
    final playbackSpeed = audioPlayerService.playbackSpeed;
    final imageUrl = _collection?.imageUrl;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Playing Podcast',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _loadingCollection
                ? const SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : imageUrl != null && imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(imageUrl, width: 200, height: 200, fit: BoxFit.cover),
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.mic, color: Colors.grey, size: 80),
                      ),
            const SizedBox(height: 32),
            Text(
              currentEpisode.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              _collection?.title ?? 'Unknown Podcast',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),

            // Seek Bar
            StreamBuilder<Duration?>( 
              stream: audioPlayerService.durationStream,
              builder: (context, snapshot) {
                final duration = snapshot.data ?? Duration.zero;
                return Column(
                  children: [
                    Slider( 
                      min: 0.0,
                      max: duration.inMilliseconds.toDouble(),
                      value: currentPosition.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                      onChanged: (value) {
                        audioPlayerService.seekTo(Duration(milliseconds: value.toInt()));
                      },
                      activeColor: Colors.blue,
                      inactiveColor: Colors.grey[300],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(currentPosition), style: const TextStyle(color: Colors.black54)),
                          Text(_formatDuration(duration), style: const TextStyle(color: Colors.black54)),
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
                  icon: const Icon(Icons.replay_10, size: 48, color: Colors.blue),
                  onPressed: audioPlayerService.skipBackward,
                ),
                const SizedBox(width: 20),
                isLoading
                    ? const CircularProgressIndicator(strokeWidth: 3)
                    : IconButton(
                        icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 72, color: Colors.blue),
                        onPressed: () {
                          if (isPlaying) {
                            audioPlayerService.pauseAudio();
                          } else {
                            audioPlayerService.playAudio(currentEpisode.audioUrl, episode: currentEpisode);
                          }
                        },
                      ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 48, color: Colors.blue),
                  onPressed: audioPlayerService.skipForward,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Playback Speed Control
            Column(
              children: [
                const Text('Playback Speed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                Slider(
                  min: 0.5,
                  max: 2.0,
                  divisions: 3,
                  value: playbackSpeed,
                  onChanged: (value) => audioPlayerService.setPlaybackSpeed(value),
                  label: '${playbackSpeed.toStringAsFixed(1)}x',
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey[300],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [0.5, 1.0, 1.5, 2.0].map((speed) => TextButton(
                    onPressed: () => audioPlayerService.setPlaybackSpeed(speed),
                    child: Text(
                      '${speed.toStringAsFixed(1)}x',
                      style: TextStyle(color: playbackSpeed == speed ? Colors.blue : Colors.black54),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 