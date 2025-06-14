import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';

class TranscriptionService {
  final String _apiKey;
  final SupabaseClient _supabase;
  static const int _maxFileSize = 100 * 1024 * 1024; // 100MB

  TranscriptionService(this._supabase) : _apiKey = dotenv.env['ASSEMBLY_API_KEY']!;

  // Upload audio file to storage
  Future<String> uploadAudio(File audioFile, {Function(double)? onProgress}) async {
    try {
      // Check file size
      final fileSize = await audioFile.length();
      if (fileSize > _maxFileSize) {
        throw Exception('File size exceeds maximum limit of 100MB');
      }

      // Generate unique filename
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(audioFile.path)}';
      final filePath = 'audio/$fileName';

      // Upload to Supabase Storage
      final fileBytes = await audioFile.readAsBytes();
      final response = await _supabase.storage
          .from('audio')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(
              contentType: 'audio/mpeg',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('audio')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload audio: $e');
    }
  }

  // Transcribe audio with progress tracking
  Future<String> transcribeAudio(String audioUrl, {Function(double)? onProgress}) async {
    try {
      // First, upload the audio file to Assembly AI
      final uploadResponse = await http.post(
        Uri.parse('https://api.assemblyai.com/v2/upload'),
        headers: {
          'authorization': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'audio_url': audioUrl,
        }),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload audio: ${uploadResponse.body}');
      }

      final uploadData = jsonDecode(uploadResponse.body);
      final audioId = uploadData['id'];

      // Start the transcription
      final transcriptResponse = await http.post(
        Uri.parse('https://api.assemblyai.com/v2/transcript'),
        headers: {
          'authorization': _apiKey,
          'content-type': 'application/json',
        },
        body: jsonEncode({
          'audio_url': audioUrl,
          'language_code': 'en',
          'punctuate': true,
          'format_text': true,
          'auto_chapters': true,
          'entity_detection': true,
          'sentiment_analysis': true,
        }),
      );

      if (transcriptResponse.statusCode != 200) {
        throw Exception('Failed to start transcription: ${transcriptResponse.body}');
      }

      final transcriptData = jsonDecode(transcriptResponse.body);
      final transcriptId = transcriptData['id'];

      // Poll for the transcription result with progress updates
      String? transcript;
      Map<String, dynamic>? metadata;
      while (transcript == null) {
        await Future.delayed(const Duration(seconds: 3));

        final resultResponse = await http.get(
          Uri.parse('https://api.assemblyai.com/v2/transcript/$transcriptId'),
          headers: {
            'authorization': _apiKey,
          },
        );

        if (resultResponse.statusCode != 200) {
          throw Exception('Failed to get transcription: ${resultResponse.body}');
        }

        final resultData = jsonDecode(resultResponse.body);
        if (resultData['status'] == 'completed') {
          transcript = resultData['text'];
          metadata = {
            'chapters': resultData['chapters'],
            'entities': resultData['entities'],
            'sentiment': resultData['sentiment'],
          };
          onProgress?.call(1.0); // 100% complete
        } else if (resultData['status'] == 'error') {
          throw Exception('Transcription failed: ${resultData['error']}');
        } else {
          // Update progress
          final progress = resultData['progress'] ?? 0.0;
          onProgress?.call(progress);
        }
      }

      // Save transcription and metadata to database
      await _saveTranscription(transcript, metadata);

      return transcript;
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }

  // Save transcription and metadata to database
  Future<void> _saveTranscription(String transcript, Map<String, dynamic>? metadata) async {
    try {
      await _supabase.from('transcriptions').insert({
        'text': transcript,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error saving transcription: $e');
    }
  }
} 