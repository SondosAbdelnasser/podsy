class Recommendation {
  final String id;
  final String name;
  final String artists;
  final String imageUrl;

  Recommendation({
    required this.id,
    required this.name,
    required this.artists,
    required this.imageUrl,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] as String,
      name: json['name'] as String,
      artists: json['artists'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artists': artists,
      'imageUrl': imageUrl,
    };
  }
} 