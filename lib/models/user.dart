class UserModel {
  final String id;
  final String email;
  final String name;
  final bool is_admin;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.is_admin,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      id: documentId,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      is_admin: data['is_admin'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'is_admin': is_admin,
    };
  }
}
