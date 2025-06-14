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
    );
  }
}

class Episode {
  final String id;
  final String title;
  final String description;
  final String audioUrl;
  final DateTime publishDate;
  final int duration;
  final String imageUrl;

  Episode({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.publishDate,
    required this.duration,
    required this.imageUrl,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['trackId'].toString(),
      title: json['trackName'] ?? '',
      description: json['description'] ?? '',
      audioUrl: json['episodeUrl'] ?? '',
      publishDate: DateTime.parse(json['releaseDate'] ?? DateTime.now().toIso8601String()),
      duration: json['trackTimeMillis'] ?? 0,
      imageUrl: json['artworkUrl600'] ?? '',
    );
  }
} 