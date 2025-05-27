//claude hwa wel screen bta3 upload 
import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/podcast_collection.dart';
import '../models/episode.dart' as episode_model;
import '../models/podcast.dart' as podcast_model;
import '../utils/supabase_config.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      // Get the public URL of the uploaded file
      String audioUrl;
      try {
        audioUrl = client.storage
            .from('podcast-files')
            .getPublicUrl(filePath);
      } catch (urlError) {
        throw Exception('Failed to get public URL: ${urlError.toString()}');
      }

      Duration estimatedDuration;
      if (!kIsWeb && audioFile != null) {
        final fileStat = await audioFile.stat();
        estimatedDuration = Duration(seconds: (fileStat.size / 16000).round());
      } else if (kIsWeb && audioBytes != null) {
        estimatedDuration = Duration(seconds: (audioBytes.length / 16000).round());
      } else {
        estimatedDuration = Duration.zero;
      }

      final episode = episode_model.Episode(
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

      try {
        await client
            .from('episodes')
            .insert(episode.toMap());
      } catch (dbError) {
        // If database insert fails, try to clean up the uploaded file
        try {
          await client.storage
              .from('podcast-files')
              .remove([filePath]);
        } catch (cleanupError) {
          print('Failed to cleanup storage after db error: ${cleanupError.toString()}');
        }
        throw Exception('Failed to create episode record: ${dbError.toString()}');
      }

    } catch (e) {
      throw Exception('Upload process failed: ${e.toString()}');
    }
  }

  Future<List<episode_model.Episode>> getCollectionEpisodes(String collectionId) async {
    try {
      final response = await client
          .from('episodes')
          .select()
          .eq('collection_id', collectionId)
          .order('published_at', ascending: false);
      
      return (response as List).map((doc) {
        // Parse duration string (format: "HH:MM:SS")
        int durationInSeconds = 0;
        if (doc['duration'] != null) {
          final durationStr = doc['duration'] as String;
          final parts = durationStr.split(':');
          if (parts.length == 3) {
            durationInSeconds = int.parse(parts[0]) * 3600 + // hours
                              int.parse(parts[1]) * 60 +    // minutes
                              int.parse(parts[2]);          // seconds
          }
        }

        return episode_model.Episode(
          id: doc['id'] as String? ?? '',
          collectionId: doc['collection_id'] as String? ?? '',
          title: doc['title'] as String? ?? '',
          description: doc['description'] as String?,
          audioUrl: doc['audio_url'] as String? ?? '',
          duration: Duration(seconds: durationInSeconds),
          publishedAt: doc['published_at'] != null 
              ? DateTime.parse(doc['published_at'] as String)
              : null,
          createdAt: DateTime.parse(doc['created_at'] as String),
          updatedAt: DateTime.parse(doc['updated_at'] as String),
        );
      }).toList();
    } catch (e) {
      print('Error in getCollectionEpisodes: $e'); // Add logging
      throw Exception('Failed to fetch episodes: ${e.toString()}');
    }
  }

  Future<episode_model.Episode?> getEpisodeById(String episodeId) async {
    try {
      final response = await client
          .from('episodes')
          .select()
          .eq('id', episodeId)
          .maybeSingle();
      
      if (response != null) {
        return episode_model.Episode.fromMap(response as Map<String, dynamic>, response['id'] as String);
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

  Future<void> updateEpisode(episode_model.Episode episode) async {
    try {
      final updatedEpisode = episode_model.Episode(
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
  Future<List<episode_model.Episode>> getAllEpisodes({int limit = 20, int offset = 0}) async {
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
          .map((doc) => episode_model.Episode.fromMap(doc as Map<String, dynamic>, doc['id'] as String))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch all episodes: ${e.toString()}');
    }
  }

  // Get all podcasts
  Future<List<podcast_model.Podcast>> getAllPodcasts() async {
    try {
      final response = await client
          .from('podcast_collections')
          .select('''
            *,
            episodes(*)
          ''')
          .order('created_at', ascending: false);
      
      return (response as List).map((doc) {
        final episodes = (doc['episodes'] as List? ?? [])
            .map((episode) {
              // Parse duration string (format: "HH:MM:SS")
              int durationInSeconds = 0;
              if (episode['duration'] != null) {
                final durationStr = episode['duration'] as String;
                final parts = durationStr.split(':');
                if (parts.length == 3) {
                  durationInSeconds = int.parse(parts[0]) * 3600 + // hours
                                    int.parse(parts[1]) * 60 +    // minutes
                                    int.parse(parts[2]);          // seconds
                }
              }

              return podcast_model.Episode(
                id: episode['id'] as String? ?? '',
                title: episode['title'] as String? ?? '',
                description: episode['description'] as String? ?? '',
                audioUrl: episode['audio_url'] as String? ?? '',
                publishDate: episode['published_at'] != null 
                    ? DateTime.parse(episode['published_at'] as String)
                    : DateTime.now(),
                duration: durationInSeconds * 1000, // Convert to milliseconds
                imageUrl: '', // No image URL in episodes table
              );
            })
            .toList();
        
        return podcast_model.Podcast(
          id: doc['id'] as String? ?? '',
          title: doc['title'] as String? ?? '',
          author: 'User', // Default author since it's not in the schema
          description: doc['description'] as String? ?? '',
          imageUrl: '', // No cover URL in schema
          feedUrl: '', // No feed URL in schema
          episodes: episodes,
          category: 'Personal', // Default category since it's not in the schema
          rating: 0.0, // Default rating since it's not in the schema
          episodeCount: episodes.length,
        );
      }).toList();
    } catch (e) {
      print('Error in getAllPodcasts: $e'); // Add logging
      throw Exception('Failed to fetch podcasts: ${e.toString()}');
    }
  }

  Future<List<podcast_model.Podcast>> getFollowedUsersEpisodes() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser == null) {
        print('Error: User not authenticated with Firebase');
        throw Exception('User not authenticated');
      }

      print('Fetching followed users for user: ${currentUser.uid}');

      // First get the list of followed users
      final followingResponse = await supabase
          .from('follows')
          .select('followed_id')
          .eq('follower_id', currentUser.uid);

      print('Following response: $followingResponse');

      if (followingResponse.isEmpty) {
        print('No followed users found');
        return [];
      }

      final followingIds = followingResponse.map((f) => f['followed_id'] as String).toList();
      print('Following IDs: $followingIds');

      // Then get all podcasts from followed users
      final podcastsResponse = await supabase
          .from('podcast_collections')
          .select('''
            *,
            episodes(*)
          ''')
          .filter('user_id', 'in', followingIds)
          .order('created_at', ascending: false);

      print('Podcasts response: $podcastsResponse');

      return (podcastsResponse as List).map((doc) {
        final episodes = (doc['episodes'] as List? ?? [])
            .map((episode) => podcast_model.Episode(
                  id: episode['id'] as String? ?? '',
                  title: episode['title'] as String? ?? '',
                  description: episode['description'] as String? ?? '',
                  audioUrl: episode['audio_url'] as String? ?? '',
                  publishDate: episode['published_at'] != null 
                      ? DateTime.parse(episode['published_at'] as String)
                      : DateTime.now(),
                  duration: (episode['duration'] as int? ?? 0) * 1000,
                  imageUrl: '', // No image URL in episodes table
                ))
            .toList();

        return podcast_model.Podcast(
          id: doc['id'] as String? ?? '',
          title: doc['title'] as String? ?? '',
          author: doc['user_id'] as String? ?? '', // We'll need to fetch user details separately
          description: doc['description'] as String? ?? '',
          imageUrl: doc['image_url'] as String? ?? '',
          feedUrl: '', // Not needed for this use case
          episodes: episodes,
          category: doc['category'] as String? ?? 'Uncategorized',
          rating: 0.0, // Default rating
          episodeCount: episodes.length,
        );
      }).toList();
    } catch (e, stackTrace) {
      print('Error getting followed users episodes: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to load followed users episodes: $e');
    }
  }
}

////////////////////////////////////////////////////////



