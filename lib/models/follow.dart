enum FollowStatus {
  pending,
  accepted,
}

class Follow {
  final String id;
  final String followerId;
  final String followedId;
  final FollowStatus status;
  final DateTime createdAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followedId,
    required this.status,
    required this.createdAt,
  });

  factory Follow.fromMap(Map<String, dynamic> data, String documentId) {
    return Follow(
      id: documentId,
      followerId: data['follower_id'] ?? '',
      followedId: data['followed_id'] ?? '',
      status: FollowStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => FollowStatus.pending,
      ),
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'follower_id': followerId,
      'followed_id': followedId,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 