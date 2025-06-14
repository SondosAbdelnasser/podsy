import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Episode {
  final String? id;
  final String collectionId;
  final String title;
  final String? description;
  final String audioUrl;
  final String? imageUrl;
  final Duration duration;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> categories;
  final bool isDeleted;

  Episode({
    this.id,
    required this.collectionId,
    required this.title,
    this.description,
    required this.audioUrl,
    this.imageUrl,
    required this.duration,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
    this.categories = const [],
    this.isDeleted = false,
  });

  factory Episode.fromMap(Map<String, dynamic> data, String documentId) {
    return Episode(
      id: documentId,
      collectionId: data['collection_id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      audioUrl: data['audio_url'] ?? '',
      imageUrl: data['image_url'],
      duration: Duration(microseconds: (data['duration'] as int) * 1000),
      publishedAt: data['published_at'] != null ? DateTime.parse(data['published_at']) : null,
      createdAt: DateTime.parse(data['created_at']),
      updatedAt: DateTime.parse(data['updated_at']),
      categories: List<String>.from(data['categories'] ?? []),
      isDeleted: data['is_deleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'collection_id': collectionId,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'duration': duration.inMicroseconds ~/ 1000,
      'published_at': publishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'categories': categories,
      'is_deleted': isDeleted,
    };
  }
}

final String huggingFaceToken = dotenv.env['HUGGINGFACE_TOKEN'] ?? '';

Future<List<String>> detectCategories(String text) async {
  try {
    print('Starting category detection...');
    
    // Call Hugging Face API for text classification
    final response = await http.post(
      Uri.parse('https://api-inference.huggingface.co/models/facebook/bart-large-mnli'),
      headers: {
        'Authorization': 'Bearer $huggingFaceToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': text,
        'parameters': {
          'candidate_labels': [
            'Technology', 'Business', 'Education', 'Entertainment', 
            'Health', 'Science', 'Sports', 'News', 'Arts', 'Music', 
            'Society & Culture', 'Religion & Spirituality', 'True Crime', 
            'Comedy', 'Politics', 'History', 'Self-Improvement', 
            'Food', 'Travel'
          ],
          'multi_label': true
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Category detection failed');
    }

    final result = jsonDecode(response.body);
    final scores = result['scores'] as List;
    final labels = result['labels'] as List;

    final topIndices = List<int>.generate(scores.length, (i) => i)
      ..sort((a, b) => scores[b].compareTo(scores[a]));
    
    return topIndices.take(3).map((i) => labels[i].toString()).toList();
  } catch (e) {
    print('Error in category detection: $e');
    return ['Uncategorized'];
  }
}
