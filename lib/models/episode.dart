class Episode {
  final String id;
  final String collectionId;
  final String title;
  final String? description;
  final String audioUrl;
  final String? imageUrl;  // imageUrl +
  final Duration duration;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Episode({
    required this.id,
    required this.collectionId,
    required this.title,
    this.description,
    required this.audioUrl,
    this.imageUrl,  // zyada 
    required this.duration,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Episode.fromMap(Map<String, dynamic> data, String documentId) {
    return Episode(
      id: documentId,
      collectionId: data['collection_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      audioUrl: data['audio_url'] ?? '',
      imageUrl: data['image_url'],  // de ktbt0 fe supa base bnfs alzft 
      duration: Duration(microseconds: (data['duration'] as int) * 1000),
      publishedAt: data['published_at'] != null ? DateTime.parse(data['published_at']) : null,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collection_id': collectionId,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'image_url': imageUrl,  // de zyada 
      'duration': duration.inMicroseconds ~/ 1000,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
