//claude hwa wel screen bta3 upload 
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/podcast_collection.dart';
import '../models/episode.dart';
import '../utils/supabase_config.dart';

class PodcastService {
  final SupabaseClient client = SupabaseConfig.client;

  // Collection methods
  Future<PodcastCollection?> getUserCollection(String userId) async {
    try {
      final response = await client
          .from('podcast_collections')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      
      if (response != null) {
        return PodcastCollection.fromMap(response as Map<String, dynamic>, response['id'] as String);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user collection: ${e.toString()}');
    }
  }

  Future<PodcastCollection> createCollection(PodcastCollection collection) async {
    try {
      final response = await client
          .from('podcast_collections')
          .insert(collection.toMap())
          .select()
          .single();
      
      return PodcastCollection.fromMap(response as Map<String, dynamic>, response['id'] as String);
    } catch (e) {
      throw Exception('Failed to create collection: ${e.toString()}');
    }
  }

  Future<List<PodcastCollection>> getUserCollections(String userId) async {
    try {
      final response = await client
          .from('podcast_collections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((doc) => PodcastCollection.fromMap(doc as Map<String, dynamic>, doc['id'] as String))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch collections: ${e.toString()}');
    }
  }

  // Episode methods
  Future<void> uploadEpisode({
    required String collectionId,
    required String title,
    String? description,
    File? audioFile, // for mobile
    Uint8List? audioBytes, // for web
    String? audioFileName,
  }) async {
    try {
      final fileName = audioFileName ?? '${DateTime.now().millisecondsSinceEpoch}.mp3';
      final filePath = 'podcasts/$collectionId/$fileName';
      
      if (kIsWeb) {
        if (audioBytes == null) throw Exception('No audio bytes provided for web upload');
        await client.storage
            .from('podcast-files')
            .uploadBinary(filePath, audioBytes);
      } else {
        if (audioFile == null) throw Exception('No audio file provided for mobile upload');
        await client.storage
            .from('podcast-files')
            .upload(filePath, audioFile);
      }

      final audioUrl = client.storage
          .from('podcast-files')
          .getPublicUrl(filePath);

      Duration estimatedDuration;
      if (!kIsWeb && audioFile != null) {
        final fileStat = await audioFile.stat();
        estimatedDuration = Duration(seconds: (fileStat.size / 16000).round());
      } else if (kIsWeb && audioBytes != null) {
        estimatedDuration = Duration(seconds: (audioBytes.length / 16000).round());
      } else {
        estimatedDuration = Duration.zero;
      }

      final episode = Episode(
        id: '',
        collectionId: collectionId,
        title: title,
        description: description,
        audioUrl: audioUrl,
        duration: estimatedDuration,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await client
          .from('episodes')
          .insert(episode.toMap());

    } catch (e) {
      throw Exception('Failed to upload episode: ${e.toString()}');
    }
  }

  Future<List<Episode>> getCollectionEpisodes(String collectionId) async {
    try {
      final response = await client
          .from('episodes')
          .select()
          .eq('collection_id', collectionId)
          .order('published_at', ascending: false);
      
      return (response as List)
          .map((doc) => Episode.fromMap(doc as Map<String, dynamic>, doc['id'] as String))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch episodes: ${e.toString()}');
    }
  }

  Future<Episode?> getEpisodeById(String episodeId) async {
    try {
      final response = await client
          .from('episodes')
          .select()
          .eq('id', episodeId)
          .maybeSingle();
      
      if (response != null) {
        return Episode.fromMap(response as Map<String, dynamic>, response['id'] as String);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get episode: ${e.toString()}');
    }
  }

  Future<void> deleteEpisode(String episodeId) async {
    try {
      // Get episode details first to delete the audio file
      final episode = await getEpisodeById(episodeId);
      if (episode != null) {
        // Extract file path from URL and delete from storage
        final uri = Uri.parse(episode.audioUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 3) {
          final filePath = pathSegments.sublist(2).join('/'); // Skip bucket and 'object' segments
          await client.storage
              .from('podcast-files')
              .remove([filePath]);
        }
      }

      // Delete episode record
      await client
          .from('episodes')
          .delete()
          .eq('id', episodeId);
    } catch (e) {
      throw Exception('Failed to delete episode: ${e.toString()}');
    }
  }

  Future<void> updateEpisode(Episode episode) async {
    try {
      final updatedEpisode = Episode(
        id: episode.id,
        collectionId: episode.collectionId,
        title: episode.title,
        description: episode.description,
        audioUrl: episode.audioUrl,
        duration: episode.duration,
        publishedAt: episode.publishedAt,
        createdAt: episode.createdAt,
        updatedAt: DateTime.now(),
      );

      await client
          .from('episodes')
          .update(updatedEpisode.toMap())
          .eq('id', episode.id);
    } catch (e) {
      throw Exception('Failed to update episode: ${e.toString()}');
    }
  }

  // Get all public episodes (for discovery)
  Future<List<Episode>> getAllEpisodes({int limit = 20, int offset = 0}) async {
    try {
      final response = await client
          .from('episodes')
          .select('''
            *,
            podcast_collections!inner(*)
          ''')
          .order('published_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      return (response as List)
          .map((doc) => Episode.fromMap(doc as Map<String, dynamic>, doc['id'] as String))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all episodes: ${e.toString()}');
    }
  }
}