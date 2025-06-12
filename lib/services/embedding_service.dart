import 'dart:convert';
import 'package:http/http.dart' as http;

enum EmbeddingProvider {
  huggingFace,
  cohere,
}

class EmbeddingService {
  final String apiKey;
  final EmbeddingProvider provider;
  final String? modelName; // Optional model name for Hugging Face
  static const int embeddingDimension = 1536;

  EmbeddingService({
    required this.apiKey,
    required this.provider,
    this.modelName,
  });

  Future<List<double>> getEmbedding(String text) async {
    switch (provider) {
      case EmbeddingProvider.huggingFace:
        return _getHuggingFaceEmbedding(text);
      case EmbeddingProvider.cohere:
        return _getCohereEmbedding(text);
    }
  }

  Future<List<double>> _getHuggingFaceEmbedding(String text) async {
    final url = Uri.parse('https://api-inference.huggingface.co/pipeline/feature-extraction/sentence-transformers/all-MiniLM-L6-v2');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': text,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> embedding = jsonDecode(response.body);
      return embedding.cast<double>();
    } else {
      throw Exception('Failed to get embedding from Hugging Face: ${response.body}');
    }
  }

  Future<List<double>> _getCohereEmbedding(String text) async {
    final url = Uri.parse('https://api.cohere.ai/v1/embed');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'texts': [text],
        'model': 'embed-english-v3.0',
        'input_type': 'search_document',
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> embeddings = data['embeddings'];
      return embeddings[0].cast<double>();
    } else {
      throw Exception('Failed to get embedding from Cohere: ${response.body}');
    }
  }

  // Helper method to combine title and description for better embeddings
  String prepareTextForEmbedding(String title, String? description) {
    if (description == null || description.isEmpty) {
      return title;
    }
    return '$title. $description';
  }
} 