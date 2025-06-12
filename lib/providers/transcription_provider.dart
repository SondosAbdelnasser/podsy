import 'package:flutter/foundation.dart';
import '../services/transcription_service.dart';
import '../services/embedding_service.dart';
import '../services/supabase_service.dart';
import '../models/episode.dart';

class TranscriptionProvider with ChangeNotifier {
  final TranscriptionService _transcriptionService = TranscriptionService(client: client, embeddingService: embeddingService);
  final EmbeddingService _embeddingService = EmbeddingService(apiKey: apiKey, provider: provider);
  final SupabaseService _supabaseService = SupabaseService(client: client);

  bool _isProcessing = false;
  String? _currentTranscript;
  String? _error;

  bool get isProcessing => _isProcessing;
  String? get currentTranscript => _currentTranscript;
  String? get error => _error;

  Future<void> processAudio(String audioUrl, String episodeId) async {
    _isProcessing = true;
    _error = null;
    notifyListeners();

    try {
      // Get transcript from AssemblyAI
      final transcript = await _transcriptionService.transcribeAudio(audioUrl);
      _currentTranscript = transcript;

      // Generate embeddings using Hugging Face
      final embedding = await _embeddingService.generateEmbedding(transcript);

      // Store transcript and embedding in Supabase
      await _supabaseService.storeTranscriptAndEmbedding(
        episodeId: episodeId,
        transcript: transcript,
        embedding: embedding,
      );

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<List<Episode>> findSimilarEpisodes(String episodeId) async {
    try {
      final similarEpisodes = await _supabaseService.findSimilarEpisodes(episodeId);
      return similarEpisodes;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
} 