import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryDetectionService {
  final String witAiToken = dotenv.env['WIT_AI_TOKEN'] ?? '';
  final String huggingFaceToken = dotenv.env['HUGGINGFACE_TOKEN'] ?? '';

  // Test method to verify token loading
  Future<bool> testWitAiToken() async {
    try {
      print('=== Testing Wit.ai token ===');
      print('1. Checking if .env file is loaded...');
      print('All environment variables: ${dotenv.env}');
      print('2. Checking token value...');
      print('Token value: $witAiToken');
      
      if (witAiToken.isEmpty) {
        print('ERROR: Token is empty! Make sure your .env file exists and contains WIT_AI_TOKEN');
        return false;
      }

      print('3. Making API test call...');
      final response = await http.get(
        Uri.parse('https://api.wit.ai/message?q=test'),
        headers: {
          'Authorization': 'Bearer $witAiToken',
          'Content-Type': 'application/json',
        },
      );

      print('4. API Response Status: ${response.statusCode}');
      print('5. API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('SUCCESS: Token is valid! API connection successful.');
        return true;
      } else {
        print('ERROR: Token validation failed. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR: Exception occurred while testing token: $e');
      return false;
    }
  }

  Future<String> transcribeAudio(String audioUrl) async {
    try {
      print('Starting audio transcription...');
      
      // Download the audio file
      final response = await http.get(Uri.parse(audioUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download audio file');
      }

      print('Audio file downloaded, sending to Wit.ai...');
      
      // Call Wit.ai API for speech recognition
      final speechResponse = await http.post(
        Uri.parse('https://api.wit.ai/speech'),
        headers: {
          'Authorization': 'Bearer $witAiToken',
          'Content-Type': 'audio/wav',
        },
        body: response.bodyBytes,
      );

      if (speechResponse.statusCode != 200) {
        print('Speech recognition failed with status: ${speechResponse.statusCode}');
        print('Response: ${speechResponse.body}');
        throw Exception('Speech recognition failed');
      }

      final transcript = jsonDecode(speechResponse.body)['text'];
      print('Transcription successful!');
      return transcript;
    } catch (e) {
      print('Error in speech recognition: $e');
      rethrow;
    }
  }

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
        print('Category detection failed with status: ${response.statusCode}');
        print('Response: ${response.body}');
        throw Exception('Category detection failed');
      }

      final result = jsonDecode(response.body);
      final scores = result['scores'] as List;
      final labels = result['labels'] as List;

      // Get top 3 categories
      final topIndices = List<int>.generate(scores.length, (i) => i)
        ..sort((a, b) => scores[b].compareTo(scores[a]));
      
      final categories = topIndices.take(3).map((i) => labels[i].toString()).toList();
      print('Categories detected: $categories');
      return categories;
    } catch (e) {
      print('Error in category detection: $e');
      rethrow;
    }
  }

  Future<List<String>> analyzePodcast(String audioUrl) async {
    try {
      print('Starting podcast analysis...');
      
      // First, transcribe the audio
      final transcript = await transcribeAudio(audioUrl);
      print('Transcription completed. Length: ${transcript.length} characters');
      
      // Then, detect categories from the transcript
      final categories = await detectCategories(transcript);
      print('Analysis completed. Categories: $categories');
      
      return categories;
    } catch (e) {
      print('Error in podcast analysis: $e');
      rethrow;
    }
  }

  // Test method to verify Hugging Face token
  Future<bool> testHuggingFaceToken() async {
    try {
      print('=== Testing Hugging Face token ===');
      print('1. Checking if .env file is loaded...');
      print('All environment variables: ${dotenv.env}');
      print('2. Checking token value...');
      print('Token value: $huggingFaceToken');
      
      if (huggingFaceToken.isEmpty) {
        print('ERROR: Token is empty! Make sure your .env file exists and contains HUGGINGFACE_TOKEN');
        return false;
      }

      print('3. Making API test call...');
      final response = await http.post(
        Uri.parse('https://api-inference.huggingface.co/models/facebook/bart-large-mnli'),
        headers: {
          'Authorization': 'Bearer $huggingFaceToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': 'This is a test message',
          'parameters': {
            'candidate_labels': ['Test'],
            'multi_label': true
          }
        }),
      );

      print('4. API Response Status: ${response.statusCode}');
      print('5. API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        print('SUCCESS: Token is valid! API connection successful.');
        return true;
      } else {
        print('ERROR: Token validation failed. Status code: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('ERROR: Exception occurred while testing token: $e');
      return false;
    }
  }
}