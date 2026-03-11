# SwapTunes — Database Schema
> Platform: **Supabase (PostgreSQL)**  
> All IDs are `uuid` with `gen_random_uuid()` default  
> All tables have Row Level Security (RLS) enabled  

---

## Legend
| Symbol | Meaning |
|--------|---------|
| 🔑 PK | Primary Key |
| 🔗 FK | Foreign Key |
| 📇 IX | Indexed |
| ✳️ UQ | Unique Constraint |

---

## Table Overview

```
users
├── creator_profiles       (1:1 — only if user_type = 'creator')
├── user_genres            (1:N — genre preferences)
├── posts                  (1:N)
│   ├── post_likes         (M:M via pivot)
│   ├── comments           (1:N)
│   ├── post_reports       (1:N)
│   └── hidden_posts       (M:M via pivot, per-user)
├── playlists              (1:N — imported from Spotify)
├── follows                (M:M self-referential)
├── collaborations         (1:N — creator only)
├── conversations          (M:M — 1-1 DMs)
│   └── messages           (1:N)
└── notifications          (1:N)
```

---

## Tables

---

### `users`
> Core user table. Managed alongside Supabase Auth (`auth.users`). Linked via `id = auth.users.id`.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK, default `auth.uid()` | Matches Supabase Auth user ID |
| `email` | `text` | NOT NULL, UNIQUE | |
| `full_name` | `text` | NOT NULL | |
| 📇✳️ `username` | `text` | NOT NULL, UNIQUE | e.g. `@dizzpy` |
| `bio` | `text` | NULLABLE | |
| `avatar_url` | `text` | NULLABLE | Supabase Storage URL |
| `user_type` | `enum` | NOT NULL, default `'listener'` | `listener` \| `creator` |
| `is_verified` | `boolean` | default `false` | Creator verified badge |
| `spotify_connected` | `boolean` | default `false` | |
| `spotify_access_token` | `text` | NULLABLE | Encrypted at rest |
| `spotify_refresh_token` | `text` | NULLABLE | Encrypted at rest |
| `created_at` | `timestamptz` | default `now()` | |
| `updated_at` | `timestamptz` | auto-updated | |

```sql
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
```

---

### `user_genres`
> Music genre preferences selected during onboarding or profile edit. Min 3 required.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `user_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | |
| `genre` | `text` | NOT NULL | e.g. `Hip-Hop`, `Jazz`, `Dubstep` |

```sql
CREATE TABLE user_genres (
  id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  genre   text NOT NULL
);
```

---

### `creator_profiles`
> Extended profile for users in Creator mode. Created when user completes Creator Setup.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗✳️ `user_id` | `uuid` | FK → `users.id`, UNIQUE | One per user |
| `role_title` | `text` | NOT NULL | e.g. `Music Producer` |
| `location` | `text` | NULLABLE | e.g. `Homagama, Sri Lanka` |
| `specializations` | `text[]` | NOT NULL | Array of genres |
| `soundcloud_url` | `text` | NULLABLE | |
| `youtube_url` | `text` | NULLABLE | |
| `spotify_artist_url` | `text` | NULLABLE | |
| `apple_music_url` | `text` | NULLABLE | |
| `portfolio_url` | `text` | NULLABLE | |
| `created_at` | `timestamptz` | default `now()` | |

```sql
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
```

---

### `posts`
> Social feed posts. Can include text and/or an image.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `user_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | |
| `content` | `text` | NOT NULL | Post body text |
| `image_url` | `text` | NULLABLE | Supabase Storage URL |
| `likes_count` | `int` | default `0` | Denormalized counter |
| `comments_count` | `int` | default `0` | Denormalized counter |
| 📇 `created_at` | `timestamptz` | default `now()` | Indexed for feed ordering |

```sql
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
```

---

### `post_likes`
> Pivot table — tracks which users liked which posts.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `post_id` | `uuid` | FK → `posts.id` ON DELETE CASCADE | |
| 🔗 `user_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | |
| `created_at` | `timestamptz` | default `now()` | |
| ✳️ | | UNIQUE(`post_id`, `user_id`) | Prevents double-likes |

```sql
CREATE TABLE post_likes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);
```

---

### `comments`
> Comments on posts. No nested replies (flat structure).

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `post_id` | `uuid` | FK → `posts.id` ON DELETE CASCADE | |
| 🔗 `user_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | |
| `content` | `text` | NOT NULL | |
| 📇 `created_at` | `timestamptz` | default `now()` | |

```sql
CREATE TABLE comments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content    text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
```

---

### `post_reports`
> User reports on posts. Reviewed by admin.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `post_id` | `uuid` | FK → `posts.id` | |
| 🔗 `reporter_id` | `uuid` | FK → `users.id` | |
| `reason` | `text` | NULLABLE | |
| `created_at` | `timestamptz` | default `now()` | |

```sql
CREATE TABLE post_reports (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id     uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  reporter_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason      text,
  created_at  timestamptz DEFAULT now()
);
```

---

### `hidden_posts`
> Per-user post hiding. Does not affect other users.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `post_id` | `uuid` | FK → `posts.id` ON DELETE CASCADE | |
| 🔗 `user_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | |
| `created_at` | `timestamptz` | default `now()` | |
| ✳️ | | UNIQUE(`post_id`, `user_id`) | |

```sql
CREATE TABLE hidden_posts (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id    uuid NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(post_id, user_id)
);
```

---

### `follows`
> Self-referential M:M — user following other users.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `follower_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | The user who follows |
| 🔗 `following_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | The user being followed |
| `created_at` | `timestamptz` | default `now()` | |
| ✳️ | | UNIQUE(`follower_id`, `following_id`) | No duplicate follows |

```sql
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
```

---

### `playlists`
> Spotify playlists imported by users. Read-only from Spotify.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `user_id` | `uuid` | FK → `users.id` ON DELETE CASCADE | |
| ✳️ `spotify_playlist_id` | `text` | UNIQUE | Spotify's own ID |
| `name` | `text` | NOT NULL | |
| `description` | `text` | NULLABLE | |
| `cover_image_url` | `text` | NULLABLE | |
| `track_count` | `int` | NOT NULL | |
| `is_public` | `boolean` | NOT NULL | From Spotify |
| `genre_tags` | `text[]` | NULLABLE | User-assigned tags |
| 📇 `created_at` | `timestamptz` | default `now()` | |

```sql
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
```

---

### `collaborations`
> Collaboration opportunities posted by Creators only.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `creator_id` | `uuid` | FK → `users.id` (must be creator) | |
| `title` | `text` | NOT NULL | e.g. `Need Mixing & Mastering` |
| `description` | `text` | NOT NULL | |
| `looking_for` | `text[]` | NOT NULL | e.g. `['Vocalist', 'Producer']` |
| `genre_style` | `text[]` | NULLABLE | e.g. `['Jazz', 'Electronic']` |
| `payment_type` | `enum` | NOT NULL | `paid` \| `revenue_share` \| `free` |
| `status` | `enum` | default `'open'` | `open` \| `closed` |
| 📇 `created_at` | `timestamptz` | default `now()` | |

```sql
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
```

---

### `conversations`
> 1-to-1 DM threads between two users. Optionally linked to a collaboration.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `user_one_id` | `uuid` | FK → `users.id` | Initiator |
| 🔗 `user_two_id` | `uuid` | FK → `users.id` | Recipient |
| 🔗 `collab_id` | `uuid` | FK → `collaborations.id`, NULLABLE | If started from Collab page |
| `last_message_at` | `timestamptz` | NULLABLE | For sorting inbox |
| `created_at` | `timestamptz` | default `now()` | |
| ✳️ | | UNIQUE(`user_one_id`, `user_two_id`) | No duplicate threads |

```sql
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
```

---

### `messages`
> Individual messages within a conversation. Powered by Supabase Realtime.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `conversation_id` | `uuid` | FK → `conversations.id` ON DELETE CASCADE | |
| 🔗 `sender_id` | `uuid` | FK → `users.id` | |
| `content` | `text` | NOT NULL | |
| `is_read` | `boolean` | default `false` | |
| 📇 `created_at` | `timestamptz` | default `now()` | |

```sql
CREATE TABLE messages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content         text NOT NULL,
  is_read         boolean DEFAULT false,
  created_at      timestamptz DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
```

---

### `notifications`
> Activity notifications for all user events.

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| 🔑 `id` | `uuid` | PK | |
| 🔗 `user_id` | `uuid` | FK → `users.id` | Recipient |
| 🔗 `actor_id` | `uuid` | FK → `users.id` | Who triggered it |
| `type` | `enum` | NOT NULL | `like` \| `comment` \| `follow` \| `collab` \| `message` |
| `reference_id` | `uuid` | NULLABLE | ID of the related post/collab/conversation |
| `is_read` | `boolean` | default `false` | |
| 📇 `created_at` | `timestamptz` | default `now()` | |

```sql
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
```

---

## Enums Summary

```sql
user_type_enum        : 'listener' | 'creator'
payment_type_enum     : 'paid' | 'revenue_share' | 'free'
collab_status_enum    : 'open' | 'closed'
notification_type_enum: 'like' | 'comment' | 'follow' | 'collab' | 'message'
```

---

## Supabase Storage Buckets

| Bucket | Access | Used For |
|--------|--------|---------|
| `avatars` | Public | User profile photos |
| `post-images` | Public | Images attached to posts |

---

## RLS Policy Notes (per table)

| Table | Read | Write |
|-------|------|-------|
| `users` | Public (own + others public fields) | Own row only |
| `posts` | Public | Own rows only |
| `post_likes` | Public | Authenticated users |
| `comments` | Public | Authenticated users |
| `follows` | Public | Own rows only |
| `collaborations` | Authenticated (creator type) | Own rows only |
| `conversations` | Own conversations only | Own rows only |
| `messages` | Own conversations only | Participants only |
| `notifications` | Own only | System/triggers only |
| `hidden_posts` | Own only | Own rows only |
