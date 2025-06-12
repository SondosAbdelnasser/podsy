import 'dart:convert';
import 'package:http/http.dart' as http;

class TranscriptionService {
  static const String _baseUrl = 'https://api.assemblyai.com/v2';
  final String _apiKey;

  TranscriptionService(this._apiKey);

  Future<String> transcribeAudio(String audioUrl) async {
    try {
      // Start transcription
      final response = await http.post(
        Uri.parse('$_baseUrl/transcript'),
        headers: {
          'authorization': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'audio_url': audioUrl,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to start transcription: ${response.body}');
      }

      final transcriptId = jsonDecode(response.body)['id'];

      // Poll for transcription completion
      String transcript;
      do {
        await Future.delayed(const Duration(seconds: 3));
        final statusResponse = await http.get(
          Uri.parse('$_baseUrl/transcript/$transcriptId'),
          headers: {
            'authorization': _apiKey,
          },
        );

        if (statusResponse.statusCode != 200) {
          throw Exception('Failed to get transcription status: ${statusResponse.body}');
        }

        final status = jsonDecode(statusResponse.body);
        if (status['status'] == 'error') {
          throw Exception('Transcription failed: ${status['error']}');
        }

        transcript = status['text'] ?? '';
      } while (transcript.isEmpty);

      return transcript;
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }
} 