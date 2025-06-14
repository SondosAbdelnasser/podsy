import 'package:flutter/foundation.dart';
import '../services/transcription_service.dart';
import '../services/embedding_service.dart';
import '../services/supabase_service.dart';
import '../models/episode.dart';

class TranscriptionProvider with ChangeNotifier {
  final TranscriptionService _transcriptionService;
  final EmbeddingService _embeddingService;
  final SupabaseService _supabaseService;
  String? _transcript;
  List<Episode> _similarEpisodes = [];
  bool _isLoading = false;
  String? _error;

  TranscriptionProvider({
    required TranscriptionService transcriptionService,
    required EmbeddingService embeddingService,
    required SupabaseService supabaseService,
  })  : _transcriptionService = transcriptionService,
        _embeddingService = embeddingService,
        _supabaseService = supabaseService;

  String? get transcript => _transcript;
  List<Episode> get similarEpisodes => _similarEpisodes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> transcribeAudio(String audioPath) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Transcribe audio
      _transcript = await _transcriptionService.transcribeAudio(audioPath);

      // Generate embedding for the transcript
      final embedding = await _embeddingService.getEmbedding(_transcript!);

      // Store transcript and embedding in Supabase
      await _supabaseService.storeEmbedding(
        episodeId: DateTime.now().millisecondsSinceEpoch.toString(), // Generate a unique ID
        embedding: embedding,
        transcript: _transcript!,
      );

      // Find similar episodes
      await _findSimilarEpisodes();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> _findSimilarEpisodes() async {
    try {
      final embedding = await _embeddingService.getEmbedding(_transcript!);
      final similarEpisodesData = await _supabaseService.searchSimilarEpisodes(embedding);
      _similarEpisodes = similarEpisodesData.map((data) => Episode.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearTranscript() {
    _transcript = null;
    _similarEpisodes = [];
    _error = null;
    notifyListeners();
  }
} 