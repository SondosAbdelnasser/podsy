import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../utils/supabase_config.dart';

class UserService {
  final SupabaseClient client = SupabaseConfig.client;

  Future<UserModel?> getUserById(String uid) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();
    
    if (response != null) {
      return UserModel.fromMap(response as Map<String, dynamic>, uid);
    }
    return null;
  }

  Future<List<UserModel>> fetchAllUsers() async {
    final response = await client
        .from('users')
        .select();
    
    return (response as List)
        .map((doc) => UserModel.fromMap(doc as Map<String, dynamic>, doc['id'] as String))
        .toList();
  }

  Future<void> createUser(UserModel user) async {
    await client
        .from('users')
        .insert(user.toMap());
  }

  Future<void> updateUserRole(String uid, bool isAdmin) async {
    await client
        .from('users')
        .update({'is_admin': isAdmin})
        .eq('id', uid);
  }

  Future<void> softDeleteUser(String uid) async {
    try {
      await client
          .from('users')
          .update({'is_deleted': true})
          .eq('id', uid);
    } catch (e) {
      throw Exception('Failed to soft delete user: ${e.toString()}');
    }
  }
}
