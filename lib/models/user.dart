class UserModel {
  final String id;
  final String email;
  final String name;
  final String? username;
  final bool isAdmin;
  final bool autoAcceptFollows;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.username,
    required this.isAdmin,
    required this.autoAcceptFollows,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      username: data['username'],
      isAdmin: data['is_admin'] ?? false,
      autoAcceptFollows: data['auto_accept_follows'] ?? true,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      isDeleted: data['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'username': username,
      'is_admin': isAdmin,
      'auto_accept_follows': autoAcceptFollows,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}
