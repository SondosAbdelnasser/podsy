import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/podcast_service.dart';
import '../models/episode.dart';
import '../models/podcast_collection.dart';

class MiniPlayerBar extends StatefulWidget {
  final VoidCallback? onExpand;
  const MiniPlayerBar({Key? key, this.onExpand}) : super(key: key);

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar> {
  PodcastCollection? _collection;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Listen to changes in current episode to fetch collection
    Provider.of<AudioPlayerService>(context).addListener(_fetchCollection);
    _fetchCollection(); // Initial fetch
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
          _loading = false;
        });
      }
      return;
    }

    // Only fetch if the collection ID has changed or if it's null
    if (_collection != null && _collection!.id == currentEpisode.collectionId) {
      return; // Already have the correct collection
    }

    setState(() => _loading = true);
    final podcastService = PodcastService();
    try {
      final collection = await podcastService.getCollectionById(currentEpisode.collectionId);
      if (mounted) {
        setState(() {
          _collection = collection;
          _loading = false;
        });
      }
    } catch (e) {
      print("Error fetching podcast collection for mini player: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);
    final currentEpisode = audioPlayerService.currentEpisode;

    if (currentEpisode == null) return const SizedBox.shrink(); // Hide if no audio is playing

    final isPlaying = audioPlayerService.isPlaying;
    final episodeTitle = currentEpisode.title;
    final imageUrl = _collection?.imageUrl;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        elevation: 8,
        color: Colors.white,
        child: InkWell(
          onTap: widget.onExpand,
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                if (_loading)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (imageUrl != null && imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.mic, color: Colors.grey, size: 32),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    episodeTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: Icon(isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, size: 32, color: Colors.blue),
                  onPressed: () {
                    if (isPlaying) {
                      audioPlayerService.pauseAudio();
                    } else {
                      audioPlayerService.playAudio(currentEpisode.audioUrl, episode: currentEpisode); // Pass episode here
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up, size: 32),
                  onPressed: widget.onExpand,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 