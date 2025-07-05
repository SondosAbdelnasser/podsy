import 'episode.dart';

class Podcast {
  final String id;
  final String title;
  final String author;
  final String description;
  final String imageUrl;
  final String feedUrl;
  final List<Episode> episodes;
  final String category;
  final double rating;
  final int episodeCount;
  final String? userId;
  final bool isDeleted;

  Podcast({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.imageUrl,
    required this.feedUrl,
    required this.episodes,
    required this.category,
    required this.rating,
    required this.episodeCount,
    this.userId,
    this.isDeleted = false,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    return Podcast(
      id: json['collectionId'].toString(),
      title: json['collectionName'] ?? '',
      author: json['artistName'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['artworkUrl600'] ?? '',
      feedUrl: json['feedUrl'] ?? '',
      episodes: [], // Will be populated separately
      category: json['primaryGenreName'] ?? '',
      rating: (json['averageUserRating'] ?? 0.0).toDouble(),
      episodeCount: json['trackCount'] ?? 0,
      userId: json['userId'] as String?,
      isDeleted: json['is_deleted'] ?? false,
    );
  }

  factory Podcast.fromMap(Map<String, dynamic> data) {
    return Podcast(
      id: data['id'] as String,
      title: data['title'] ?? '',
      author: data['author'] ?? 'User',
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? '',
      feedUrl: data['feed_url'] ?? '',
      episodes: [], // Episodes are handled separately
      category: data['category'] ?? 'Personal',
      rating: (data['rating'] ?? 0.0).toDouble(),
      episodeCount: data['episode_count'] ?? 0,
      userId: data['user_id'] as String?,
      isDeleted: data['is_deleted'] ?? false,
    );
  }
} 