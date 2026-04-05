# Discover Feature - Playlist Screens Implementation Plan

## Context

The discover feature has two screens built (home + search) with mock data. The user needs to add playlist management: browsing playlists by genre tags, importing from Spotify, manually creating playlists (for non-Spotify users), and customizing before publishing. **SwapTunes does not play music** - playlists are curated recommendations with external links (Spotify, YouTube Music, Apple Music, etc.) where users actually listen.

---

## All Screens (7 total: 2 existing + 5 new + 1 bottom sheet)

| # | Screen | Status | Purpose |
|---|--------|--------|---------|
| 1 | **Discover Home** | existing | Genre chips, playlist cards, suggested users |
| 2 | **Search Screen** | existing | Search across users, playlists, creators |
| 3 | **Browse All Genres Screen** | **new** | Full page grid of all genres (from "See All") |
| 4 | **Genre Detail Screen** | **new** | Playlists filtered by one genre tag |
| 5 | **Spotify Import Screen** | **new** | Connect Spotify or pick a playlist to import |
| 6 | **Playlist Editor Screen** | **new** | Create / edit / customize playlist (shared) |
| 7 | **Playlist Detail Screen** | **new** | View playlist info + external links |
| - | **Add Playlist Bottom Sheet** | **new** | Modal with two options (not a full screen) |

---

## Navigation Map

```
DISCOVER HOME (existing)
  |
  ├─ "See All" on Browse by Genre ──> BROWSE ALL GENRES SCREEN (new)
  |                                      ├─ Tap a genre card ──> GENRE DETAIL SCREEN
  |
  ├─ Tap genre chip ────────────────> GENRE DETAIL SCREEN (new)
  |                                      └─ Tap playlist card ──> PLAYLIST DETAIL SCREEN
  |
  ├─ Tap "+" icon ──────────────────> ADD PLAYLIST BOTTOM SHEET (new)
  |                                      ├─ "Import from Spotify" ──> SPOTIFY IMPORT SCREEN
  |                                      └─ "Create Manually" ──────> PLAYLIST EDITOR SCREEN (create mode)
  |
  ├─ Tap playlist card ────────────> PLAYLIST DETAIL SCREEN (new)
  |                                      └─ Owner taps "Edit" ──> PLAYLIST EDITOR SCREEN (edit mode)
  |
  └─ Search icon ──────────────────> SEARCH SCREEN (existing)

SPOTIFY IMPORT SCREEN (new)
  ├─ Not connected ──> "Connect Spotify" button (reuse existing OAuth flow)
  └─ Connected ──────> Shows user's Spotify playlists
                         └─ Tap one ──> imports it ──> PLAYLIST EDITOR SCREEN (customize mode)
```

---

## Complete User Flows (step-by-step)

### Flow A: Browse Genres
1. User opens **Discover Home**
2. Sees "Browse by Genre" section with horizontal genre chips
3. **Option A1**: Taps a genre chip (e.g. "Dubstep") → goes to **Genre Detail Screen** showing playlists tagged with "Dubstep"
4. **Option A2**: Taps "See All" → goes to **Browse All Genres Screen** showing all genres in a beautiful grid layout
5. On Browse All Genres, taps a genre card → goes to **Genre Detail Screen** for that genre
6. On Genre Detail, taps a playlist card → goes to **Playlist Detail Screen**

### Flow B: Add Playlist via Spotify Import
1. User taps "+" icon on **Discover Home** app bar
2. **Add Playlist Bottom Sheet** appears with two options
3. User taps "Import from Spotify"
4. Goes to **Spotify Import Screen**
5. **If not connected**: Sees "Connect your Spotify" message + button → triggers OAuth → after connecting, screen refreshes to show playlists
6. **If connected**: Sees list of their Spotify playlists (with "Already imported" badges)
7. User taps one playlist to import
8. System imports it (name, cover, track count, spotify_url auto-filled)
9. Navigates to **Playlist Editor Screen** (customize mode) with imported data pre-filled
10. User can edit name, description, add more external links (YouTube Music, Apple Music, etc.), select genre tags, change cover image
11. User taps "Publish" → playlist is saved and shared on SwapTunes
12. Returns to **Discover Home**

### Flow C: Add Playlist Manually (no Spotify needed)
1. User taps "+" icon on **Discover Home** app bar
2. **Add Playlist Bottom Sheet** appears
3. User taps "Create Manually"
4. Goes to **Playlist Editor Screen** (create mode) with empty form
5. User fills in: name, description, cover image
6. User selects **source platform** (where the playlist lives: Spotify, YouTube Music, Apple Music, SoundCloud, Other)
7. User adds external links: paste the playlist URL(s) (at least one required)
8. User fills in **playlist blueprint**: genre tags, featured artists, mood/vibe tags
9. User taps "Publish" → playlist is created and shared on SwapTunes
10. Returns to **Discover Home**

### Flow D: View & Edit Playlist
1. User taps a playlist card anywhere (Discover Home, Genre Detail, Search results)
2. Goes to **Playlist Detail Screen** showing cover image, name, description, genre tags, external link buttons
3. If viewing own playlist: sees "Edit" button in app bar
4. Taps "Edit" → goes to **Playlist Editor Screen** (edit mode) with all fields pre-populated
5. Makes changes → taps "Save Changes"
6. Returns to **Playlist Detail Screen** with updated data

### Flow E: Listen to a Playlist (external)
1. User views **Playlist Detail Screen**
2. Sees external link buttons (only platforms with URLs show)
3. Taps "Open in Spotify" / "Open in YouTube Music" / etc.
4. Opens the external app or browser with the playlist URL

---

## Phase 1: Database Schema Changes

### 1A. Make `spotify_playlist_id` nullable (manual playlists won't have one)

```sql
ALTER TABLE playlists ALTER COLUMN spotify_playlist_id DROP NOT NULL;
-- Partial unique index: still unique when not null
DROP INDEX IF EXISTS playlists_spotify_playlist_id_key;
CREATE UNIQUE INDEX playlists_spotify_playlist_id_key
  ON playlists (spotify_playlist_id) WHERE spotify_playlist_id IS NOT NULL;
```

### 1B. Add source platform, external links, and metadata columns

```sql
-- Source platform badge (where the playlist is from)
ALTER TABLE playlists ADD COLUMN source_platform text NOT NULL DEFAULT 'other';
-- Values: 'spotify', 'youtube_music', 'apple_music', 'soundcloud', 'other'
-- Auto-set to 'spotify' on import, user selects on manual create

-- External platform links (following creator_profiles pattern, lines 36-40 in init_schema.sql)
ALTER TABLE playlists ADD COLUMN spotify_url text;
ALTER TABLE playlists ADD COLUMN youtube_music_url text;
ALTER TABLE playlists ADD COLUMN apple_music_url text;
ALTER TABLE playlists ADD COLUMN soundcloud_url text;

-- ═══ Playlist Blueprint Metadata (internal dataset for future recommendations) ═══

ALTER TABLE playlists ADD COLUMN artists text[] DEFAULT '{}';
-- Key artists in the playlist (e.g. ['Skrillex', 'Excision', 'Zeds Dead'])

ALTER TABLE playlists ADD COLUMN mood_tags text[] DEFAULT '{}';
-- Max 3 mood/vibe tags (e.g. ['energetic', 'dark', 'intense'])
-- Predefined options: energetic, chill, dark, upbeat, melancholic, heavy,
--   smooth, aggressive, dreamy, romantic, nostalgic, euphoric, raw, peaceful, hypnotic

ALTER TABLE playlists ADD COLUMN era text;
-- Decade/era of the music (e.g. '2020s', '2010s', '90s', 'mixed')

ALTER TABLE playlists ADD COLUMN energy_level text;
-- Energy intensity: 'low', 'medium', 'high'

ALTER TABLE playlists ADD COLUMN occasion_tags text[] DEFAULT '{}';
-- When to listen (e.g. ['workout', 'driving', 'party'])
-- Options: workout, study, party, driving, sleep, cooking, gaming, travel, meditation, hangout

ALTER TABLE playlists ADD COLUMN vocal_style text;
-- Vocal type: 'instrumental', 'vocal', 'mixed'

ALTER TABLE playlists ADD COLUMN language text DEFAULT 'english';
-- Primary language: 'english', 'spanish', 'korean', 'japanese', 'hindi', 'mixed', 'instrumental', 'other'

-- Full blueprint structure:
--   genre_tags      = what genre          (from existing column)
--   artists         = who's in it
--   mood_tags       = what vibe (max 3)
--   era             = what decade
--   energy_level    = how intense
--   occasion_tags   = when to listen
--   vocal_style     = vocal or instrumental
--   language        = what language

ALTER TABLE playlists ADD COLUMN updated_at timestamptz DEFAULT now();
```

This blueprint is **internal metadata stored in DB only** - NOT shown to users in the UI. It powers future features like:
- User taste matching ("you both share dubstep playlists with Skrillex")
- Recommendation engine ("based on your dark dubstep playlists, try these")
- Platform filtering ("show only YouTube Music playlists")

### 1C. Sample Blueprint Data (how it looks in the database)

**Example 1: Dubstep Spotify playlist**
```json
{
  "name": "Heavy Bass Drops 2026",
  "source_platform": "spotify",
  "genre_tags": ["dubstep", "bass", "electronic"],
  "artists": ["Skrillex", "Excision", "Zeds Dead", "Virtual Riot"],
  "mood_tags": ["energetic", "heavy", "dark"],
  "era": "2020s",
  "energy_level": "high",
  "occasion_tags": ["workout", "gaming", "party"],
  "vocal_style": "instrumental",
  "language": "instrumental",
  "spotify_url": "https://open.spotify.com/playlist/abc123",
  "track_count": 45
}
```

**Example 2: Chill Lo-fi YouTube Music playlist**
```json
{
  "name": "Late Night Study Vibes",
  "source_platform": "youtube_music",
  "genre_tags": ["lo-fi", "hip-hop", "ambient"],
  "artists": ["Nujabes", "J Dilla", "Tomppabeats", "idealism"],
  "mood_tags": ["chill", "peaceful", "dreamy"],
  "era": "2010s",
  "energy_level": "low",
  "occasion_tags": ["study", "sleep", "meditation"],
  "vocal_style": "instrumental",
  "language": "instrumental",
  "youtube_music_url": "https://music.youtube.com/playlist?list=xyz789",
  "track_count": 32
}
```

**Example 3: Pop/R&B Apple Music playlist**
```json
{
  "name": "Summer R&B Essentials",
  "source_platform": "apple_music",
  "genre_tags": ["r&b", "pop", "soul"],
  "artists": ["SZA", "Frank Ocean", "The Weeknd", "Daniel Caesar"],
  "mood_tags": ["smooth", "romantic", "upbeat"],
  "era": "2020s",
  "energy_level": "medium",
  "occasion_tags": ["driving", "hangout", "cooking"],
  "vocal_style": "vocal",
  "language": "english",
  "apple_music_url": "https://music.apple.com/playlist/pl.abc456",
  "track_count": 28
}
```

**Example 4: Rock SoundCloud playlist**
```json
{
  "name": "Underground Indie Rock Gems",
  "source_platform": "soundcloud",
  "genre_tags": ["indie-rock", "alternative", "garage-rock"],
  "artists": ["Black Midi", "Squid", "Dry Cleaning", "Shame"],
  "mood_tags": ["raw", "energetic", "aggressive"],
  "era": "2020s",
  "energy_level": "high",
  "occasion_tags": ["workout", "party"],
  "vocal_style": "vocal",
  "language": "english",
  "soundcloud_url": "https://soundcloud.com/user/sets/indie-rock-gems",
  "track_count": 20
}
```

**Example 5: K-Pop mixed platform playlist**
```json
{
  "name": "K-Pop Bangers",
  "source_platform": "spotify",
  "genre_tags": ["k-pop", "pop", "dance"],
  "artists": ["BLACKPINK", "BTS", "NewJeans", "Stray Kids"],
  "mood_tags": ["upbeat", "euphoric", "energetic"],
  "era": "2020s",
  "energy_level": "high",
  "occasion_tags": ["party", "workout", "driving"],
  "vocal_style": "vocal",
  "language": "korean",
  "spotify_url": "https://open.spotify.com/playlist/def456",
  "youtube_music_url": "https://music.youtube.com/playlist?list=kpop123",
  "track_count": 35
}
```

**Example 6: Classical/Ambient focus playlist**
```json
{
  "name": "Deep Focus Piano",
  "source_platform": "apple_music",
  "genre_tags": ["classical", "ambient", "piano"],
  "artists": ["Ludovico Einaudi", "Yiruma", "Nils Frahm", "Ólafur Arnalds"],
  "mood_tags": ["peaceful", "melancholic", "dreamy"],
  "era": "mixed",
  "energy_level": "low",
  "occasion_tags": ["study", "meditation", "sleep"],
  "vocal_style": "instrumental",
  "language": "instrumental",
  "apple_music_url": "https://music.apple.com/playlist/pl.piano789",
  "track_count": 40
}
```

**How blueprint gets populated:**
- **Spotify import**: `genre_tags` from Spotify's genre data if available, `artists` extracted from track listing via Spotify API, `mood_tags` left empty (user can add later or we auto-generate in future)
- **Manual create**: User fills in `genre_tags` in the editor (visible to user as "categorization"). `artists` and `mood_tags` are entered by user during creation as optional metadata fields (shown as simple chip inputs, labeled "Featured Artists" and "Vibe/Mood")
- **Future**: Could auto-analyze with AI to suggest mood_tags based on genre + artists

**Files to modify:**
- `backend/database/init_schema.sql` - update the playlists table definition for reference

---

## Phase 2: Backend API Changes

### 2A. New endpoint in discover feature

Add to `backend/src/features/discover/discover.routes.js`:

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `GET` | `/discover/genres` | requireAuth | Get all unique genre tags (from playlists + user_genres) |

In `discover.service.js`, add `getGenres()` - queries distinct genre tags from playlists table and combines with genres from user_genres table. Returns sorted unique list.

### 2B. New endpoints in playlists feature

Add to `backend/src/features/playlists/playlists.routes.js`:

| Method | Path | Auth | Purpose |
|--------|------|------|---------|
| `POST` | `/playlists/create` | requireAuth | Create manual playlist |
| `PATCH` | `/playlists/:playlistId` | requireAuth | Update/customize playlist |
| `GET` | `/playlists/:playlistId` | public | Get single playlist detail |

### 2C. New service methods in `backend/src/features/playlists/playlists.service.js`

- **`createPlaylist(userId, data)`** - Insert into playlists with `spotify_playlist_id: null`, validate required `name` and `source_platform`
- **`updatePlaylist(userId, playlistId, data)`** - Update all editable fields: name, description, cover_image_url, source_platform, is_public, external links (spotify_url, youtube_music_url, apple_music_url, soundcloud_url), and blueprint metadata (genre_tags, artists, mood_tags, era, energy_level, occasion_tags, vocal_style, language). Ownership check via `.match({ id, user_id })`
- **`getPlaylistById(playlistId)`** - Select playlist with user join (username, avatar_url, full_name)

### 2D. New controller methods in `backend/src/features/playlists/playlists.controller.js`

- **`createPlaylist`** - Validate body (name required), call service
- **`updatePlaylist`** - Validate body, call service with `req.user.id` + `req.params.playlistId`
- **`getPlaylist`** - Call service, return playlist with owner info

### 2E. Modify Spotify import to auto-populate spotify_url and source_platform

In `playlists.service.js` `importPlaylists()`, add fields:
```js
spotify_url: `https://open.spotify.com/playlist/${item.id}`,
source_platform: 'spotify'
```

**Files to modify:**
- `backend/src/features/discover/discover.routes.js`
- `backend/src/features/discover/discover.service.js`
- `backend/src/features/discover/discover.controller.js`
- `backend/src/features/playlists/playlists.routes.js`
- `backend/src/features/playlists/playlists.service.js`
- `backend/src/features/playlists/playlists.controller.js`

---

## Phase 3: Frontend Data Layer

The discover feature currently has NO data layer - only presentation with mock data. Create it following the feed/profile pattern.

### 3A. Models (`frontend/lib/features/discover/data/models/`)

**`playlist_model.dart`**
```
Fields:
  // Core
  id, userId, spotifyPlaylistId?, name, description?, coverImageUrl?,
  trackCount, isPublic, sourcePlatform, createdAt, updatedAt,

  // External links
  spotifyUrl?, youtubeMusicUrl?, appleMusicUrl?, soundcloudUrl?,

  // Blueprint metadata (internal)
  genreTags, artists, moodTags (max 3), era?, energyLevel?,
  occasionTags, vocalStyle?, language?,

  // User join data
  ownerUsername, ownerFullName, ownerAvatarUrl?

Methods: fromJson(), toJson(), copyWith()
```

**`spotify_playlist_model.dart`**
```
Fields: id, name, trackCount, isPublic, coverImageUrl?, isImported
Methods: fromJson()
```

### 3B. Datasource (`frontend/lib/features/discover/data/datasources/discover_remote_datasource.dart`)

Following pattern from `frontend/lib/features/feed/data/datasources/feed_remote_datasource.dart`:

```dart
class DiscoverRemoteDatasource {
  // Discover
  Future<List<PlaylistModel>> getDiscoverPlaylists({String? genre, int page, int limit});
  Future<Map<String, dynamic>> search(String query, {String type});

  // Playlist CRUD
  Future<PlaylistModel> createPlaylist(Map<String, dynamic> data);
  Future<PlaylistModel> updatePlaylist(String id, Map<String, dynamic> data);
  Future<PlaylistModel> getPlaylist(String id);
  Future<void> deletePlaylist(String id);

  // Spotify
  Future<List<SpotifyPlaylistModel>> getAvailableSpotifyPlaylists();
  Future<PlaylistModel> importSpotifyPlaylist(String playlistId); // single playlist
}
```

### 3C. Repository (`frontend/lib/features/discover/data/repositories/discover_repository.dart`)

Direct delegation to datasource (no Isar cache initially - can add later).

### 3D. API Constants additions (`frontend/lib/core/constants/api_constants.dart`)

```dart
// Discover
static const String discoverPlaylists = '/discover/playlists';
static const String discoverGenres = '/discover/genres';

// Playlists (additions)
static const String playlistCreate = '/playlists/create';
static String playlistDetail(String id) => '/playlists/$id';
static String playlistUpdate(String id) => '/playlists/$id';
static const String spotifyAvailable = '/playlists/spotify/available';
static const String playlistImport = '/playlists/import';
static String userPlaylists(String userId) => '/playlists/user/$userId';
```

**New files:**
- `frontend/lib/features/discover/data/models/playlist_model.dart`
- `frontend/lib/features/discover/data/models/spotify_playlist_model.dart`
- `frontend/lib/features/discover/data/datasources/discover_remote_datasource.dart`
- `frontend/lib/features/discover/data/repositories/discover_repository.dart`

**Files to modify:**
- `frontend/lib/core/constants/api_constants.dart`

---

## Phase 4: New Screens + ViewModels

### 4A. Browse All Genres Screen

**`browse_genres_screen.dart`** - Beautiful full-page grid of all music genres
- AppBar with title "Browse Genres"
- Grid layout (2 columns) of genre cards - each card is visually styled (gradient/color background, genre name, icon or illustration)
- Tapping a genre card navigates to **Genre Detail Screen**
- Data from `GET /discover/genres`

**`browse_genres_viewmodel.dart`**
- Fetches all genres from API
- State: `isLoading`, `error`, `genres` (list of strings)

**Design idea**: Each genre card could have a unique accent color (mapped from genre name) to make the grid visually distinctive. Similar to Spotify's "Browse" page aesthetic but with SwapTunes dark theme.

### 4B. Genre Detail Screen

**`genre_detail_screen.dart`** - Full screen showing playlists for a specific genre tag
- AppBar with genre name as title (e.g. "Dubstep")
- Vertical list/grid of `PlaylistCard` widgets
- Pagination (load more on scroll)
- Calls `GET /discover/playlists?genre=<tag>`

**`genre_detail_viewmodel.dart`**
- Takes genre string, fetches filtered playlists
- Pagination: `loadPlaylists()`, `loadMore()`, `hasMore`
- State: `isLoading`, `error`, `playlists`

### 4C. Add Playlist Bottom Sheet

**`add_playlist_sheet.dart`** - Modal bottom sheet (not a screen)
- Two tappable card options: "Import from Spotify" and "Create Manually"
- Checks `user.spotifyConnected` to decide navigation for Spotify option
- Shown from `_buildIconAction(AppAssets.icon.add, ...)` in discover_screen.dart

### 4D. Spotify Import Screen

**`spotify_import_screen.dart`**
- If not connected: illustration + "Connect Spotify" button (triggers existing `AuthViewmodel.connectSpotify()`)
- If connected: list of user's Spotify playlists via `GET /playlists/spotify/available`
- Each item shows: cover image, name, track count, "Already imported" badge if applicable
- Tap one playlist → import it → navigate to Playlist Editor for customization

**`spotify_import_viewmodel.dart`**
- Fetches available playlists
- `importPlaylist(spotifyId)` - imports single playlist, returns created PlaylistModel
- State: `isLoading`, `playlists`, `isImporting`

### 4E. Playlist Editor Screen (dual-purpose: create + edit)

**`playlist_editor_screen.dart`**
- If `playlist == null`: create mode (empty form)
- If `playlist != null`: edit mode (pre-populated fields)
- Form sections:
  1. **Cover & Basic Info**
     - Cover image (tap to pick, upload via `/uploads/image`)
     - Name (TextFormField, required)
     - Description (TextFormField, multiline)
  2. **Source Platform** (required)
     - Platform selector chips: Spotify, YouTube Music, Apple Music, SoundCloud, Other
     - Auto-set to "Spotify" on import
     - Shows a platform badge/icon on the playlist
  3. **External Links**
     - Spotify URL (auto-filled for imports)
     - YouTube Music URL
     - Apple Music URL
     - SoundCloud URL
     - At least one link required
  4. **Categorization** (feeds into internal blueprint metadata in DB)
     - Genre tags (chip selector from predefined list + custom input)
     - Featured Artists (chip input - type artist names, e.g. "Skrillex", "Excision")
     - Mood/Vibe (chip selector, **max 3**: energetic, chill, dark, upbeat, melancholic, heavy, smooth, aggressive, dreamy, romantic, nostalgic, euphoric, raw, peaceful, hypnotic)
     - Era (dropdown: 2020s, 2010s, 2000s, 90s, 80s, mixed)
     - Energy Level (selector: Low, Medium, High)
     - Occasion (chip selector: workout, study, party, driving, sleep, cooking, gaming, travel, meditation, hangout)
     - Vocal Style (selector: Instrumental, Vocal, Mixed)
     - Language (dropdown: English, Spanish, Korean, Japanese, Hindi, Mixed, Instrumental, Other)
  5. **Visibility**
     - Public/Private toggle
- "Publish" / "Save Changes" button

**`playlist_editor_viewmodel.dart`**
- Form state management for all fields
- `pickCoverImage()` + `uploadCoverImage()`
- `setSourcePlatform(platform)`
- `addGenreTag(tag)` / `removeGenreTag(tag)`
- `addArtist(name)` / `removeArtist(name)`
- `addMoodTag(tag)` / `removeMoodTag(tag)` (max 3 enforced)
- `setEra(era)` / `setEnergyLevel(level)` / `setVocalStyle(style)` / `setLanguage(lang)`
- `addOccasionTag(tag)` / `removeOccasionTag(tag)`
- `savePlaylist()` - calls create or update based on mode
- Validation: name required, source platform required, at least one external link required

### 4F. Playlist Detail Screen

**`playlist_detail_screen.dart`**
- Large cover image at top with **source platform badge** overlay (e.g. Spotify logo badge)
- Playlist name, description
- Owner info row (avatar + username)
- Genre tag chips (visible to users as categorization)
- External link buttons (Spotify, YouTube Music, etc. - only show if URL exists)
- Track count info
- If owner: Edit + Delete actions in app bar
- Note: artists + mood_tags are NOT displayed here - they're internal blueprint data in the DB only

**`playlist_detail_viewmodel.dart`**
- Fetches single playlist via `GET /playlists/:id`
- `deletePlaylist()` with confirmation
- State: `playlist`, `isLoading`, `isOwner`

**New files:**
- `frontend/lib/features/discover/presentation/screens/browse_genres_screen.dart`
- `frontend/lib/features/discover/presentation/screens/genre_detail_screen.dart`
- `frontend/lib/features/discover/presentation/screens/spotify_import_screen.dart`
- `frontend/lib/features/discover/presentation/screens/playlist_editor_screen.dart`
- `frontend/lib/features/discover/presentation/screens/playlist_detail_screen.dart`
- `frontend/lib/features/discover/presentation/viewmodels/browse_genres_viewmodel.dart`
- `frontend/lib/features/discover/presentation/viewmodels/genre_detail_viewmodel.dart`
- `frontend/lib/features/discover/presentation/viewmodels/spotify_import_viewmodel.dart`
- `frontend/lib/features/discover/presentation/viewmodels/playlist_editor_viewmodel.dart`
- `frontend/lib/features/discover/presentation/viewmodels/playlist_detail_viewmodel.dart`
- `frontend/lib/features/discover/presentation/widgets/add_playlist_sheet.dart`
- `frontend/lib/features/discover/presentation/widgets/external_link_button.dart`
- `frontend/lib/features/discover/presentation/widgets/genre_card.dart`

---

## Phase 5: Wire Existing Screens

### 5A. Modify `discover_screen.dart`
- Wire "+" icon (`AppAssets.icon.add`) to show `AddPlaylistSheet`
- Wire `GenreChip` taps to navigate to `GenreDetailScreen`
- Wire `PlaylistCard` taps to navigate to `PlaylistDetailScreen`
- Wire "See All" on Browse by Genre section to navigate to `BrowseGenresScreen`

### 5B. Modify `discover_viewmodel.dart`
- Replace mock data with real API calls via `DiscoverRepository`
- Inject repository via constructor

### 5C. Modify `genre_chip.dart`
- Add `onTap` callback parameter

### 5D. Modify `playlist_card.dart`
- Add `onTap` callback parameter
- Add `playlistId` parameter for navigation

### 5E. Register providers
- Wire `DiscoverRepository` + `DiscoverRemoteDatasource` in dependency injection (`main.dart` or provider setup)

**Files to modify:**
- `frontend/lib/features/discover/presentation/screens/discover_screen.dart`
- `frontend/lib/features/discover/presentation/viewmodels/discover_viewmodel.dart`
- `frontend/lib/features/discover/presentation/widgets/genre_chip.dart`
- `frontend/lib/features/discover/presentation/widgets/playlist_card.dart`
- `frontend/lib/main.dart` (provider registration)

---

## Implementation Order

1. **Database migrations** (Phase 1) - nullable spotify_playlist_id + external URL columns
2. **Backend endpoints** (Phase 2) - genres endpoint + create, update, get-single playlist
3. **Frontend data layer** (Phase 3) - models, datasource, repository, API constants
4. **Browse All Genres Screen** (Phase 4A) - beautiful genre grid, proves data layer works
5. **Genre Detail Screen** (Phase 4B) - playlists filtered by genre
6. **Playlist Editor Screen** (Phase 4E) - core screen used by both flows
7. **Add Playlist Bottom Sheet** (Phase 4C) - entry point
8. **Spotify Import Screen** (Phase 4D) - needs editor to exist first
9. **Playlist Detail Screen** (Phase 4F) - view + navigation from cards
10. **Wire existing screens** (Phase 5) - replace mocks, add navigation

---

## Verification

1. **Manual create flow**: Discover Home → "+" → "Create Manually" → fill form with name + genre tags + YouTube Music link → Publish → verify in DB
2. **Spotify import flow**: Discover Home → "+" → "Import from Spotify" → select a playlist → customize in editor (spotify_url auto-filled) → Publish
3. **Genre browsing (chip)**: Discover Home → tap "Dubstep" chip → see filtered playlists → tap one → see detail with external links
6. **Genre browsing (see all)**: Discover Home → "See All" on Browse by Genre → see beautiful grid of all genres → tap one → see filtered playlists
4. **Edit flow**: Playlist Detail (own playlist) → Edit → change description → Save → verify updated
5. **Non-Spotify user**: "+" → "Import from Spotify" → sees "Connect Spotify" prompt → can go back and use "Create Manually" instead

---

## File Summary

**New files (18):**
- Frontend models: 2
- Frontend datasource + repository: 2
- Frontend screens: 5 (browse genres, genre detail, spotify import, playlist editor, playlist detail)
- Frontend viewmodels: 5 (browse genres, genre detail, spotify import, playlist editor, playlist detail)
- Frontend widgets: 3 (add playlist sheet, external link button, genre card)
- SQL migration: 1

**Modified files (11):**
- `backend/database/init_schema.sql`
- `backend/src/features/discover/discover.routes.js`
- `backend/src/features/discover/discover.service.js`
- `backend/src/features/discover/discover.controller.js`
- `backend/src/features/playlists/playlists.routes.js`
- `backend/src/features/playlists/playlists.service.js`
- `backend/src/features/playlists/playlists.controller.js`
- `frontend/lib/core/constants/api_constants.dart`
- `frontend/lib/features/discover/presentation/screens/discover_screen.dart`
- `frontend/lib/features/discover/presentation/viewmodels/discover_viewmodel.dart`
- `frontend/lib/features/discover/presentation/widgets/genre_chip.dart`
- `frontend/lib/features/discover/presentation/widgets/playlist_card.dart`
