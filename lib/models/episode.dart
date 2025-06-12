class Episode {
  final String id;
  final String collectionId;
  final String title;
  final String? description;
  final String audioUrl;
  final String? imageUrl;
  final Duration duration;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<double>? embedding;
  final int likesCount;
  final int listensCount;

  Episode({
    required this.id,
    required this.collectionId,
    required this.title,
    this.description,
    required this.audioUrl,
    this.imageUrl,
    required this.duration,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.embedding,
    this.likesCount = 0,
    this.listensCount = 0,
  });

  // For compatibility with existing code
  factory Episode.fromMap(Map<String, dynamic> data, String documentId) {
    final durationInSeconds = data['duration'] as int? ?? 0;
    return Episode(
      id: documentId,
      collectionId: data['collection_id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String?,
      audioUrl: data['audio_url'] as String? ?? '',
      imageUrl: data['image_url'] as String?,
      duration: Duration(seconds: durationInSeconds),
      publishedAt: data['published_at'] != null 
          ? DateTime.parse(data['published_at'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
      embedding: (data['embedding'] as List<dynamic>?)?.cast<double>(),
      likesCount: data['likes_count'] as int? ?? 0,
      listensCount: data['listens_count'] as int? ?? 0,
    );
  }

  // For new code using JSON
  factory Episode.fromJson(Map<String, dynamic> json) {
    final durationInSeconds = json['duration'] as int? ?? 0;
    return Episode(
      id: json['id'] as String? ?? '',
      collectionId: json['collection_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      audioUrl: json['audio_url'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      duration: Duration(seconds: durationInSeconds),
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      embedding: (json['embedding'] as List<dynamic>?)?.cast<double>(),
      likesCount: json['likes_count'] as int? ?? 0,
      listensCount: json['listens_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collection_id': collectionId,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'duration': duration.inSeconds,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'embedding': embedding,
      'likes_count': likesCount,
      'listens_count': listensCount,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection_id': collectionId,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'duration': duration.inSeconds,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'embedding': embedding,
      'likes_count': likesCount,
      'listens_count': listensCount,
    };
  }
}
