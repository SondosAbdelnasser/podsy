-- Function to get trending episodes
CREATE OR REPLACE FUNCTION get_trending_episodes(days integer, limit_count integer)
RETURNS TABLE (
    id uuid,
    title text,
    description text,
    audio_url text,
    duration interval,
    published_at timestamptz,
    created_at timestamptz,
    updated_at timestamptz,
    image_url text,
    likes_count integer,
    listens_count integer,
    collection_id uuid,
    user_id text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.*,
        COUNT(DISTINCT l.id) as likes_count,
        COUNT(DISTINCT ua.id) as listens_count
    FROM episodes e
    LEFT JOIN likes l ON e.id = l.episode_id
    LEFT JOIN user_activity ua ON e.id = ua.episode_id 
        AND ua.type = 'listen' 
        AND ua.timestamp > NOW() - (days || ' days')::interval
    GROUP BY e.id
    ORDER BY (likes_count + listens_count) DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get similar episodes using vector similarity
CREATE OR REPLACE FUNCTION get_similar_episodes(episode_id uuid, limit_count integer)
RETURNS TABLE (
    id uuid,
    title text,
    description text,
    audio_url text,
    duration interval,
    published_at timestamptz,
    created_at timestamptz,
    updated_at timestamptz,
    image_url text,
    similarity float
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.*,
        1 - (e.embedding <=> (SELECT embedding FROM episodes WHERE id = episode_id)) as similarity
    FROM episodes e
    WHERE e.id != episode_id
    ORDER BY similarity DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get popular episodes
CREATE OR REPLACE FUNCTION get_popular_episodes(limit_count integer)
RETURNS TABLE (
    id uuid,
    title text,
    description text,
    audio_url text,
    duration interval,
    published_at timestamptz,
    created_at timestamptz,
    updated_at timestamptz,
    image_url text,
    likes_count integer,
    listens_count integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.*,
        COUNT(DISTINCT l.id) as likes_count,
        COUNT(DISTINCT ua.id) as listens_count
    FROM episodes e
    LEFT JOIN likes l ON e.id = l.episode_id
    LEFT JOIN user_activity ua ON e.id = ua.episode_id AND ua.type = 'listen'
    GROUP BY e.id
    ORDER BY (likes_count + listens_count) DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to get recommendations from history
CREATE OR REPLACE FUNCTION get_recommendations_from_history(
    user_id text,
    episode_ids uuid[],
    limit_count integer
)
RETURNS TABLE (
    id uuid,
    title text,
    description text,
    audio_url text,
    duration interval,
    published_at timestamptz,
    created_at timestamptz,
    updated_at timestamptz,
    image_url text,
    similarity float
) AS $$
BEGIN
    RETURN QUERY
    WITH user_episodes AS (
        SELECT embedding
        FROM episodes
        WHERE id = ANY(episode_ids)
    ),
    avg_embedding AS (
        SELECT AVG(embedding) as embedding
        FROM user_episodes
    )
    SELECT 
        e.*,
        1 - (e.embedding <=> (SELECT embedding FROM avg_embedding)) as similarity
    FROM episodes e
    WHERE e.id != ALL(episode_ids)
    ORDER BY similarity DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;

-- Function to update episode engagement metrics
CREATE OR REPLACE FUNCTION update_episode_engagement()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.type = 'listen' THEN
        UPDATE episodes
        SET listens_count = listens_count + 1
        WHERE id = NEW.episode_id;
    ELSIF NEW.type = 'like' THEN
        UPDATE episodes
        SET likes_count = likes_count + 1
        WHERE id = NEW.episode_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for updating engagement metrics
CREATE TRIGGER update_episode_engagement_trigger
AFTER INSERT ON user_activity
FOR EACH ROW
EXECUTE FUNCTION update_episode_engagement(); 