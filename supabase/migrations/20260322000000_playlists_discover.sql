-- Migration: playlists discover feature
-- Adds source_platform, primary_url, blueprint metadata, likes, and playlist_likes table

-- 1. Make spotify_playlist_id nullable (manual playlists won't have one)
ALTER TABLE playlists ALTER COLUMN spotify_playlist_id DROP NOT NULL;

ALTER TABLE playlists DROP CONSTRAINT IF EXISTS playlists_spotify_playlist_id_key;
DROP INDEX IF EXISTS playlists_spotify_playlist_id_key;
CREATE UNIQUE INDEX playlists_spotify_playlist_id_key
  ON playlists (spotify_playlist_id)
  WHERE spotify_playlist_id IS NOT NULL;

-- 2. Add new columns
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS source_platform text NOT NULL DEFAULT 'other';
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS primary_url text;
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS artists text[] DEFAULT '{}';
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS mood_tags text[] DEFAULT '{}';
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS era text;
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS energy_level text;
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS occasion_tags text[] DEFAULT '{}';
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS vocal_style text;
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS language text DEFAULT 'english';
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS likes_count int DEFAULT 0;
ALTER TABLE playlists ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- 3. Playlist likes table
CREATE TABLE IF NOT EXISTS playlist_likes (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  playlist_id uuid NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  timestamptz DEFAULT now(),
  UNIQUE(playlist_id, user_id)
);

ALTER TABLE playlist_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read playlist likes"
  ON playlist_likes FOR SELECT USING (true);

CREATE POLICY "Authenticated users can like playlist"
  ON playlist_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike playlist"
  ON playlist_likes FOR DELETE USING (auth.uid() = user_id);

-- 4. RPC functions for atomic like counter
CREATE OR REPLACE FUNCTION increment_playlist_likes(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE playlists SET likes_count = likes_count + 1 WHERE id = p_id;
END; $$;

CREATE OR REPLACE FUNCTION decrement_playlist_likes(p_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE playlists SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = p_id;
END; $$;
