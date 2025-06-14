-- Add is_deleted column to podcast_collections table
ALTER TABLE podcast_collections
ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

-- Add is_deleted column to episodes table
ALTER TABLE episodes
ADD COLUMN is_deleted BOOLEAN DEFAULT FALSE;

-- Create indexes for better query performance
CREATE INDEX idx_podcast_collections_is_deleted ON podcast_collections(is_deleted);
CREATE INDEX idx_episodes_is_deleted ON episodes(is_deleted); 