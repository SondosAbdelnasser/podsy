class Interest {
  final String id;
  final String name;

  Interest({required this.id, required this.name});

  factory Interest.fromMap(Map<String, dynamic> map) {
    return Interest(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
    );
  }
}
