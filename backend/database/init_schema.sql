-- SwapTunes Initial Schema Backup
-- Contains all tables, Enums, Indicies, and RLS Policies.

CREATE TYPE user_type_enum AS ENUM ('listener', 'creator');

CREATE TABLE users (
  id                    uuid PRIMARY KEY REFERENCES auth.users(id),
  email                 text NOT NULL UNIQUE,
  full_name             text NOT NULL,
  username              text NOT NULL UNIQUE,
  bio                   text,
  avatar_url            text,
  user_type             user_type_enum NOT NULL DEFAULT 'listener',
  is_verified           boolean DEFAULT false,
  spotify_connected     boolean DEFAULT false,
  spotify_access_token  text,
  spotify_refresh_token text,
  created_at            timestamptz DEFAULT now(),
  updated_at            timestamptz DEFAULT now()
);

CREATE INDEX idx_users_username ON users(username);

CREATE TABLE user_genres (
  id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  genre   text NOT NULL
);

CREATE TABLE creator_profiles (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  role_title          text NOT NULL,
  location            text,
  specializations     text[] NOT NULL DEFAULT '{}',
  soundcloud_url      text,
  youtube_url         text,
  spotify_artist_url  text,
  apple_music_url     text,
  portfolio_url       text,
  created_at          timestamptz DEFAULT now()
);

CREATE TABLE posts (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content        text NOT NULL,
  image_url      text,
  likes_count    int DEFAULT 0,
  comments_count int DEFAULT 0,
  created_at     timestamptz DEFAULT now()
);

CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_user_id ON posts(user_id);

CREATE TABLE post_likes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);

CREATE TABLE comments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content    text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_comments_post_id ON comments(post_id);

CREATE TABLE post_reports (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  reporter_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason      text,
  created_at  timestamptz DEFAULT now()
);

CREATE TABLE hidden_posts (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);

CREATE TABLE follows (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  following_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at   timestamptz DEFAULT now(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

CREATE INDEX idx_follows_follower ON follows(follower_id);
CREATE INDEX idx_follows_following ON follows(following_id);

CREATE TABLE playlists (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  spotify_playlist_id text NOT NULL UNIQUE,
  name                text NOT NULL,
  description         text,
  cover_image_url     text,
  track_count         int NOT NULL DEFAULT 0,
  is_public           boolean NOT NULL DEFAULT true,
  genre_tags          text[],
  created_at          timestamptz DEFAULT now()
);

CREATE TYPE payment_type_enum AS ENUM ('paid', 'revenue_share', 'free');
CREATE TYPE collab_status_enum AS ENUM ('open', 'closed');

CREATE TABLE collaborations (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title        text NOT NULL,
  description  text NOT NULL,
  looking_for  text[] NOT NULL DEFAULT '{}',
  genre_style  text[],
  payment_type payment_type_enum NOT NULL,
  status       collab_status_enum NOT NULL DEFAULT 'open',
  created_at   timestamptz DEFAULT now()
);

CREATE INDEX idx_collaborations_creator ON collaborations(creator_id);
CREATE INDEX idx_collaborations_status ON collaborations(status);

CREATE TABLE conversations (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_one_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_two_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  collab_id       uuid REFERENCES collaborations(id) ON DELETE SET NULL,
  last_message_at timestamptz,
  created_at      timestamptz DEFAULT now(),
  UNIQUE(user_one_id, user_two_id),
  CHECK (user_one_id != user_two_id)
);

CREATE INDEX idx_conversations_user_one ON conversations(user_one_id);
CREATE INDEX idx_conversations_user_two ON conversations(user_two_id);

CREATE TABLE messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content         text NOT NULL,
  is_read         boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);

CREATE TYPE notification_type_enum AS ENUM ('like','comment','follow','collab','message');

CREATE TABLE notifications (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  actor_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type         notification_type_enum NOT NULL,
  reference_id uuid,
  is_read      boolean DEFAULT false,
  created_at   timestamptz DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);

-- Enable RLS for all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_genres ENABLE ROW LEVEL SECURITY;
ALTER TABLE creator_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE hidden_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaborations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Basic RLS Policies based on 01-database-schema.md
-- Users: public read, own row write
CREATE POLICY "Public read users" ON users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = id);

-- Posts: public read, own row write
CREATE POLICY "Public read posts" ON posts FOR SELECT USING (true);
CREATE POLICY "Users can insert own posts" ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON posts FOR DELETE USING (auth.uid() = user_id);

-- Post Likes: public read, authenticated users can like
CREATE POLICY "Public read post likes" ON post_likes FOR SELECT USING (true);
CREATE POLICY "Authenticated users can like" ON post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike" ON post_likes FOR DELETE USING (auth.uid() = user_id);

-- Comments: public read, authenticated users can comment
CREATE POLICY "Public read comments" ON comments FOR SELECT USING (true);
CREATE POLICY "Authenticated users can comment" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can edit own comment" ON comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comment" ON comments FOR DELETE USING (auth.uid() = user_id);

-- Follows: public read, own row write
CREATE POLICY "Public read follows" ON follows FOR SELECT USING (true);
CREATE POLICY "Users can follow" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow" ON follows FOR DELETE USING (auth.uid() = follower_id);

-- Playlists: public read, own row write
CREATE POLICY "Public read playlists" ON playlists FOR SELECT USING (true);
CREATE POLICY "Users can insert own playlists" ON playlists FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own playlists" ON playlists FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own playlists" ON playlists FOR DELETE USING (auth.uid() = user_id);

-- Hidden posts: own only read/write
CREATE POLICY "Read own hidden posts" ON hidden_posts FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Hide posts for self" ON hidden_posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Unhide posts for self" ON hidden_posts FOR DELETE USING (auth.uid() = user_id);

-- Collaborations: public read, write for creators
CREATE POLICY "Public read collaborations" ON collaborations FOR SELECT USING (true);
CREATE POLICY "Users can write own collaborations" ON collaborations FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Users can update own collaborations" ON collaborations FOR UPDATE USING (auth.uid() = creator_id);
CREATE POLICY "Users can delete own collaborations" ON collaborations FOR DELETE USING (auth.uid() = creator_id);

-- Notifications: own only
CREATE POLICY "Users read own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users delete own notifications" ON notifications FOR DELETE USING (auth.uid() = user_id);

-- RPC functions for atomic counter updates on the posts table.

CREATE OR REPLACE FUNCTION increment_likes(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET likes_count = likes_count + 1 WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_likes(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION increment_comments(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET comments_count = comments_count + 1 WHERE id = p_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_comments(p_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = p_id;
END;
$$;
