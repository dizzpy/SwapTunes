# Report Database Schema

Source files read: `supabase/migrations/20260322000000_playlists_discover.sql`. `supabase/seed.sql` was not present in this checkout. Only schema facts present in the migration are documented here.

## Migration Inventory

| Migration file | Timestamp inferred from filename | Purpose found in source |
|---|---:|---|
| `20260322000000_playlists_discover.sql` | 2026-03-22 00:00:00 | Adds playlist discover metadata, makes `playlists.spotify_playlist_id` nullable, changes its uniqueness to ignore nulls, creates `playlist_likes`, enables RLS for playlist likes, and creates playlist like counter RPC functions. |

## Enum Types

No PostgreSQL enum types were created or altered in the migration. `source_platform`, `energy_level`, `vocal_style`, and similar fields are stored as `text` or `text[]`.

## Table: `playlists`

The migration alters an existing `playlists` table. The full original `CREATE TABLE playlists` statement was not present in `supabase/migrations/`, so pre-existing columns, original primary key, and original foreign keys could not be fully determined from source.

### Columns Added Or Altered

| Column | Type | Nullable | Default | Constraints / notes |
|---|---|---:|---|---|
| `spotify_playlist_id` | Could not determine from source | Yes | Could not determine from source | Existing column altered with `DROP NOT NULL`. Existing unique constraint/index was dropped and replaced by a partial unique index where the value is not null. |
| `source_platform` | `text` | No | `'other'` | Added if not exists. |
| `primary_url` | `text` | Yes | None | Added if not exists. |
| `artists` | `text[]` | Yes | `'{}'` | Added if not exists. |
| `mood_tags` | `text[]` | Yes | `'{}'` | Added if not exists. |
| `era` | `text` | Yes | None | Added if not exists. |
| `energy_level` | `text` | Yes | None | Added if not exists. |
| `occasion_tags` | `text[]` | Yes | `'{}'` | Added if not exists. |
| `vocal_style` | `text` | Yes | None | Added if not exists. |
| `language` | `text` | Yes | `'english'` | Added if not exists. |
| `likes_count` | `int` | Yes | `0` | Added if not exists. |
| `updated_at` | `timestamptz` | Yes | `now()` | Added if not exists. |

### Keys And Indexes

| Type | Name | Definition / description |
|---|---|---|
| Primary key | Could not determine from source | Original table definition was not present in the migration. |
| Foreign keys | Could not determine from source | Original table definition was not present in the migration. |
| Unique index | `playlists_spotify_playlist_id_key` | Unique index on `playlists(spotify_playlist_id)` with predicate `spotify_playlist_id IS NOT NULL`. This allows multiple manual playlists with null Spotify IDs while preserving uniqueness for imported Spotify playlists. |

### RLS Policies

No `playlists` RLS policies were created or altered in the migration.

## Table: `playlist_likes`

### Columns

| Column | Type | Nullable | Default | Constraints / notes |
|---|---|---:|---|---|
| `id` | `uuid` | No | `gen_random_uuid()` | Primary key. |
| `playlist_id` | `uuid` | No | None | Foreign key to `playlists(id)` with `ON DELETE CASCADE`. Included in unique pair with `user_id`. |
| `user_id` | `uuid` | No | None | Foreign key to `users(id)` with `ON DELETE CASCADE`. Must equal `auth.uid()` for inserts/deletes under RLS. Included in unique pair with `playlist_id`. |
| `created_at` | `timestamptz` | Yes | `now()` | Creation timestamp. |

### Keys And Constraints

| Type | Name | Definition / description |
|---|---|---|
| Primary key | Inline primary key on `id` | `id uuid PRIMARY KEY DEFAULT gen_random_uuid()`. |
| Foreign key | Inline foreign key on `playlist_id` | References `playlists(id)`; deletes cascade when a playlist is deleted. |
| Foreign key | Inline foreign key on `user_id` | References `users(id)`; deletes cascade when a user is deleted. |
| Unique constraint | Inline unique pair | `UNIQUE(playlist_id, user_id)`, preventing a user from liking the same playlist more than once. |

### Indexes

No explicit `CREATE INDEX` statement was present for `playlist_likes`. PostgreSQL will create supporting indexes for the primary key and unique constraint, but explicit index names were not present in source.

### RLS Policies

RLS is enabled on `playlist_likes`.

| Policy name | Operation | Description |
|---|---|---|
| `Public read playlist likes` | `SELECT` | Anyone can read playlist like records. |
| `Authenticated users can like playlist` | `INSERT` | A like can be inserted only when the row's `user_id` matches the authenticated Supabase user ID. |
| `Users can unlike playlist` | `DELETE` | A like can be deleted only when the row's `user_id` matches the authenticated Supabase user ID. |

## RPC Functions

| Function | Description |
|---|---|
| `increment_playlist_likes(p_id uuid)` | Security-definer function that increments `playlists.likes_count` by 1 for the given playlist ID. |
| `decrement_playlist_likes(p_id uuid)` | Security-definer function that decrements `playlists.likes_count` for the given playlist ID but never below 0. |
