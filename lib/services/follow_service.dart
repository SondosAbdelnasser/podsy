import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/follow.dart';
import '../utils/supabase_config.dart';

class FollowService {
  final SupabaseClient client = SupabaseConfig.client;

  Future<void> sendFollowRequest(String followerId, String followedId) async {
    try {
      // Check if a follow request already exists
      final existingRequest = await client
          .from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId)
          .maybeSingle();

      if (existingRequest != null) {
        throw Exception('A follow request already exists');
      }

      // Create new follow request
      await client.from('follows').insert({
        'follower_id': followerId,
        'followed_id': followedId,
        'status': FollowStatus.pending.toString().split('.').last,
        'created_at': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to send follow request: ${e.message} (Code: ${e.code})');
    } catch (e) {
      throw Exception('Failed to send follow request: ${e.toString()}');
    }
  }

  Future<void> acceptFollowRequest(String followId) async {
    try {
      await client
          .from('follows')
          .update({
            'status': FollowStatus.accepted.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', followId);
    } catch (e) {
      throw Exception('Failed to accept follow request: ${e.toString()}');
    }
  }

  Future<void> rejectFollowRequest(String followId) async {
    try {
      await client
          .from('follows')
          .delete()
          .eq('id', followId);
    } catch (e) {
      throw Exception('Failed to reject follow request: ${e.toString()}');
    }
  }

  Future<List<Follow>> getPendingFollowRequests(String userId) async {
    try {
      final response = await client
          .from('follows')
          .select()
          .eq('followed_id', userId)
          .eq('status', FollowStatus.pending.toString().split('.').last)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Follow.fromMap(data as Map<String, dynamic>, data['id'] as String))
          .toList();
    } catch (e) {
      throw Exception('Failed to get pending follow requests: ${e.toString()}');
    }
  }

  Future<List<Follow>> getAcceptedFollows(String userId) async {
    try {
      final response = await client
          .from('follows')
          .select()
          .eq('followed_id', userId)
          .eq('status', FollowStatus.accepted.toString().split('.').last)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Follow.fromMap(data as Map<String, dynamic>, data['id'] as String))
          .toList();
    } catch (e) {
      throw Exception('Failed to get accepted follows: ${e.toString()}');
    }
  }

  Future<List<Follow>> getFollowing(String userId) async {
    try {
      final response = await client
          .from('follows')
          .select()
          .eq('follower_id', userId)
          .eq('status', FollowStatus.accepted.toString().split('.').last)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => Follow.fromMap(data as Map<String, dynamic>, data['id'] as String))
          .toList();
    } catch (e) {
      throw Exception('Failed to get following: ${e.toString()}');
    }
  }

  Future<bool> isFollowing(String followerId, String followedId) async {
    try {
      final response = await client
          .from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId)
          .eq('status', FollowStatus.accepted.toString().split('.').last)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check follow status: ${e.toString()}');
    }
  }

  Future<bool> hasPendingRequest(String followerId, String followedId) async {
    try {
      final response = await client
          .from('follows')
          .select()
          .eq('follower_id', followerId)
          .eq('followed_id', followedId)
          .eq('status', FollowStatus.pending.toString().split('.').last)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check pending request: ${e.toString()}');
    }
  }
} 