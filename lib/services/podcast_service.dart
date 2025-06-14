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
import 'category_detection_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PodcastService {
  final SupabaseClient client = SupabaseConfig.client;
  final CategoryDetectionService _categoryService = CategoryDetectionService();

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

  Future<String?> uploadPodcastImage({
    File? imageFile,
    Uint8List? imageBytes,
    String? imageFileName,
    required String collectionId,
  }) async {
    try {
      final fileName = imageFileName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'podcast-images/$collectionId/$fileName';
      
      // Upload the image file
      if (kIsWeb) {
        if (imageBytes == null) throw Exception('No image bytes provided for web upload');
        await client.storage
            .from('podcast-files')
            .uploadBinary(filePath, imageBytes);
      } else {
        if (imageFile == null) throw Exception('No image file provided for mobile upload');
        await client.storage
            .from('podcast-files')
            .upload(filePath, imageFile, fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true
            ));
      }

      // Get the public URL
      return client.storage
          .from('podcast-files')
          .getPublicUrl(filePath);
    } catch (e) {
      print('Error uploading podcast image: $e');
      return null;
    }
  }

  Future<PodcastCollection> createCollection(
    PodcastCollection collection, {
    File? imageFile,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    try {
      // First create the collection to get an ID
      final response = await client
          .from('podcast_collections')
          .insert(collection.toMap())
          .select()
          .single();
      
      final createdCollection = PodcastCollection.fromMap(response as Map<String, dynamic>, response['id'] as String);

      // If an image was provided, upload it and update the collection
      if (imageFile != null || imageBytes != null) {
        final imageUrl = await uploadPodcastImage(
          imageFile: imageFile,
          imageBytes: imageBytes,
          imageFileName: imageFileName,
          collectionId: createdCollection.id,
        );
        
        if (imageUrl != null) {
          // Update the collection with the image URL
          await client
              .from('podcast_collections')
              .update({'image_url': imageUrl})
              .eq('id', createdCollection.id);
          
          // Return updated collection
          return PodcastCollection(
            id: createdCollection.id,
            userId: createdCollection.userId,
            title: createdCollection.title,
            description: createdCollection.description,
            imageUrl: imageUrl,
            createdAt: createdCollection.createdAt,
            updatedAt: createdCollection.updatedAt,
          );
        }
      }
      
      return createdCollection;
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

      // Detect categories from the audio - This is now handled by backend
      // List<String> categories = []; // This line is no longer needed
      // try {
      //   print('Starting category detection for episode: $title');
      //   categories = await _categoryService.analyzePodcast(audioUrl);
      //   print('Detected categories: $categories');
      // } catch (e) {
      //   print('Error detecting categories: $e');
      //   // Continue with upload even if category detection fails
      //   categories = ['Uncategorized'];
      // }

      final episode = episode_model.Episode(
        collectionId: collectionId,
        title: title,
        description: description,
        audioUrl: audioUrl,
        duration: estimatedDuration,
        publishedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        categories: [], // Initialize with empty, backend will update
      );

      Map<String, dynamic> insertedEpisodeData;
      try {
        final response = await client
            .from('episodes')
            .insert(episode.toMap())
            .select(); // Add .select() to get the inserted data
        insertedEpisodeData = (response as List).first as Map<String, dynamic>;
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

      // Trigger backend for category detection asynchronously
      _triggerBackendCategoryDetection(insertedEpisodeData['id'] as String, audioUrl);

    } catch (e) {
      throw Exception('Upload process failed: ${e.toString()}');
    }
  }

  // New function to trigger backend category detection
  Future<void> _triggerBackendCategoryDetection(String episodeId, String audioUrl) async {
    try {
      print('Triggering backend category detection for episodeId: $episodeId');
      final response = await http.post(
        Uri.parse('https://supabase.com/dashboard/project/osduwubkohbzyvndzesd/functions/categorize-episode'), // REPLACE THIS WITH YOUR ACTUAL BACKEND ENDPOINT
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'episodeId': episodeId,
          'audioUrl': audioUrl,
        }),
      );

      if (response.statusCode == 200) {
        print('Backend category detection triggered successfully.');
      } else {
        print('Failed to trigger backend category detection. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Error triggering backend category detection: $e');
    }
  }

  Future<List<episode_model.Episode>> getCollectionEpisodes(String collectionId) async {
    try {
      final response = await client
          .from('episodes')
          .select()
          .eq('collection_id', collectionId)
          .eq('is_deleted', false)
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
          .eq('id', episode.id!);
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

  // Get all podcasts (excluding soft-deleted ones for regular user view)
  Future<List<podcast_model.Podcast>> getAllPodcasts() async {
    try {
      final response = await client
          .from('podcast_collections')
          .select('''
            *,
            episodes(*)
          ''')
          .eq('is_deleted', false) // Filter out soft-deleted podcasts
          .order('created_at', ascending: false);
      
      return (response as List).map((doc) {
        final episodes = (doc['episodes'] as List? ?? [])
            .where((episode) => episode['is_deleted'] == false) // Filter out soft-deleted episodes
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
          imageUrl: doc['image_url'] as String? ?? '', // Use the image URL from the collection
          feedUrl: '', // No feed URL in schema
          episodes: episodes,
          category: 'Personal', // Default category since it's not in the schema
          rating: 0.0, // Default rating since it's not in the schema
          episodeCount: episodes.length,
          userId: doc['user_id'] as String?, // Pass the user_id
        );
      }).toList();
    } catch (e) {
      print('Error in getAllPodcasts: $e'); // Add logging
      throw Exception('Failed to fetch podcasts: ${e.toString()}');
    }
  }

  // New method for admin to get all podcasts (including soft-deleted ones)
  Future<List<podcast_model.Podcast>> getAllPodcastsForAdmin() async {
    try {
      final response = await client
          .from('podcast_collections')
          .select('''
            *,
            episodes(*)
          ''')
          // No .eq('is_deleted', false) filter here for admin view
          .order('created_at', ascending: false);
      
      return (response as List).map((doc) {
        final episodes = (doc['episodes'] as List? ?? [])
            .map((episode) { // No filtering by is_deleted for admin view of episodes
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
          imageUrl: doc['image_url'] as String? ?? '', // Use the image URL from the collection
          feedUrl: '', // No feed URL in schema
          episodes: episodes,
          category: 'Personal', // Default category since it's not in the schema
          rating: 0.0, // Default rating since it's not in the schema
          episodeCount: episodes.length,
          userId: doc['user_id'] as String?, // Pass the user_id
        );
      }).toList();
    } catch (e) {
      print('Error in getAllPodcastsForAdmin: $e'); // Add logging
      throw Exception('Failed to fetch all podcasts for admin: ${e.toString()}');
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
          .eq('is_deleted', false) // Filter out soft-deleted podcasts
          .order('created_at', ascending: false);

      print('Podcasts response: $podcastsResponse');

      return (podcastsResponse as List).map((doc) {
        final episodes = (doc['episodes'] as List? ?? [])
            .where((episode) => episode['is_deleted'] == false) // Filter out soft-deleted episodes
            .map((episode) => podcast_model.Episode(
                  id: episode['id'] as String? ?? '',
                  title: episode['title'] as String? ?? '',
                  description: episode['description'] as String? ?? '',
                  audioUrl: episode['audio_url'] as String? ?? '',
                  publishDate: episode['published_at'] != null 
                      ? DateTime.parse(episode['published_at'] as String)
                      : DateTime.now(),
                  duration: _parseDurationString(episode['duration'] as String? ?? '00:00:00'),
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
          userId: doc['user_id'] as String?, // Pass the user_id
        );
      }).toList();
    } catch (e, stackTrace) {
      print('Error getting followed users episodes: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to load followed users episodes: $e');
    }
  }

  // Helper method to parse duration string
  int _parseDurationString(String durationStr) {
    final parts = durationStr.split(':');
    if (parts.length == 3) {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      return (hours * 3600 + minutes * 60 + seconds); // Convert to milliseconds
    }
    return 0;
  }

  Future<String> _getFirebaseIdToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    final token = await user.getIdToken();
    if (token == null) {
      throw Exception('Failed to get ID token');
    }
    return token;
  }

  Future<void> categorizeEpisode(String episodeId) async {
    try {
      final response = await http.post(
        Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/categorize-episode'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({ 'episodeId': episodeId }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to categorize episode: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error categorizing episode: $e');
    }
  }

  Future<void> softDeletePodcast(String podcastId) async {
    try {
      await client
          .from('podcast_collections')
          .update({'is_deleted': true})
          .eq('id', podcastId);
    } catch (e) {
      throw Exception('Failed to soft delete podcast: ${e.toString()}');
    }
  }

  Future<void> softDeleteEpisode(String episodeId) async {
    try {
      await client
          .from('episodes')
          .update({'is_deleted': true})
          .eq('id', episodeId);
    } catch (e) {
      throw Exception('Failed to soft delete episode: ${e.toString()}');
    }
  }
}

////////////////////////////////////////////////////////



