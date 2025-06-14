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
  final DateTime? updatedAt;

  Follow({
    required this.id,
    required this.followerId,
    required this.followedId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
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
      updatedAt: data['updated_at'] != null ? DateTime.parse(data['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'follower_id': followerId,
      'followed_id': followedId,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 