class Like {
  final String id;
  final String userId;
  final String episodeId;
  final DateTime createdAt;

  Like({
    required this.id,
    required this.userId,
    required this.episodeId,
    required this.createdAt,
  });

  factory Like.fromMap(Map<String, dynamic> data, String documentId) {
    return Like(
      id: documentId,
      userId: data['user_id'] ?? '',
      episodeId: data['episode_id'] ?? '',
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'episode_id': episodeId,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 