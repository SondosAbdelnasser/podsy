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