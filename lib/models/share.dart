class Share {
  final String id;
  final String userId;
  final String episodeId;
  final String platform;
  final DateTime createdAt;

  Share({
    required this.id,
    required this.userId,
    required this.episodeId,
    required this.platform,
    required this.createdAt,
  });

  factory Share.fromMap(Map<String, dynamic> data, String documentId) {
    return Share(
      id: documentId,
      userId: data['user_id'] ?? '',
      episodeId: data['episode_id'] ?? '',
      platform: data['platform'] ?? '',
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'episode_id': episodeId,
      'platform': platform,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 