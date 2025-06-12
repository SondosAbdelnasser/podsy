import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/transcription_provider.dart';
import '../models/episode.dart';
import '../widgets/episode_card.dart';
import '../services/podcast_service.dart';
import '../services/embedding_service.dart';
import '../config/api_keys.dart';

class TranscriptionScreen extends StatefulWidget {
  final String audioUrl;
  final String episodeId;
  final String? initialTranscript;

  const TranscriptionScreen({
    super.key,
    required this.audioUrl,
    required this.episodeId,
    this.initialTranscript,
  });

  @override
  _TranscriptionScreenState createState() => _TranscriptionScreenState();
}

class _TranscriptionScreenState extends State<TranscriptionScreen> {
  bool _isLoading = false;
  String? _transcript;
  List<Episode> _similarEpisodes = [];
  bool _showTranscript = false;
  late final PodcastService _podcastService;

  @override
  void initState() {
    super.initState();
    final embeddingService = EmbeddingService(
      apiKey: ApiKeys.huggingFaceApiKey,
      provider: EmbeddingProvider.huggingFace,
    );
    _podcastService = PodcastService(
      client: Supabase.instance.client,
      embeddingService: embeddingService,
    );
    _transcript = widget.initialTranscript;
    _loadSimilarEpisodes();
  }

  Future<void> _loadSimilarEpisodes() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transcriptionProvider = Provider.of<TranscriptionProvider>(context, listen: false);
      final similarEpisodes = await transcriptionProvider.findSimilarEpisodes(widget.episodeId);
      
      setState(() {
        _similarEpisodes = similarEpisodes;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error finding similar episodes: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processAudio() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final transcriptionProvider = Provider.of<TranscriptionProvider>(context, listen: false);
      await transcriptionProvider.processAudio(widget.audioUrl, widget.episodeId);
      
      setState(() {
        _transcript = transcriptionProvider.currentTranscript;
        _showTranscript = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing audio: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Similar Episodes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.transcribe),
            onPressed: _processAudio,
            tooltip: 'Show Transcript',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showTranscript && _transcript != null)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Transcript:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_transcript!),
                        ],
                      ),
                    ),
                  )
                else
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Click the transcript button to see the audio text',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                Container(
                  height: 220,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Similar Episodes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _similarEpisodes.isEmpty
                            ? const Center(
                                child: Text('No similar episodes found.'),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                itemCount: _similarEpisodes.length,
                                itemBuilder: (context, index) {
                                  final episode = _similarEpisodes[index];
                                  return FutureBuilder<String>(
                                    future: _podcastService.getCollectionOwnerName(episode.collectionId),
                                    builder: (context, snapshot) {
                                      return Container(
                                        width: 200,
                                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pop(context, _transcript);
                                            },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (episode.imageUrl != null)
                                                  ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(
                                                      top: Radius.circular(12),
                                                    ),
                                                    child: Image.network(
                                                      episode.imageUrl!,
                                                      height: 100,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          height: 100,
                                                          color: Colors.grey[300],
                                                          child: const Icon(
                                                            Icons.podcasts,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                else
                                                  Container(
                                                    height: 100,
                                                    decoration: const BoxDecoration(
                                                      color: Colors.grey,
                                                      borderRadius: BorderRadius.vertical(
                                                        top: Radius.circular(12),
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.podcasts,
                                                      size: 40,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                Padding(
                                                  padding: const EdgeInsets.all(8.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        episode.title,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        snapshot.data ?? 'Unknown',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
} 