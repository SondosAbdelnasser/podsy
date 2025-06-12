-- Create podcast_collections table
CREATE TABLE IF NOT EXISTS podcast_collections (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES auth.users(id),
    title TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Add RLS (Row Level Security) policies
ALTER TABLE podcast_collections ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own collections
CREATE POLICY "Users can view their own collections"
ON podcast_collections
FOR SELECT
USING (auth.uid()::text = user_id);

-- Allow users to create their own collections
CREATE POLICY "Users can create their own collections"
ON podcast_collections
FOR INSERT
WITH CHECK (auth.uid()::text = user_id);

-- Allow users to update their own collections
CREATE POLICY "Users can update their own collections"
ON podcast_collections
FOR UPDATE
USING (auth.uid()::text = user_id);

-- Allow users to delete their own collections
CREATE POLICY "Users can delete their own collections"
ON podcast_collections
FOR DELETE
USING (auth.uid()::text = user_id);

-- Create indexes
CREATE INDEX idx_podcast_collections_user_id ON podcast_collections(user_id);
CREATE INDEX idx_podcast_collections_created_at ON podcast_collections(created_at);

-- Create episodes table
CREATE TABLE IF NOT EXISTS episodes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    collection_id UUID NOT NULL REFERENCES podcast_collections(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    audio_url TEXT NOT NULL,
    image_url TEXT,
    duration INTEGER NOT NULL,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    embedding vector(1536),
    likes_count INTEGER DEFAULT 0,
    listens_count INTEGER DEFAULT 0
);

-- Add RLS (Row Level Security) policies for episodes
ALTER TABLE episodes ENABLE ROW LEVEL SECURITY;

-- Allow users to view episodes from collections they have access to
CREATE POLICY "Users can view episodes from accessible collections"
ON episodes
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM podcast_collections
        WHERE podcast_collections.id = episodes.collection_id
        AND podcast_collections.user_id = auth.uid()::text
    )
);

-- Allow users to create episodes in their own collections
CREATE POLICY "Users can create episodes in their collections"
ON episodes
FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM podcast_collections
        WHERE podcast_collections.id = episodes.collection_id
        AND podcast_collections.user_id = auth.uid()::text
    )
);

-- Allow users to update episodes in their own collections
CREATE POLICY "Users can update episodes in their collections"
ON episodes
FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM podcast_collections
        WHERE podcast_collections.id = episodes.collection_id
        AND podcast_collections.user_id = auth.uid()::text
    )
);

-- Allow users to delete episodes from their own collections
CREATE POLICY "Users can delete episodes from their collections"
ON episodes
FOR DELETE
USING (
    EXISTS (
        SELECT 1 FROM podcast_collections
        WHERE podcast_collections.id = episodes.collection_id
        AND podcast_collections.user_id = auth.uid()::text
    )
);

-- Create indexes for episodes
CREATE INDEX idx_episodes_collection_id ON episodes(collection_id);
CREATE INDEX idx_episodes_created_at ON episodes(created_at); 