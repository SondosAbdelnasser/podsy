class PodcastCollection {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  PodcastCollection({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PodcastCollection.fromMap(Map<String, dynamic> data, String documentId) {
    return PodcastCollection(
      id: documentId,
      userId: data['user_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['image_url'],
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
} 