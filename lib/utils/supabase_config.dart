import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://baxcgruzuycxpllcpqqw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJheGNncnV6dXljeHBsbGNwcXF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5ODc4MDUsImV4cCI6MjA2MzU2MzgwNX0.1tL7rQEUgIRuuQMgcDaqX8nPH0ThJnWYmbZnnanUuHk';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: true, // Enable debug mode to get more detailed error messages
      );

      // Verify the connection by making a simple query
      final client = Supabase.instance.client;
      await client.from('podcast_collections').select().limit(1);
      
      print('Supabase initialized successfully');
    } catch (e) {
      print('Failed to initialize Supabase: ${e.toString()}');
      rethrow;
    }
  }

  static Future<void> setAuthUser(String userId) async {
    // No-op: We use Firebase for auth, Supabase for DB only
  }
} 
