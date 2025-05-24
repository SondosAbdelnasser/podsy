import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://baxcgruzuycxpllcpqqw.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJheGNncnV6dXljeHBsbGNwcXF3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc5ODc4MDUsImV4cCI6MjA2MzU2MzgwNX0.1tL7rQEUgIRuuQMgcDaqX8nPH0ThJnWYmbZnnanUuHk';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
} 