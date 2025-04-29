import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

class UploadPodcastPage extends StatefulWidget {
  @override
  _UploadPodcastPageState createState() => _UploadPodcastPageState();
}

class _UploadPodcastPageState extends State<UploadPodcastPage> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? fileName;
  PlatformFile? pickedFile;

  Future<void> pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null) {
      setState(() {
        pickedFile = result.files.first;
        fileName = pickedFile!.name;
      });
    }
  }

  Future<void> uploadPodcast() async {
    if (pickedFile == null || titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Complete all fields")));
      return;
    }

    final storageRef = FirebaseStorage.instance.ref().child('podcasts/${pickedFile!.name}');
    final uploadTask = await storageRef.putData(pickedFile!.bytes!);
    final audioUrl = await uploadTask.ref.getDownloadURL();

    await FirebaseFirestore.instance.collection('podcasts').add({
      'title': titleController.text,
      'description': descriptionController.text,
      'audioUrl': audioUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Uploaded successfully")));
    titleController.clear();
    descriptionController.clear();
    setState(() {
      pickedFile = null;
      fileName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Podcast')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickAudioFile,
              child: Text(fileName ?? 'Pick Audio File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: uploadPodcast,
              child: Text('Upload Podcast'),
            ),
          ],
        ),
      ),
    );
  }
}
