import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/podcast_service.dart';

class UploadEpisodeScreen extends StatefulWidget {
  final String podcastId;
  final String podcastTitle;

  const UploadEpisodeScreen({
    Key? key,
    required this.podcastId,
    required this.podcastTitle,
  }) : super(key: key);

  @override
  _UploadEpisodeScreenState createState() => _UploadEpisodeScreenState();
}

class _UploadEpisodeScreenState extends State<UploadEpisodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PodcastService _podcastService = PodcastService();
  bool _isLoading = false;
  File? _audioFile;
  String? _audioFileName;
  Uint8List? _audioBytes;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          if (kIsWeb) {
            _audioBytes = result.files.single.bytes;
            _audioFileName = result.files.single.name;
          } else {
            _audioFile = File(result.files.single.path!);
            _audioFileName = result.files.single.name;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking audio file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

<<<<<<< Updated upstream
=======
  Future<void> _transcribeAudio() async {
    if (_audioFile == null && _audioBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an audio file first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // First upload the audio file to get a URL
      final audioUrl = await _uploadAudioFile();
      setState(() => _audioUrl = audioUrl);

      // Navigate to transcription screen
      final transcript = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => TranscriptionScreen(
            audioUrl: audioUrl,
            episodeId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      );

      if (transcript != null && _descriptionController.text.isEmpty) {
        _descriptionController.text = 'Transcript:\n$transcript';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

>>>>>>> Stashed changes
  Future<void> _uploadEpisode() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFile == null && _audioBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an audio file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload the episode
      await _podcastService.uploadEpisode(
        collectionId: widget.podcastId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        audioFile: _audioFile,
        audioBytes: _audioBytes,
        audioFileName: _audioFileName,
      );

      // Get the latest episode ID
      final episodes = await _podcastService.getCollectionEpisodes(widget.podcastId);
      if (episodes.isNotEmpty) {
        final latestEpisode = episodes.first;
        // Trigger categorization
        await _podcastService.categorizeEpisode(latestEpisode.id!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Episode uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear the form
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _audioFile = null;
        _audioFileName = null;
        _audioBytes = null;
      });

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading episode: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Upload Episode',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Episode Title',
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintText: 'Enter your episode title',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.black87),
                  hintText: 'Enter your episode description',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Audio Upload Section
              const Text(
                'Audio File',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAudio,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: _audioFile != null || _audioBytes != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.audio_file,
                                size: 32,
                                color: Theme.of(context).primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _audioFileName ?? 'Audio file selected',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Select Audio File',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                            ),
                            Text(
                              '(MP3, WAV, etc.)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
=======
=======
>>>>>>> Stashed changes
                              const SizedBox(height: 8),
                              Text(
                                'Tap to select audio file',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
>>>>>>> Stashed changes
                              ),
                            ),
                          ],
                        ),
                ),
              ),
<<<<<<< Updated upstream
<<<<<<< Updated upstream
              SizedBox(height: 32),
=======
=======
>>>>>>> Stashed changes
              const SizedBox(height: 16),

              // Transcribe Button
              if (_audioFile != null || _audioBytes != null)
                ElevatedButton.icon(
                  onPressed: _transcribeAudio,
                  icon: const Icon(Icons.transcribe),
                  label: const Text('Transcribe Audio'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),

              const SizedBox(height: 24),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes

              // Upload Button
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadEpisode,
                style: ElevatedButton.styleFrom(
<<<<<<< Updated upstream
<<<<<<< Updated upstream
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Upload Episode',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
=======
=======
>>>>>>> Stashed changes
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Upload Episode'),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
              ),
            ],
          ),
        ),
      ),
    );
  }
}