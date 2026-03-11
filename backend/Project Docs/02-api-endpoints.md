# SwapTunes — REST API Endpoints
> **Base URL:** `/api/v1`  
> **Backend:** Node.js + Express  
> **Auth:** Supabase JWT — pass as `Authorization: Bearer <token>` header  
> **Format:** All requests/responses are `application/json`

---

## Auth Levels
| Badge | Meaning |
|-------|---------|
| `PUBLIC` | No authentication required |
| `AUTH` | Valid Supabase JWT required |
| `AUTH · CREATOR` | Must be authenticated + `user_type = 'creator'` |
| `AUTH · OWNER` | Must be the owner of the resource |
| `AUTH · SPOTIFY` | Must have Spotify connected |

---

## Route Groups

```
/api/v1/auth           → Authentication & onboarding
/api/v1/users          → User profiles & social actions
/api/v1/creator        → Creator mode setup & profile
/api/v1/posts          → Feed posts, likes, comments, reports
/api/v1/discover       → Discover page, search
/api/v1/playlists      → Spotify playlist import
/api/v1/collabs        → Collaboration marketplace
/api/v1/conversations  → Messaging (REST bootstrap)
/api/v1/notifications  → Notifications
```

---

## 1. Authentication & Onboarding
> Supabase Auth handles Google OAuth, Spotify OAuth, and Magic Link sign-in directly.  
> These endpoints handle post-auth profile setup.

---

### `POST /auth/profile/setup`
**Auth:** `AUTH`  
Complete profile after first-time sign-in (new user onboarding).

**Request Body:**
```json
{
  "full_name": "Dizzpy Sanchez",
  "username": "dizzpy",
  "bio": "Eclectic beats from the underground.",
  "genres": ["Dubstep", "Techno", "Trap"],
  "avatar_url": "https://..."
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `full_name` | string | ✅ | |
| `username` | string | ✅ | Unique, no @ prefix |
| `bio` | string | ❌ | |
| `genres` | string[] | ✅ | Min 3 items |
| `avatar_url` | string | ❌ | |

**Response `200`:**
```json
{ "user": { ...UserObject } }
```

---

### `POST /auth/spotify/connect`
**Auth:** `AUTH`  
Store Spotify OAuth tokens after user connects Spotify.

**Request Body:**
```json
{
  "spotify_access_token": "...",
  "spotify_refresh_token": "..."
}
```

**Response `200`:**
```json
{ "spotify_connected": true }
```

---

## 2. Users & Profiles

---

### `GET /users/me`
**Auth:** `AUTH`  
Get current user's full profile including genres and creator profile if applicable.

**Response `200`:**
```json
{
  "user": {
    "id": "uuid",
    "username": "dizzpy",
    "full_name": "Dizzpy Sanchez",
    "bio": "...",
    "avatar_url": "...",
    "user_type": "creator",
    "is_verified": true,
    "spotify_connected": true,
    "genres": ["Dubstep", "Techno"],
    "creator_profile": { ...CreatorProfileObject },
    "stats": {
      "followers": 234000,
      "following": 634000,
      "posts": 23,
      "playlists": 12,
      "collabs": 8
    }
  }
}
```

---

### `PATCH /users/me`
**Auth:** `AUTH`  
Edit own profile. All fields optional.

**Request Body:**
```json
{
  "full_name": "...",
  "bio": "...",
  "avatar_url": "...",
  "genres": ["Jazz", "Rock"]
}
```

**Response `200`:**
```json
{ "user": { ...UpdatedUserObject } }
```

---

### `GET /users/:username`
**Auth:** `PUBLIC`  
Get public profile by username.

**Response `200`:**
```json
{
  "user": {
    "id": "uuid",
    "username": "dizzpy",
    "full_name": "Dizzpy Sanchez",
    "avatar_url": "...",
    "bio": "...",
    "user_type": "creator",
    "is_verified": true,
    "genres": ["Dubstep"],
    "creator_profile": { ...or null },
    "stats": { "followers": 234000, "following": 634000, "posts": 23 },
    "is_following": false
  }
}
```

---

### `POST /users/:userId/follow`
**Auth:** `AUTH`  
Follow a user.

**Response `200`:**
```json
{ "followed": true, "followers_count": 234001 }
```

**Error `409`:** Already following.

---

### `DELETE /users/:userId/follow`
**Auth:** `AUTH`  
Unfollow a user.

**Response `200`:**
```json
{ "unfollowed": true, "followers_count": 234000 }
```

---

### `GET /users/:userId/followers`
**Auth:** `PUBLIC`  
Get paginated followers list.

**Query Params:**
| Param | Type | Default |
|-------|------|---------|
| `page` | int | 1 |
| `limit` | int | 20 |

**Response `200`:**
```json
{
  "followers": [ ...UserPreview[] ],
  "total": 234000,
  "page": 1
}
```

---

### `GET /users/:userId/following`
**Auth:** `PUBLIC`  
Get paginated following list.

**Query Params:** same as `/followers`

---

## 3. Creator Setup

---

### `POST /creator/setup`
**Auth:** `AUTH`  
Switch user to creator mode and save creator profile. Sets `users.user_type = 'creator'`.

**Request Body:**
```json
{
  "role_title": "Music Producer",
  "location": "Homagama, Sri Lanka",
  "specializations": ["Hip-Hop", "Electronic", "Jazz"],
  "soundcloud_url": "https://soundcloud.com/dizzpy",
  "youtube_url": "https://youtube.com/dizzpy",
  "spotify_artist_url": "https://spotify.com/dizzpy",
  "apple_music_url": "https://music.apple.com/dizzpy",
  "portfolio_url": "https://dizzpy.com"
}
```

| Field | Type | Required |
|-------|------|----------|
| `role_title` | string | ✅ |
| `location` | string | ❌ |
| `specializations` | string[] | ✅ |
| `soundcloud_url` | string | ❌ |
| `youtube_url` | string | ❌ |
| `spotify_artist_url` | string | ❌ |
| `apple_music_url` | string | ❌ |
| `portfolio_url` | string | ❌ |

**Response `201`:**
```json
{
  "creator_profile": { ...CreatorProfileObject },
  "user_type": "creator"
}
```

---

### `PATCH /creator/profile`
**Auth:** `AUTH · CREATOR`  
Update creator profile. All fields optional.

**Request Body:** same fields as setup, all optional.

**Response `200`:**
```json
{ "creator_profile": { ...UpdatedCreatorProfileObject } }
```

---

## 4. Posts & Feed

---

### `GET /posts/feed`
**Auth:** `AUTH`  
Get paginated home feed. Returns posts from followed users + algorithmically suggested posts. Excludes posts hidden by the current user.

**Query Params:**
| Param | Type | Notes |
|-------|------|-------|
| `cursor` | string | Pagination cursor (created_at of last item) |
| `limit` | int | Default 20 |

**Response `200`:**
```json
{
  "posts": [
    {
      "id": "uuid",
      "content": "...",
      "image_url": "...",
      "likes_count": 345000,
      "comments_count": 50000,
      "is_liked": true,
      "created_at": "...",
      "user": { "id": "uuid", "username": "honeymoon", "avatar_url": "...", "is_verified": true }
    }
  ],
  "next_cursor": "2024-01-01T00:00:00Z"
}
```

---

### `POST /posts`
**Auth:** `AUTH`  
Create a new post.

**Request Body:**
```json
{
  "content": "Inspirational designs, illustrations...",
  "image_url": "https://..."
}
```

| Field | Type | Required |
|-------|------|----------|
| `content` | string | ✅ |
| `image_url` | string | ❌ |

**Response `201`:**
```json
{ "post": { ...PostObject } }
```

---

### `DELETE /posts/:postId`
**Auth:** `AUTH · OWNER`  
Delete own post.

**Response `200`:**
```json
{ "deleted": true }
```

---

### `POST /posts/:postId/like`
**Auth:** `AUTH`  
Like a post. Triggers `like` notification to post owner.

**Response `200`:**
```json
{ "liked": true, "likes_count": 345001 }
```

---

### `DELETE /posts/:postId/like`
**Auth:** `AUTH`  
Unlike a post.

**Response `200`:**
```json
{ "liked": false, "likes_count": 345000 }
```

---

### `GET /posts/:postId/comments`
**Auth:** `AUTH`  
Get all comments on a post.

**Query Params:**
| Param | Type | Default |
|-------|------|---------|
| `limit` | int | 30 |
| `cursor` | string | — |

**Response `200`:**
```json
{
  "comments": [
    {
      "id": "uuid",
      "content": "This is amazing!",
      "created_at": "...",
      "user": { "id": "uuid", "username": "lanarey", "avatar_url": "..." }
    }
  ]
}
```

---

### `POST /posts/:postId/comments`
**Auth:** `AUTH`  
Add a comment. Triggers `comment` notification to post owner.

**Request Body:**
```json
{ "content": "This is fire!" }
```

**Response `201`:**
```json
{ "comment": { ...CommentObject } }
```

---

### `POST /posts/:postId/report`
**Auth:** `AUTH`  
Report a post for review.

**Request Body:**
```json
{ "reason": "Spam" }
```

**Response `201`:**
```json
{ "reported": true }
```

---

### `POST /posts/:postId/hide`
**Auth:** `AUTH`  
Hide a post from own feed only. Does not affect other users.

**Response `200`:**
```json
{ "hidden": true }
```

---

## 5. Discover & Search

---

### `GET /discover/playlists`
**Auth:** `AUTH`  
Get featured and suggested playlists for the Discover page.

**Query Params:**
| Param | Type | Notes |
|-------|------|-------|
| `genre` | string | Filter by genre |
| `limit` | int | Default 20 |

**Response `200`:**
```json
{
  "playlists": [ ...PlaylistObject[] ],
  "genres": ["Hip-Hop", "Jazz", "Rock", "Classical", "Reggae"]
}
```

---

### `GET /discover/suggested-users`
**Auth:** `AUTH`  
Get suggested users/creators to follow (based on shared genres).

**Response `200`:**
```json
{
  "users": [
    {
      "id": "uuid",
      "username": "skrillex",
      "full_name": "Skrillex",
      "avatar_url": "...",
      "role_title": "Dubstep Anthems",
      "is_following": false
    }
  ]
}
```

---

### `GET /discover/search`
**Auth:** `AUTH`  
Search across all content types.

**Query Params:**
| Param | Type | Required | Notes |
|-------|------|----------|-------|
| `q` | string | ✅ | Search query |
| `type` | string | ❌ | `all` \| `users` \| `playlists` \| `creators` \| `albums` — default `all` |
| `limit` | int | ❌ | Default 20 |
| `cursor` | string | ❌ | Pagination |

**Response `200`:**
```json
{
  "results": {
    "users": [ ...UserPreview[] ],
    "playlists": [ ...PlaylistObject[] ],
    "creators": [ ...CreatorPreview[] ]
  }
}
```

---

## 6. Playlists (Spotify Import)

---

### `GET /playlists/spotify/available`
**Auth:** `AUTH · SPOTIFY`  
Fetch user's Spotify playlists directly from Spotify API (via stored tokens).

**Response `200`:**
```json
{
  "playlists": [
    {
      "spotify_playlist_id": "37i9dQZF1...",
      "name": "All the Stars",
      "track_count": 31,
      "is_public": true,
      "cover_image_url": "https://..."
    }
  ]
}
```

---

### `POST /playlists/import`
**Auth:** `AUTH · SPOTIFY`  
Import selected Spotify playlists into SwapTunes DB.

**Request Body:**
```json
{
  "spotify_playlist_ids": ["37i9dQZF1...", "2YRe7HZKnXi..."]
}
```

**Response `201`:**
```json
{
  "imported": [ ...PlaylistObject[] ],
  "count": 2
}
```

---

### `GET /playlists/user/:userId`
**Auth:** `PUBLIC`  
Get a user's imported playlists (public ones only for other users).

**Response `200`:**
```json
{ "playlists": [ ...PlaylistObject[] ] }
```

---

### `DELETE /playlists/:playlistId`
**Auth:** `AUTH · OWNER`  
Remove an imported playlist from SwapTunes profile.

**Response `200`:**
```json
{ "deleted": true }
```

---

## 7. Collaborations (Creator Only)

---

### `GET /collabs`
**Auth:** `AUTH · CREATOR`  
Get all open collaboration posts with optional filters.

**Query Params:**
| Param | Type | Notes |
|-------|------|-------|
| `role` | string | Filter: `Vocalist`, `Producer`, `Mixing`, `Mastering`, `Songwriter`, `Instrumentalist` |
| `genre` | string | Filter by genre |
| `payment_type` | string | `paid` \| `revenue_share` \| `free` |
| `cursor` | string | Pagination cursor |
| `limit` | int | Default 20 |

**Response `200`:**
```json
{
  "collabs": [
    {
      "id": "uuid",
      "title": "Need Mixing & Mastering",
      "description": "...",
      "looking_for": ["Mixing", "Mastering"],
      "genre_style": ["R&B", "Soul"],
      "payment_type": "paid",
      "status": "open",
      "created_at": "...",
      "creator": { "id": "uuid", "username": "melodymarks", "role_title": "Song Writer" }
    }
  ],
  "next_cursor": "..."
}
```

---

### `GET /collabs/me`
**Auth:** `AUTH · CREATOR`  
Get all collaboration posts created by current user (manage view).

**Response `200`:**
```json
{ "collabs": [ ...CollabObject[] ] }
```

---

### `GET /collabs/:collabId`
**Auth:** `AUTH · CREATOR`  
Get single collab post details.

**Response `200`:**
```json
{
  "collab": { ...FullCollabObject },
  "creator": { ...CreatorPublicProfile }
}
```

---

### `POST /collabs`
**Auth:** `AUTH · CREATOR`  
Create a new collaboration post.

**Request Body:**
```json
{
  "title": "Need Mixing & Mastering",
  "description": "Looking for an experienced mixing engineer for my R&B EP.",
  "looking_for": ["Mixing", "Mastering"],
  "genre_style": ["R&B", "Soul"],
  "payment_type": "paid"
}
```

| Field | Type | Required |
|-------|------|----------|
| `title` | string | ✅ |
| `description` | string | ✅ |
| `looking_for` | string[] | ✅ |
| `genre_style` | string[] | ❌ |
| `payment_type` | enum | ✅ |

**Response `201`:**
```json
{ "collab": { ...CollabObject } }
```

---

### `PATCH /collabs/:collabId`
**Auth:** `AUTH · CREATOR · OWNER`  
Edit own collab post. All fields optional.

**Request Body:**
```json
{
  "title": "Updated title",
  "description": "Updated description",
  "status": "closed"
}
```

**Response `200`:**
```json
{ "collab": { ...UpdatedCollabObject } }
```

---

### `DELETE /collabs/:collabId`
**Auth:** `AUTH · CREATOR · OWNER`  
Delete own collab post.

**Response `200`:**
```json
{ "deleted": true }
```

---

## 8. Messaging (REST Bootstrap + Supabase Realtime)

> REST endpoints are used to initialize conversations and load history.  
> Live message delivery uses **Supabase Realtime** (see `05-realtime-channels.md`).

---

### `GET /conversations`
**Auth:** `AUTH`  
Get all conversations for the current user, sorted by most recent message.

**Response `200`:**
```json
{
  "conversations": [
    {
      "id": "uuid",
      "other_user": { "id": "uuid", "username": "dustin", "avatar_url": "...", "is_online": true },
      "last_message": { "content": "Gotta listen to this new track!", "created_at": "..." },
      "unread_count": 3,
      "collab_id": null
    }
  ]
}
```

---

### `POST /conversations`
**Auth:** `AUTH`  
Start a new conversation with a user, or return the existing one (idempotent). Optionally link to a collab post.

**Request Body:**
```json
{
  "user_id": "uuid",
  "collab_id": "uuid"
}
```

| Field | Type | Required |
|-------|------|----------|
| `user_id` | uuid | ✅ |
| `collab_id` | uuid | ❌ |

**Response `200` (existing) or `201` (new):**
```json
{ "conversation": { ...ConversationObject } }
```

---

### `POST /conversations/:convId/messages`
**Auth:** `AUTH`  
Send a message. Inserts into DB → triggers Supabase Realtime to recipient.

**Request Body:**
```json
{ "content": "Are we still going to the Zodiac meeting tomorrow?" }
```

**Response `201`:**
```json
{ "message": { ...MessageObject } }
```

---

### `GET /conversations/:convId/messages`
**Auth:** `AUTH`  
Load message history for a conversation (initial page load). After this, new messages arrive via Realtime.

**Query Params:**
| Param | Type | Notes |
|-------|------|-------|
| `limit` | int | Default 50 |
| `before` | timestamptz | For pagination (load older messages) |

**Response `200`:**
```json
{
  "messages": [
    {
      "id": "uuid",
      "content": "I am so ready. I think they do a new",
      "sender_id": "uuid",
      "is_read": true,
      "created_at": "..."
    }
  ]
}
```

---

### `PATCH /conversations/:convId/read`
**Auth:** `AUTH`  
Mark all unread messages in a conversation as read.

**Response `200`:**
```json
{ "updated_count": 3 }
```

---

## 9. Notifications

---

### `GET /notifications`
**Auth:** `AUTH`  
Get all notifications for current user.

**Query Params:**
| Param | Type | Default |
|-------|------|---------|
| `unread_only` | boolean | false |
| `limit` | int | 30 |

**Response `200`:**
```json
{
  "notifications": [
    {
      "id": "uuid",
      "type": "like",
      "is_read": false,
      "created_at": "...",
      "actor": { "id": "uuid", "username": "skrillex", "avatar_url": "..." },
      "reference_id": "post-uuid"
    }
  ],
  "unread_count": 5
}
```

---

### `PATCH /notifications/read-all`
**Auth:** `AUTH`  
Mark all notifications as read.

**Response `200`:**
```json
{ "updated_count": 5 }
```

---

### `PATCH /notifications/:notifId/read`
**Auth:** `AUTH`  
Mark single notification as read.

**Response `200`:**
```json
{ "updated": true }
```

---

## Error Response Format

All errors follow this shape:
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "You must be logged in to perform this action."
  }
}
```

| HTTP Code | Code | When |
|-----------|------|------|
| `400` | `BAD_REQUEST` | Missing/invalid fields |
| `401` | `UNAUTHORIZED` | No/invalid JWT |
| `403` | `FORBIDDEN` | Auth but not allowed (e.g. not creator, not owner) |
| `404` | `NOT_FOUND` | Resource doesn't exist |
| `409` | `CONFLICT` | Duplicate (e.g. already following, username taken) |
| `500` | `SERVER_ERROR` | Internal server error |
