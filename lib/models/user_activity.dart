enum ActivityType {
  listen,
  like,
  share,
  complete
}

class UserActivity {
  final String id;
  final String userId;
  final String episodeId;
  final ActivityType type;
  final DateTime timestamp;
  final double? listenDuration; // in seconds, null for non-listen activities
  final Map<String, dynamic>? metadata;

  UserActivity({
    required this.id,
    required this.userId,
    required this.episodeId,
    required this.type,
    required this.timestamp,
    this.listenDuration,
    this.metadata,
  });

  factory UserActivity.fromJson(Map<String, dynamic> json) {
    return UserActivity(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      episodeId: json['episode_id'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['type']}',
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      listenDuration: json['listen_duration'] as double?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'episode_id': episodeId,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'listen_duration': listenDuration,
      'metadata': metadata,
    };
  }
} 