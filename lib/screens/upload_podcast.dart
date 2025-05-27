import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../models/podcast_collection.dart';
import '../models/episode.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class UploadPodcastScreen extends StatefulWidget {
  @override
  _UploadPodcastScreenState createState() => _UploadPodcastScreenState();
}

class _UploadPodcastScreenState extends State<UploadPodcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PodcastService _podcastService = PodcastService();

  File? _audioFile;
  Uint8List? _audioBytes; // For web
  String? _audioFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: kIsWeb, // get bytes on web
      );

      if (result != null) {
        if (kIsWeb) {
          setState(() {
            _audioBytes = result.files.single.bytes;
            _audioFileName = result.files.single.name;
            _audioFile = null;
          });
        } else {
          setState(() {
            _audioFile = File(result.files.single.path!);
            _audioFileName = result.files.single.name;
            _audioBytes = null;
          });
        }
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

  Future<void> _uploadPodcast() async {
    if (!_formKey.currentState!.validate()) return;
    
    if ((!kIsWeb && _audioFile == null) || (kIsWeb && _audioBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an audio file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated, plz login again');
      }

      PodcastCollection? collection = await _podcastService.getUserCollection(currentUser.id);
      
      if (collection == null) {
        collection = PodcastCollection(
          id: '',
          userId: currentUser.id,
          title: "${currentUser.name}'s Podcasts",
          description: "Personal podcast collection",
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        collection = await _podcastService.createCollection(collection);
      }

      await _podcastService.uploadEpisode(
        collectionId: collection.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        audioFile: kIsWeb ? null : _audioFile,
        audioBytes: kIsWeb ? _audioBytes : null,
        audioFileName: _audioFileName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Podcast uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _audioFile = null;
        _audioBytes = null;
        _audioFileName = null;
      });

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading podcast: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Podcast'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: themeColor),
                  SizedBox(height: 16),
                  Text(
                    'Uploading podcast...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Input
                    Text(
                      'Title',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Enter podcast title',
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Description Input
                    Text(
                      'Description',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter podcast description (optional)',
                        hintStyle: TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: themeColor, width: 2),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 24),

                    // Audio File Selection
                    Text(
                      'Audio File',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _audioFile != null ? themeColor : Colors.white24,
                          width: _audioFile != null ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _audioFile != null ? Icons.audiotrack : Icons.upload_file,
                            color: _audioFile != null ? themeColor : Colors.white54,
                            size: 48,
                          ),
                          SizedBox(height: 12),
                          if (_audioFile != null)
                            Text(
                              _audioFileName ?? 'Audio file selected',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            )
                          else
                            Text(
                              'No audio file selected',
                              style: TextStyle(color: Colors.white54),
                            ),
                          SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _pickAudioFile,
                            icon: Icon(Icons.folder_open),
                            label: Text(_audioFile != null ? 'Change File' : 'Choose File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white24,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32),

                    // Upload Button
                    ElevatedButton(
                      onPressed: _uploadPodcast,
                      child: Text(
                        'Upload',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 56),
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}