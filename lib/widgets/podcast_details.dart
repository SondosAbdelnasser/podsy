// lib/widgets/podcast_details.dart

import 'package:flutter/material.dart';

class PodcastDetails extends StatelessWidget {
  final String title;
  final String? description;
  final String? imageUrl;

  PodcastDetails({
    required this.title,
    this.description,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Podcast image
        if (imageUrl != null)
          Image.network(imageUrl!),
        
        // Podcast title
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        
        // Podcast description
        if (description != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(description!),
          ),
      ],
    );
  }
}
