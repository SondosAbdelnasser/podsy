// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';
// import 'admin_dashboard_screen.dart';

// class UploadPodcastScreen extends StatefulWidget {
//   const UploadPodcastScreen({super.key});

//   @override
//   State<UploadPodcastScreen> createState() => _UploadPodcastScreenState();
// }

// class _UploadPodcastScreenState extends State<UploadPodcastScreen> {
//   final _titleController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   File? _selectedFile;
//   bool _isUploading = false;

//   // Future<void> _pickFile() async {
//   //   final result = await FilePicker.platform.pickFiles(type: FileType.audio);
//   //   if (result != null && result.files.single.path != null) {
//   //     setState(() {
//   //       _selectedFile = File(result.files.single.path!);
//   //     });
//   //   }
//   // }

//   // Future<void> _uploadPodcast() async {
//   //   if (_titleController.text.isEmpty || _selectedFile == null) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Title and audio file are required.')),
//   //     );
//   //     return;
//   //   }

//   //   setState(() {
//   //     _isUploading = true;
//   //   });

//   //   try {
//   //     final fileName = _selectedFile!.path.split('/').last;
//   //     final storageResponse = await Supabase.instance.client.storage
//   //         .from('podcasts')
//   //         .upload('audios/$fileName', _selectedFile!);

//   //     final publicUrl = Supabase.instance.client.storage
//   //         .from('podcasts')
//   //         .getPublicUrl('audios/$fileName');

//   //     await Supabase.instance.client.from('podcast_uploads').insert({
//   //       'title': _titleController.text,
//   //       'description': _descriptionController.text,
//   //       'audio_url': publicUrl,
//   //     });

//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       const SnackBar(content: Text('Podcast uploaded successfully!')),
//   //     );

//   //     _titleController.clear();
//   //     _descriptionController.clear();
//   //     setState(() => _selectedFile = null);
//   //   } catch (e) {
//   //     ScaffoldMessenger.of(context).showSnackBar(
//   //       SnackBar(content: Text('Error: $e')),
//   //     );
//   //   } finally {
//   //     setState(() {
//   //       _isUploading = false;
//   //     });
//   //   }
//   // }



//   // PlatformFile? _selectedFile;

// Future<void> _pickFile() async {
//   final result = await FilePicker.platform.pickFiles(
//     type: FileType.audio,
//     withData: true, // Ensures .bytes is filled
//   );
//   if (result != null && result.files.single.bytes != null) {
//     setState(() {
//       _selectedFile = result.files.single as File?; // ✅ PlatformFile with bytes
//     });
//   }
// }


//   Future<void> _uploadPodcast() async {
//   if (_titleController.text.isEmpty || _selectedFile == null || _selectedFile!.bytes == null) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Title and audio file are required.')),
//     );
//     return;
//   }

//   setState(() {
//     _isUploading = true;
//   });

//   try {
//     final fileName = _selectedFile!.name;

//     // Upload using uploadBinary (not upload)
//     final storageResponse = await Supabase.instance.client.storage
//         .from('podcasts')
//         .uploadBinary('audios/$fileName', _selectedFile!.bytes!);

//     final publicUrl = Supabase.instance.client.storage
//         .from('podcasts')
//         .getPublicUrl('audios/$fileName');

//     await Supabase.instance.client.from('podcast_uploads').insert({
//       'title': _titleController.text,
//       'description': _descriptionController.text,
//       'audio_url': publicUrl,
//     });

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Podcast uploaded successfully!')),
//     );

//     _titleController.clear();
//     _descriptionController.clear();
//     setState(() => _selectedFile = null);
//   } catch (e) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Error: $e')),
//     );
//   } finally {
//     setState(() {
//       _isUploading = false;
//     });
//   }
// }




//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Upload Podcast')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text('Title'),
//               TextField(controller: _titleController),
//               const SizedBox(height: 16),
//               const Text('Description'),
//               TextField(
//                 controller: _descriptionController,
//                 maxLines: 4,
//               ),
//               const SizedBox(height: 16),
//               GestureDetector(
//                 onTap: _pickFile,
//                 child: DottedBorder(
//                   color: Colors.grey,
//                   strokeWidth: 2,
//                   dashPattern: [6, 3],
//                   child: Container(
//                     height: 120,
//                     width: double.infinity,
//                     alignment: Alignment.center,
//                     child: Text(
//                       _selectedFile != null
//                           ? 'Selected: ${_selectedFile!.path.split('/').last}'
//                           : 'Drag & Drop or Tap to Select Audio File',
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton(
//                 onPressed: _isUploading ? null : _uploadPodcast,
//                 child: _isUploading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('Upload'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// extension on File {
//   get bytes => null;
  
//    get name => null;
// }

// class DottedBorder extends StatelessWidget {
//   final Widget child;
//   final Color color;
//   final double strokeWidth;
//   final List<double> dashPattern;

//   const DottedBorder({
//     super.key,
//     required this.child,
//     required this.color,
//     required this.strokeWidth,
//     required this.dashPattern,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return CustomPaint(
//       painter: _DottedBorderPainter(
//         color: color,
//         strokeWidth: strokeWidth,
//         dashPattern: dashPattern,
//       ),
//       child: child,
//     );
//   }
// }

// class _DottedBorderPainter extends CustomPainter {
//   final Color color;
//   final double strokeWidth;
//   final List<double> dashPattern;

//   _DottedBorderPainter({
//     required this.color,
//     required this.strokeWidth,
//     required this.dashPattern,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..style = PaintingStyle.stroke;

//     double x = 0;
//     bool draw = true;
//     final path = Path()
//       ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

//     for (final metric in path.computeMetrics()) {
//       final length = metric.length;
//       double distance = 0.0;
//       while (distance < length) {
//         final len = dashPattern[(draw ? 0 : 1) % dashPattern.length];
//         if (draw) {
//           canvas.drawPath(
//             metric.extractPath(distance, distance + len),
//             paint,
//           );
//         }
//         distance += len;
//         draw = !draw;
//       }
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

/////////////////////claude 
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/podcast_service.dart';
import '../models/podcast_collection.dart';
import '../models/episode.dart';

class UploadPodcastScreen extends StatefulWidget {
  @override
  _UploadPodcastScreenState createState() => _UploadPodcastScreenState();
}

class _UploadPodcastScreenState extends State<UploadPodcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final PodcastService _podcastService = PodcastService();
  
  File? _selectedAudioFile;
  String? _selectedFileName;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudioFile = File(result.files.single.path!);
          _selectedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadPodcast() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAudioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an audio file'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Create or get existing podcast collection for the user
      PodcastCollection? collection = await _podcastService.getUserCollection(
        authProvider.currentUser!.id,
      );

      if (collection == null) {
        // Create a default collection for the user
        collection = await _podcastService.createCollection(
          PodcastCollection(
            id: '',
            userId: authProvider.currentUser!.id,
            title: '${authProvider.currentUser!.name}\'s Podcasts',
            description: 'Personal podcast collection',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Upload audio file to Supabase Storage
      setState(() => _uploadProgress = 0.3);
      
      final audioUrl = await _podcastService.uploadAudioFile(
        _selectedAudioFile!,
        '${authProvider.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}_${_selectedFileName}',
        onProgress: (progress) {
          setState(() => _uploadProgress = 0.3 + (progress * 0.6));
        },
      );

      setState(() => _uploadProgress = 0.9);

      // Create episode record
      final episode = Episode(
        id: '',
        collectionId: collection.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        audioUrl: audioUrl,
        duration: Duration(seconds: 0), // Will be updated when audio metadata is available
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _podcastService.createEpisode(episode);

      setState(() => _uploadProgress = 1.0);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Podcast uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedAudioFile = null;
        _selectedFileName = null;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF6A1B9A);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Upload Podcast',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Enter podcast title',
                  hintStyle: TextStyle(color: Colors.white30),
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
                  prefixIcon: Icon(Icons.title, color: themeColor),
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 20),
              
              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Enter podcast description (optional)',
                  hintStyle: TextStyle(color: Colors.white30),
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
                  prefixIcon: Icon(Icons.description, color: themeColor),
                  alignLabelWithHint: true,
                ),
                style: TextStyle(color: Colors.white, fontSize: 16),
                maxLines: 4,
                textAlignVertical: TextAlignVertical.top,
              ),
              
              SizedBox(height: 20),
              
              // File picker section
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedAudioFile != null ? themeColor : Colors.white30,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _selectedAudioFile != null ? Icons.audiotrack : Icons.upload_file,
                      size: 48,
                      color: _selectedAudioFile != null ? themeColor : Colors.white70,
                    ),
                    SizedBox(height: 12),
                    Text(
                      _selectedAudioFile != null 
                          ? 'Selected: $_selectedFileName'
                          : 'No audio file selected',
                      style: TextStyle(
                        color: _selectedAudioFile != null ? themeColor : Colors.white70,
                        fontSize: 16,
                        fontWeight: _selectedAudioFile != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isUploading ? null : _pickAudioFile,
                      icon: Icon(Icons.folder_open, color: Colors.white),
                      label: Text(
                        _selectedAudioFile != null ? 'Change File' : 'Select Audio File',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Upload progress indicator
              if (_isUploading) ...[
                Column(
                  children: [
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.white30,
                      valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Uploading... ${(_uploadProgress * 100).toInt()}%',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
              
              // Upload button
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadPodcast,
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Uploading...', style: TextStyle(fontSize: 18)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload, size: 24),
                          SizedBox(width: 8),
                          Text('Upload Podcast', style: TextStyle(fontSize: 18)),
                        ],
                      ),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 56),
                  backgroundColor: _isUploading ? Colors.grey : themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isUploading ? 0 : 4,
                ),
              ),
              
              SizedBox(height: 20),
              
              // Help text
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white05,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: themeColor, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Upload Guidelines',
                          style: TextStyle(
                            color: themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Supported formats: MP3, WAV, AAC, M4A\n'
                      '• Maximum file size: 100MB\n'
                      '• Recommended quality: 128kbps or higher\n'
                      '• Title and audio file are required',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}