import 'package:flutter/material.dart';
import '../models/podcast.dart';

class PodcastCard extends StatelessWidget {
  final Podcast podcast;
  final VoidCallback onTap;
  final Widget? trailing;

  const PodcastCard({
    Key? key,
    required this.podcast,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
<<<<<<< Updated upstream
      child: SizedBox(
        height: 220, // Reduced height for the entire card
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Podcast Cover Image
              SizedBox(
                height: 140, // Reduced height for the image section
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Container(
                    color: Colors.grey[200],
                    child: podcast.imageUrl.isNotEmpty
                          ? Image.network(
                              podcast.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.mic,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                );
                              },
                            )
                          : Center(
=======
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Podcast Cover Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  color: Colors.grey[200],
                  child: podcast.imageUrl.isNotEmpty
                      ? Image.network(
                          podcast.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
>>>>>>> Stashed changes
                              child: Icon(
                                Icons.mic,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                            ),
                  ),
                ),
              ),
<<<<<<< Updated upstream
              // Podcast Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              podcast.title,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
=======
            ),
            // Podcast Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    podcast.title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    podcast.author,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          podcast.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
>>>>>>> Stashed changes
                          ),
                          if (trailing != null) trailing!,
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber,
                          ),
                          SizedBox(width: 2),
                          Text(
                            podcast.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.category,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              podcast.category,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.headphones,
                            size: 12,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${podcast.episodeCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                ),
=======
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        podcast.rating.toStringAsFixed(1),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.headphones,
                        size: 12,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${podcast.episodeCount}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
>>>>>>> Stashed changes
              ),
            ],
          ),
        ),
      ),
    );
  }
}
