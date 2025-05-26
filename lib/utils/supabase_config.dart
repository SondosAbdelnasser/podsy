import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  static Future<void> setAuthUser(String userId) async {
    // No-op: We use Firebase for auth, Supabase for DB only
  }
} 
// -- Create podcast_collections table
// CREATE TABLE IF NOT EXISTS podcast_collections (
//     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//     user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
//     title VARCHAR(255) NOT NULL,
//     description TEXT,
//     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
//     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
// );

// -- Create episodes table  
// CREATE TABLE IF NOT EXISTS episodes (
//     id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
//     collection_id UUID NOT NULL REFERENCES podcast_collections(id) ON DELETE CASCADE,
//     title VARCHAR(255) NOT NULL,
//     description TEXT,
//     audio_url TEXT NOT NULL,
//     duration BIGINT NOT NULL, -- Duration in milliseconds
//     published_at TIMESTAMP WITH TIME ZONE,
//     created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
//     updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
// );

// -- Create indexes for better performance
// CREATE INDEX IF NOT EXISTS idx_podcast_collections_user_id ON podcast_collections(user_id);
// CREATE INDEX IF NOT EXISTS idx_episodes_collection_id ON episodes(collection_id);
// CREATE INDEX IF NOT EXISTS idx_episodes_published_at ON episodes(published_at DESC);

// -- Enable RLS (Row Level Security)
// ALTER TABLE podcast_collections ENABLE ROW LEVEL SECURITY;
// ALTER TABLE episodes ENABLE ROW LEVEL SECURITY;

// -- RLS Policies for podcast_collections
// CREATE POLICY "Users can view all podcast collections" ON podcast_collections
//     FOR SELECT USING (true);

// CREATE POLICY "Users can insert their own podcast collections" ON podcast_collections
//     FOR INSERT WITH CHECK (auth.uid() = user_id);

// CREATE POLICY "Users can update their own podcast collections" ON podcast_collections
//     FOR UPDATE USING (auth.uid() = user_id);

// CREATE POLICY "Users can delete their own podcast collections" ON podcast_collections
//     FOR DELETE USING (auth.uid() = user_id);

// -- RLS Policies for episodes
// CREATE POLICY "Users can view all episodes" ON episodes
//     FOR SELECT USING (true);

// CREATE POLICY "Users can insert episodes for their collections" ON episodes
//     FOR INSERT WITH CHECK (
//         EXISTS (
//             SELECT 1 FROM podcast_collections 
//             WHERE id = collection_id AND user_id = auth.uid()
//         )
//     );

// CREATE POLICY "Users can update episodes for their collections" ON episodes
//     FOR UPDATE USING (
//         EXISTS (
//             SELECT 1 FROM podcast_collections 
//             WHERE id = collection_id AND user_id = auth.uid()
//         )
//     );

// CREATE POLICY "Users can delete episodes for their collections" ON episodes
//     FOR DELETE USING (
//         EXISTS (
//             SELECT 1 FROM podcast_collections 
//             WHERE id = collection_id AND user_id = auth.uid()
//         )
//     );

// -- Create storage bucket for podcast audio files
// INSERT INTO storage.buckets (id, name, public) 
// VALUES ('podcast-audio', 'podcast-audio', true)
// ON CONFLICT (id) DO NOTHING;

// -- Storage policies for podcast audio
// CREATE POLICY "Anyone can view podcast audio files" ON storage.objects
//     FOR SELECT USING (bucket_id = 'podcast-audio');

// CREATE POLICY "Authenticated users can upload podcast audio files" ON storage.objects
//     FOR INSERT WITH CHECK (
//         bucket_id = 'podcast-audio' AND 
//         auth.role() = 'authenticated'
//     );

// CREATE POLICY "Users can update their own podcast audio files" ON storage.objects
//     FOR UPDATE USING (
//         bucket_id = 'podcast-audio' AND 
//         auth.uid()::text = (storage.foldername(name))[1]
//     );

// CREATE POLICY "Users can delete their own podcast audio files" ON storage.objects
//     FOR DELETE USING (
//         bucket_id = 'podcast-audio' AND 
//         auth.uid()::text = (storage.foldername(name))[1]
//     );