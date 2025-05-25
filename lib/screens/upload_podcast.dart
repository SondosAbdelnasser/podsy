import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadPodcastScreen extends StatefulWidget {
  const UploadPodcastScreen({super.key});

  @override
  State<UploadPodcastScreen> createState() => _UploadPodcastScreenState();
}

class _UploadPodcastScreenState extends State<UploadPodcastScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _uploadPodcast() async {
    if (_titleController.text.isEmpty || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and audio file are required.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = _selectedFile!.path.split('/').last;
      final storageResponse = await Supabase.instance.client.storage
          .from('podcasts')
          .upload('audios/$fileName', _selectedFile!);

      final publicUrl = Supabase.instance.client.storage
          .from('podcasts')
          .getPublicUrl('audios/$fileName');

      await Supabase.instance.client.from('podcast_uploads').insert({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'audio_url': publicUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podcast uploaded successfully!')),
      );

      _titleController.clear();
      _descriptionController.clear();
      setState(() => _selectedFile = null);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Podcast')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Title'),
              TextField(controller: _titleController),
              const SizedBox(height: 16),
              const Text('Description'),
              TextField(
                controller: _descriptionController,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickFile,
                child: DottedBorder(
                  color: Colors.grey,
                  strokeWidth: 2,
                  dashPattern: [6, 3],
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      _selectedFile != null
                          ? 'Selected: ${_selectedFile!.path.split('/').last}'
                          : 'Drag & Drop or Tap to Select Audio File',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadPodcast,
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DottedBorder extends StatelessWidget {
  final Widget child;
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        strokeWidth: strokeWidth,
        dashPattern: dashPattern,
      ),
      child: child,
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<double> dashPattern;

  _DottedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    double x = 0;
    bool draw = true;
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      double distance = 0.0;
      while (distance < length) {
        final len = dashPattern[(draw ? 0 : 1) % dashPattern.length];
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, distance + len),
            paint,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
