import 'package:flutter/material.dart';
import '../../models/episode.dart';

class EpisodeCard extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;
  final VoidCallback? onLike;
  final bool isLiked;
  final bool showPlayButton;

  const EpisodeCard({
    Key? key,
    required this.episode,
    required this.onTap,
    this.onLike,
    this.isLiked = false,
    this.showPlayButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Episode Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: episode.imageUrl != null
                    ? Image.network(
                        episode.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 16),
              // Episode Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      episode.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(episode.duration),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                    if (episode.description != null && episode.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        episode.description!,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: isLiked ? Colors.red : Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${episode.likesCount}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.headphones,
                          color: Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${episode.listensCount}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Play Button
              if (showPlayButton)
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.deepPurple,
                    size: 32,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[800],
      child: Icon(Icons.mic, color: Colors.grey[600]),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
} 