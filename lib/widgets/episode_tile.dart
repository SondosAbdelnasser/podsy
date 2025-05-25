import 'package:flutter/material.dart';

class EpisodeTile extends StatelessWidget {
  final Map<String, dynamic> episode;

  const EpisodeTile({required this.episode, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: const CircleAvatar(
        radius: 25,
        backgroundColor: Colors.deepPurpleAccent,
        child: Icon(Icons.podcasts, color: Colors.white),
      ),
      title: Text(
        episode['title'] ?? 'Episode',
        style: const TextStyle(color: Colors.white),
      ),
      subtitle: Text(
        "${episode['host'] ?? 'Host'} • ${episode['duration'] ?? '25 min'}",
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: const Icon(Icons.play_arrow, color: Colors.white),
      onTap: () {
        // TODO: Navigate to play screen or episode details
      },
    );
  }
}
