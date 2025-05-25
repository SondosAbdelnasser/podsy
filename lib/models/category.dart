class Category {
  final String id;
  final String name;
  final String? parentId;

  Category({
    required this.id,
    required this.name,
    this.parentId,
  });

  factory Category.fromMap(Map<String, dynamic> data, String documentId) {
    return Category(
      id: documentId,
      name: data['name'] ?? '',
      parentId: data['parent_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'parent_id': parentId,
    };
  }
} 