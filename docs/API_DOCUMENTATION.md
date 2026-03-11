# SwapTunes Backend — Full API Documentation

> **Base URL:** `https://<your-domain>/api/v1`  
> **Content-Type:** `application/json` for all requests and responses.  
> **Authentication:** Supabase JWT — pass the token in the `Authorization` header.

---

## Table of Contents

1. [Authentication & Headers](#1-authentication--headers)
2. [Standard Response Format](#2-standard-response-format)
3. [Error Format](#3-error-format)
4. [Pagination](#4-pagination)
5. [Health](#5-health)
6. [Auth](#6-auth)
7. [Users](#7-users)
8. [Creator](#8-creator)
9. [Posts](#9-posts)
10. [Discover](#10-discover)
11. [Playlists](#11-playlists)
12. [Collabs](#12-collabs)
13. [Conversations (Messaging)](#13-conversations-messaging)
14. [Notifications](#14-notifications)

---

## 1. Authentication & Headers

| Header          | Value                   | When Required                        |
| --------------- | ----------------------- | ------------------------------------ |
| `Authorization` | `Bearer <supabase_jwt>` | All protected routes (`requireAuth`) |
| `Content-Type`  | `application/json`      | All POST / PATCH / PUT requests      |

There are two auth middleware levels used across this backend:

- **`requireJwtAuth`** — Verifies the Supabase JWT only. Used for the profile setup endpoint where the user hasn't been inserted into `public.users` yet. Auth data is available on `req.authData.user`.
- **`requireAuth`** — Verifies the JWT **and** ensures the user exists in `public.users`. The full user object is available on `req.user`.

---

## 2. Standard Response Format

All successful responses return data directly (no wrapper envelope):

```json
// HTTP 200
{ ...data }

// HTTP 201
{ ...created_resource }
```

Simple success operations return:

```json
{ "success": true }
```

---

## 3. Error Format

All errors follow a consistent structure:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable error message"
  }
}
```

### Common HTTP Status Codes

| Status | Meaning                                   |
| ------ | ----------------------------------------- |
| `200`  | OK                                        |
| `201`  | Created                                   |
| `400`  | Bad Request / Validation Error            |
| `401`  | Unauthorized — missing or invalid JWT     |
| `403`  | Forbidden — authenticated but not allowed |
| `404`  | Resource not found                        |
| `429`  | Too Many Requests — rate limited          |
| `503`  | Service Unavailable — dependency is down  |

### Common Error Codes

| Code                  | Description                                 |
| --------------------- | ------------------------------------------- |
| `VALIDATION_FAILED`   | Request body failed schema validation       |
| `NOT_FOUND`           | Requested resource does not exist           |
| `ALREADY_SETUP`       | User profile already initialized            |
| `ALREADY_FOLLOWING`   | Already following the target user           |
| `ALREADY_LIKED`       | Post already liked by this user             |
| `FORBIDDEN`           | Not authorized to access this resource      |
| `INVALID`             | Invalid operation (e.g. following yourself) |
| `SPOTIFY_CONN_FAILED` | Spotify OAuth exchange failed               |

---

## 4. Pagination

All list endpoints support the following query parameters:

| Parameter | Type      | Default | Max  | Description           |
| --------- | --------- | ------- | ---- | --------------------- |
| `page`    | `integer` | `1`     | —    | Page number (1-based) |
| `limit`   | `integer` | `20`    | `50` | Items per page        |

---

## 5. Health

### `GET /health`

Lightweight liveness check. No authentication required.

**Response `200`:**

```json
{
  "status": "ok",
  "timestamp": "2026-03-07T12:00:00.000Z"
}
```

---

### `GET /health/detailed`

Full readiness check including dependency status. No authentication required.

**Response `200` (all healthy) / `503` (degraded):**

```json
{
  "status": "ok",
  "timestamp": "2026-03-07T12:00:00.000Z",
  "uptime": "2h 34m 10s",
  "environment": "production",
  "version": "1.0.0",
  "node": "v20.11.0",
  "memory": {
    "heapUsed": "45.23 MB",
    "heapTotal": "72.00 MB",
    "rss": "98.11 MB"
  },
  "services": {
    "supabase": { "status": "ok", "latency": "12ms" },
    "spotify": { "status": "ok", "latency": "210ms" }
  }
}
```

---

## 6. Auth

All auth routes live under `/auth`.

---

### `POST /auth/profile/setup`

Creates the user's profile in `public.users` after they sign up through Supabase Auth. This is the **first call** after sign-up.

> **Auth:** `requireJwtAuth` — JWT only, no existing profile needed.

**Request Body:**

```json
{
  "full_name": "Jane Doe",
  "username": "janedoe",
  "bio": "Music producer from NYC.",
  "avatar_url": "https://example.com/avatar.jpg",
  "genres": ["hip-hop", "jazz", "electronic"]
}
```

| Field        | Type       | Required | Constraints                                  |
| ------------ | ---------- | -------- | -------------------------------------------- |
| `full_name`  | `string`   | ✅       | Min 1 character                              |
| `username`   | `string`   | ✅       | Min 3 chars, alphanumeric + underscores only |
| `bio`        | `string`   | ❌       | Optional free text                           |
| `avatar_url` | `string`   | ❌       | Optional URL                                 |
| `genres`     | `string[]` | ✅       | Minimum 3 genres                             |

**Response `201`:**

```json
{
  "id": "uuid",
  "full_name": "Jane Doe",
  "username": "janedoe",
  "bio": "Music producer from NYC.",
  "avatar_url": "https://example.com/avatar.jpg",
  "user_type": "listener",
  "spotify_connected": false,
  "is_verified": false,
  "created_at": "2026-03-07T12:00:00.000Z"
}
```

**Error Codes:**

| Code                  | Status | Description            |
| --------------------- | ------ | ---------------------- |
| `ALREADY_SETUP`       | 400    | Profile already exists |
| `GENRE_INSERT_FAILED` | 400    | Failed to save genres  |

---

### `POST /auth/spotify/connect`

Exchanges a Spotify OAuth authorization code for tokens and links Spotify to the user's account.

> **Auth:** `requireAuth`

**Request Body:**

```json
{
  "code": "AQD...spotify_auth_code...",
  "redirect_uri": "swaptunes://spotify-callback"
}
```

| Field          | Type     | Required | Description                                         |
| -------------- | -------- | -------- | --------------------------------------------------- |
| `code`         | `string` | ✅       | Spotify OAuth authorization code                    |
| `redirect_uri` | `string` | ✅       | Must match the URI used in the Spotify auth request |

**Response `200`:**

```json
{
  "id": "uuid",
  "username": "janedoe",
  "spotify_connected": true,
  "updated_at": "2026-03-07T12:00:00.000Z"
}
```

**Error Codes:**

| Code                    | Status | Description            |
| ----------------------- | ------ | ---------------------- |
| `SPOTIFY_CONN_FAILED`   | 400    | OAuth exchange failed  |
| `SPOTIFY_UPDATE_FAILED` | 400    | Database update failed |

---

### `GET /auth/me`

Returns the authenticated user's full profile object.

> **Auth:** `requireAuth`

**Response `200`:**

```json
{
  "id": "uuid",
  "full_name": "Jane Doe",
  "username": "janedoe",
  "bio": "Music producer from NYC.",
  "avatar_url": "https://example.com/avatar.jpg",
  "user_type": "listener",
  "spotify_connected": true,
  "is_verified": false,
  "created_at": "2026-03-07T12:00:00.000Z"
}
```

---

## 7. Users

All user routes live under `/users`.

---

### `GET /users/:username`

Fetch a public profile by username including creator profile, genres, and stats.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param      | Type     | Description         |
| ---------- | -------- | ------------------- |
| `username` | `string` | The user's username |

**Response `200`:**

```json
{
  "id": "uuid",
  "full_name": "Jane Doe",
  "username": "janedoe",
  "bio": "Music producer from NYC.",
  "avatar_url": "https://example.com/avatar.jpg",
  "user_type": "creator",
  "spotify_connected": true,
  "is_verified": false,
  "genres": ["hip-hop", "jazz"],
  "creator_profiles": {
    "id": "uuid",
    "role_title": "Producer",
    "location": "New York",
    "specializations": ["mixing", "mastering"],
    "soundcloud_url": null,
    "youtube_url": null,
    "spotify_artist_url": null
  },
  "stats": {
    "followers": 142,
    "following": 58,
    "posts": 23,
    "playlists": 5,
    "collabs": 3
  },
  "created_at": "2026-03-07T12:00:00.000Z"
}
```

> Note: `spotify_access_token` and `spotify_refresh_token` are always stripped from the response.

**Error Codes:**

| Code        | Status | Description                                 |
| ----------- | ------ | ------------------------------------------- |
| `NOT_FOUND` | 404    | User with the given username does not exist |

---

### `PATCH /users/me`

Update the authenticated user's own profile. Only send fields you want to change.

> **Auth:** `requireAuth`

**Request Body (all fields optional):**

```json
{
  "full_name": "Jane Smith",
  "bio": "Updated bio",
  "avatar_url": "https://example.com/new-avatar.jpg",
  "genres": ["pop", "r&b", "soul"]
}
```

> If `genres` is included, the entire genres list is replaced (old entries deleted, new ones inserted).

**Response `200`:**

```json
{ "success": true }
```

---

### `GET /users/:userId/followers`

List all followers of a user.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description |
| -------- | ------ | ----------- |
| `userId` | `uuid` | User's ID   |

**Query Parameters:** Supports [pagination](#4-pagination).

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "full_name": "John Smith",
    "username": "johnsmith",
    "avatar_url": "https://example.com/avatar.jpg"
  }
]
```

---

### `GET /users/:userId/following`

List all users that a user is following.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description |
| -------- | ------ | ----------- |
| `userId` | `uuid` | User's ID   |

**Query Parameters:** Supports [pagination](#4-pagination).

**Response `200`:** Same shape as the followers response.

---

### `POST /users/:userId/follow`

Follow a user.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description        |
| -------- | ------ | ------------------ |
| `userId` | `uuid` | The user to follow |

**Response `200`:**

```json
{ "success": true }
```

> A `follow` notification is automatically created for the target user.

**Error Codes:**

| Code                | Status | Description                 |
| ------------------- | ------ | --------------------------- |
| `INVALID`           | 400    | Cannot follow yourself      |
| `ALREADY_FOLLOWING` | 400    | Already following this user |

---

### `DELETE /users/:userId/unfollow`

Unfollow a user.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description          |
| -------- | ------ | -------------------- |
| `userId` | `uuid` | The user to unfollow |

**Response `200`:**

```json
{ "success": true }
```

---

## 8. Creator

All creator routes live under `/creator`.

---

### `POST /creator/setup`

Upgrades an existing `listener` account to a `creator` account. Creates the `creator_profiles` record.

> **Auth:** `requireAuth`

**Request Body:**

```json
{
  "role_title": "Music Producer",
  "location": "New York, USA",
  "specializations": ["mixing", "mastering", "composition"],
  "soundcloud_url": "https://soundcloud.com/janedoe",
  "youtube_url": "https://youtube.com/@janedoe",
  "spotify_artist_url": "https://open.spotify.com/artist/xxx",
  "apple_music_url": "https://music.apple.com/artist/xxx",
  "portfolio_url": "https://janedoe.com"
}
```

| Field                | Type       | Required | Constraints         |
| -------------------- | ---------- | -------- | ------------------- |
| `role_title`         | `string`   | ✅       | Min 1 character     |
| `location`           | `string`   | ❌       | Optional            |
| `specializations`    | `string[]` | ✅       | Min 1 item          |
| `soundcloud_url`     | `string`   | ❌       | Must be a valid URL |
| `youtube_url`        | `string`   | ❌       | Must be a valid URL |
| `spotify_artist_url` | `string`   | ❌       | Must be a valid URL |
| `apple_music_url`    | `string`   | ❌       | Must be a valid URL |
| `portfolio_url`      | `string`   | ❌       | Must be a valid URL |

**Response `201`:**

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "role_title": "Music Producer",
  "location": "New York, USA",
  "specializations": ["mixing", "mastering", "composition"],
  "soundcloud_url": "https://soundcloud.com/janedoe",
  "created_at": "2026-03-07T12:00:00.000Z"
}
```

---

### `PATCH /creator/profile`

Update the authenticated creator's profile. Only send the fields you want to change.

> **Auth:** `requireAuth`

**Request Body (all fields optional):**

```json
{
  "role_title": "Beatmaker & Producer",
  "location": "Los Angeles, USA",
  "specializations": ["trap", "drill"]
}
```

**Response `200`:**

```json
{
  "id": "uuid",
  "user_id": "uuid",
  "role_title": "Beatmaker & Producer",
  "location": "Los Angeles, USA",
  "updated_at": "2026-03-07T12:00:00.000Z"
}
```

---

## 9. Posts

All post routes live under `/posts`.

---

### `GET /posts/feed`

Get a paginated feed of posts. Hidden posts are filtered out for the requesting user. Each post includes a `is_liked` flag for the current user.

> **Auth:** `requireAuth`

**Query Parameters:**

| Param   | Type      | Description                               |
| ------- | --------- | ----------------------------------------- |
| `page`  | `integer` | Page number (default: `1`)                |
| `limit` | `integer` | Items per page (default: `20`, max: `50`) |

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "content": "Just finished a new beat 🎹",
    "image_url": "https://example.com/image.jpg",
    "likes_count": 42,
    "comments_count": 7,
    "is_liked": false,
    "created_at": "2026-03-07T12:00:00.000Z",
    "user": {
      "id": "uuid",
      "username": "janedoe",
      "full_name": "Jane Doe",
      "avatar_url": "https://example.com/avatar.jpg",
      "is_verified": false
    }
  }
]
```

---

### `POST /posts`

Create a new post.

> **Auth:** `requireAuth`

**Request Body:**

```json
{
  "content": "Just dropped a new track!",
  "image_url": "https://example.com/cover.jpg"
}
```

| Field       | Type     | Required | Constraints                |
| ----------- | -------- | -------- | -------------------------- |
| `content`   | `string` | ✅       | Min 1 char, max 1000 chars |
| `image_url` | `string` | ❌       | Must be a valid URL        |

**Response `201`:**

```json
{
  "id": "uuid",
  "content": "Just dropped a new track!",
  "image_url": "https://example.com/cover.jpg",
  "likes_count": 0,
  "comments_count": 0,
  "created_at": "2026-03-07T12:00:00.000Z",
  "user": {
    "id": "uuid",
    "username": "janedoe",
    "full_name": "Jane Doe",
    "avatar_url": "https://example.com/avatar.jpg",
    "is_verified": false
  }
}
```

---

### `DELETE /posts/:postId`

Delete a post owned by the authenticated user.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description              |
| -------- | ------ | ------------------------ |
| `postId` | `uuid` | ID of the post to delete |

**Response `200`:**

```json
{ "success": true }
```

---

### `POST /posts/:postId/like`

Like a post.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description  |
| -------- | ------ | ------------ |
| `postId` | `uuid` | Post to like |

**Response `200`:**

```json
{ "success": true }
```

> A `like` notification is automatically sent to the post owner.

**Error Codes:**

| Code            | Status | Description        |
| --------------- | ------ | ------------------ |
| `ALREADY_LIKED` | 400    | Post already liked |

---

### `DELETE /posts/:postId/like`

Remove a like from a post.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description    |
| -------- | ------ | -------------- |
| `postId` | `uuid` | Post to unlike |

**Response `200`:**

```json
{ "success": true }
```

---

### `POST /posts/:postId/hide`

Hide a post from the authenticated user's feed. Idempotent — calling it multiple times is safe.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description  |
| -------- | ------ | ------------ |
| `postId` | `uuid` | Post to hide |

**Response `200`:**

```json
{ "success": true }
```

---

### `POST /posts/:postId/report`

Report a post.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description    |
| -------- | ------ | -------------- |
| `postId` | `uuid` | Post to report |

**Request Body:**

```json
{
  "reason": "Spam or misleading content"
}
```

| Field    | Type     | Required | Description           |
| -------- | -------- | -------- | --------------------- |
| `reason` | `string` | ✅       | Reason for the report |

**Response `200`:**

```json
{ "success": true }
```

---

### `GET /posts/:postId/comments`

Get all comments on a post.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description |
| -------- | ------ | ----------- |
| `postId` | `uuid` | Post ID     |

**Query Parameters:** Supports [pagination](#4-pagination). Comments are ordered oldest first.

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "content": "Absolute fire! 🔥",
    "created_at": "2026-03-07T12:01:00.000Z",
    "user": {
      "id": "uuid",
      "username": "johnsmith",
      "full_name": "John Smith",
      "avatar_url": "https://example.com/avatar.jpg"
    }
  }
]
```

---

### `POST /posts/:postId/comments`

Add a comment to a post.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param    | Type   | Description        |
| -------- | ------ | ------------------ |
| `postId` | `uuid` | Post to comment on |

**Request Body:**

```json
{
  "content": "Absolute fire! 🔥"
}
```

| Field     | Type     | Required | Constraints               |
| --------- | -------- | -------- | ------------------------- |
| `content` | `string` | ✅       | Min 1 char, max 500 chars |

**Response `201`:**

```json
{
  "id": "uuid",
  "post_id": "uuid",
  "content": "Absolute fire! 🔥",
  "created_at": "2026-03-07T12:01:00.000Z",
  "user": {
    "id": "uuid",
    "username": "johnsmith",
    "full_name": "John Smith",
    "avatar_url": "https://example.com/avatar.jpg"
  }
}
```

> A `comment` notification is automatically sent to the post owner.

---

## 10. Discover

All discover routes live under `/discover`.

---

### `GET /discover/playlists`

Browse public playlists. Optionally filter by genre.

> **Auth:** `requireAuth`

**Query Parameters:**

| Param   | Type      | Description                   |
| ------- | --------- | ----------------------------- |
| `genre` | `string`  | Filter playlists by genre tag |
| `page`  | `integer` | Page number                   |
| `limit` | `integer` | Items per page                |

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "name": "Chill Vibes",
    "description": "Weekend playlist",
    "cover_url": "https://example.com/cover.jpg",
    "is_public": true,
    "genre_tags": ["chill", "lo-fi"],
    "created_at": "2026-03-07T12:00:00.000Z",
    "user": {
      "username": "janedoe",
      "full_name": "Jane Doe",
      "avatar_url": "https://example.com/avatar.jpg"
    }
  }
]
```

---

### `GET /discover/search`

Search across users, playlists, and creators.

> **Auth:** `requireAuth`

**Query Parameters:**

| Param   | Type      | Required | Description                                                       |
| ------- | --------- | -------- | ----------------------------------------------------------------- |
| `q`     | `string`  | ✅       | Search query term                                                 |
| `type`  | `string`  | ❌       | One of `all`, `users`, `playlists`, `creators`. Defaults to `all` |
| `page`  | `integer` | ❌       | Page number                                                       |
| `limit` | `integer` | ❌       | Items per page                                                    |

**Response `200` (type=all):**

```json
{
  "users": [
    {
      "id": "uuid",
      "username": "janedoe",
      "full_name": "Jane Doe",
      "avatar_url": "https://example.com/avatar.jpg",
      "user_type": "creator"
    }
  ],
  "playlists": [
    {
      "id": "uuid",
      "name": "Chill Beats",
      "cover_url": "https://example.com/cover.jpg",
      "is_public": true,
      "user": { "username": "janedoe", "full_name": "Jane Doe" }
    }
  ],
  "creators": [
    {
      "id": "uuid",
      "role_title": "Beatmaker",
      "user": {
        "id": "uuid",
        "username": "janedoe",
        "full_name": "Jane Doe",
        "avatar_url": "https://example.com/avatar.jpg"
      }
    }
  ]
}
```

**Error Codes:**

| Code                | Status | Description                |
| ------------------- | ------ | -------------------------- |
| `VALIDATION_FAILED` | 400    | `q` query param is missing |

---

## 11. Playlists

All playlist routes live under `/playlists`.

---

### `GET /playlists/spotify/available`

Fetch the authenticated user's available Spotify playlists (not yet imported).

> **Auth:** `requireAuth` + Spotify connected (`requireSpotify`)

**Response `200`:**

```json
[
  {
    "id": "spotify_playlist_id",
    "name": "My Workout Mix",
    "description": "Energetic tracks",
    "image": "https://i.scdn.co/...",
    "tracks_total": 45,
    "is_public": true
  }
]
```

---

### `POST /playlists/import`

Import one or more Spotify playlists into SwapTunes.

> **Auth:** `requireAuth` + Spotify connected (`requireSpotify`)

**Request Body:**

```json
{
  "playlist_ids": ["spotify_playlist_id_1", "spotify_playlist_id_2"]
}
```

| Field          | Type       | Required | Description                             |
| -------------- | ---------- | -------- | --------------------------------------- |
| `playlist_ids` | `string[]` | ✅       | Array of Spotify playlist IDs to import |

**Response `201`:**

```json
{
  "imported": 2,
  "playlists": [
    {
      "id": "uuid",
      "name": "My Workout Mix",
      "spotify_id": "spotify_playlist_id_1",
      "is_public": true,
      "created_at": "2026-03-07T12:00:00.000Z"
    }
  ]
}
```

---

### `GET /playlists/user/:userId`

Get all playlists belonging to a specific user. No authentication required.

**Path Parameters:**

| Param    | Type   | Description |
| -------- | ------ | ----------- |
| `userId` | `uuid` | User's ID   |

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "name": "Chill Vibes",
    "cover_url": "https://example.com/cover.jpg",
    "is_public": true,
    "genre_tags": ["chill", "lo-fi"],
    "created_at": "2026-03-07T12:00:00.000Z"
  }
]
```

---

### `DELETE /playlists/:playlistId`

Delete a playlist owned by the authenticated user.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param        | Type   | Description        |
| ------------ | ------ | ------------------ |
| `playlistId` | `uuid` | Playlist to delete |

**Response `200`:**

```json
{ "success": true }
```

---

## 12. Collabs

All collab routes live under `/collabs`.

Collabs are collaboration listings posted by creators looking for other musicians or producers.

---

### `GET /collabs`

Browse open collaborations. Optionally filter by role.

> **Auth:** `requireAuth`

**Query Parameters:**

| Param   | Type      | Description                                             |
| ------- | --------- | ------------------------------------------------------- |
| `role`  | `string`  | Filter by a specific role (e.g. `vocalist`, `producer`) |
| `page`  | `integer` | Page number                                             |
| `limit` | `integer` | Items per page                                          |

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "title": "Looking for a vocalist",
    "description": "Working on a neo-soul EP and need a talented vocalist",
    "looking_for": ["vocalist"],
    "genre_style": ["neo-soul", "r&b"],
    "payment_type": "revenue_share",
    "status": "open",
    "created_at": "2026-03-07T12:00:00.000Z",
    "creator": {
      "id": "uuid",
      "username": "janedoe",
      "full_name": "Jane Doe",
      "avatar_url": "https://example.com/avatar.jpg",
      "is_verified": false
    }
  }
]
```

---

### `GET /collabs/me`

Get all collaborations posted by the authenticated creator.

> **Auth:** `requireAuth` + Creator account (`requireCreator`)

**Query Parameters:** Supports [pagination](#4-pagination).

**Response `200`:** Array of collab objects (same shape as above).

---

### `GET /collabs/:collabId`

Get a single collaboration by its ID.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param      | Type   | Description      |
| ---------- | ------ | ---------------- |
| `collabId` | `uuid` | Collaboration ID |

**Response `200`:** Single collab object.

**Error Codes:**

| Code        | Status | Description                  |
| ----------- | ------ | ---------------------------- |
| `NOT_FOUND` | 404    | Collaboration does not exist |

---

### `POST /collabs`

Create a new collaboration listing.

> **Auth:** `requireAuth` + Creator account (`requireCreator`)

**Request Body:**

```json
{
  "title": "Looking for a beatmaker",
  "description": "I am working on a concept album and need original beats",
  "looking_for": ["producer", "beatmaker"],
  "genre_style": ["hip-hop", "trap"],
  "payment_type": "paid",
  "status": "open"
}
```

| Field          | Type       | Required | Constraints                                 |
| -------------- | ---------- | -------- | ------------------------------------------- |
| `title`        | `string`   | ✅       | Min 5 characters                            |
| `description`  | `string`   | ✅       | Min 10 characters                           |
| `looking_for`  | `string[]` | ✅       | Min 1 role                                  |
| `genre_style`  | `string[]` | ❌       | Optional genres                             |
| `payment_type` | `enum`     | ✅       | One of `paid`, `revenue_share`, `free`      |
| `status`       | `enum`     | ❌       | One of `open`, `closed`. Defaults to `open` |

**Response `201`:** The created collab object.

---

### `PATCH /collabs/:collabId`

Update a collaboration. Only the creator who owns it can update it.

> **Auth:** `requireAuth` + Creator account (`requireCreator`)

**Path Parameters:**

| Param      | Type   | Description             |
| ---------- | ------ | ----------------------- |
| `collabId` | `uuid` | Collaboration to update |

**Request Body (all fields optional):**

```json
{
  "title": "Updated title",
  "status": "closed"
}
```

**Response `200`:** Updated collab object.

---

### `DELETE /collabs/:collabId`

Delete a collaboration. Only the creator who owns it can delete it.

> **Auth:** `requireAuth` + Creator account (`requireCreator`)

**Path Parameters:**

| Param      | Type   | Description             |
| ---------- | ------ | ----------------------- |
| `collabId` | `uuid` | Collaboration to delete |

**Response `200`:**

```json
{ "success": true }
```

---

## 13. Conversations (Messaging)

All messaging routes live under `/conversations`.

---

### `GET /conversations`

Get all conversations the authenticated user is part of.

> **Auth:** `requireAuth`

**Query Parameters:** Supports [pagination](#4-pagination).

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "last_message_at": "2026-03-07T12:05:00.000Z",
    "collab_id": "uuid or null",
    "user_one": {
      "id": "uuid",
      "username": "janedoe",
      "full_name": "Jane Doe",
      "avatar_url": "https://example.com/avatar.jpg"
    },
    "user_two": {
      "id": "uuid",
      "username": "johnsmith",
      "full_name": "John Smith",
      "avatar_url": "https://example.com/avatar2.jpg"
    }
  }
]
```

> To determine which participant is "the other user", compare both `user_one` and `user_two` against the current user's ID.

---

### `POST /conversations`

Start a new conversation with another user. If a conversation already exists between the two users, the existing one is returned.

> **Auth:** `requireAuth`

**Request Body:**

```json
{
  "recipient_id": "uuid",
  "collab_id": "uuid"
}
```

| Field          | Type   | Required | Description                              |
| -------------- | ------ | -------- | ---------------------------------------- |
| `recipient_id` | `uuid` | ✅       | The user to start a conversation with    |
| `collab_id`    | `uuid` | ❌       | Optional — link conversation to a collab |

**Response `201`:**

```json
{
  "id": "uuid",
  "user_one_id": "uuid",
  "user_two_id": "uuid",
  "collab_id": "uuid or null",
  "last_message_at": null,
  "created_at": "2026-03-07T12:00:00.000Z"
}
```

**Error Codes:**

| Code      | Status | Description                               |
| --------- | ------ | ----------------------------------------- |
| `INVALID` | 400    | Cannot start a conversation with yourself |

---

### `GET /conversations/:conversationId/messages`

Get messages in a conversation. Only participants can access this.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param            | Type   | Description     |
| ---------------- | ------ | --------------- |
| `conversationId` | `uuid` | Conversation ID |

**Query Parameters:** Supports [pagination](#4-pagination). Messages are returned newest first — reverse on the client side.

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "conversation_id": "uuid",
    "sender_id": "uuid",
    "content": "Hey, are you still looking for a vocalist?",
    "is_read": false,
    "created_at": "2026-03-07T12:06:00.000Z"
  }
]
```

**Error Codes:**

| Code        | Status | Description                                    |
| ----------- | ------ | ---------------------------------------------- |
| `FORBIDDEN` | 403    | User is not a participant of this conversation |

---

### `POST /conversations/:conversationId/messages`

Send a message in a conversation.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param            | Type   | Description     |
| ---------------- | ------ | --------------- |
| `conversationId` | `uuid` | Conversation ID |

**Request Body:**

```json
{
  "content": "Hey, are you still looking for a vocalist?"
}
```

| Field     | Type     | Required | Description  |
| --------- | -------- | -------- | ------------ |
| `content` | `string` | ✅       | Message text |

**Response `201`:**

```json
{
  "id": "uuid",
  "conversation_id": "uuid",
  "sender_id": "uuid",
  "content": "Hey, are you still looking for a vocalist?",
  "is_read": false,
  "created_at": "2026-03-07T12:06:00.000Z"
}
```

> A `message` notification is automatically sent to the other participant.

---

### `PATCH /conversations/:conversationId/read`

Mark all unread messages sent by the other user in a conversation as read.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param            | Type   | Description     |
| ---------------- | ------ | --------------- |
| `conversationId` | `uuid` | Conversation ID |

**Response `200`:**

```json
{ "success": true }
```

**Error Codes:**

| Code        | Status | Description               |
| ----------- | ------ | ------------------------- |
| `FORBIDDEN` | 403    | User is not a participant |

---

## 14. Notifications

All notification routes live under `/notifications`.

---

### `GET /notifications`

Get notifications for the authenticated user.

> **Auth:** `requireAuth`

**Query Parameters:** Supports [pagination](#4-pagination).

**Response `200`:**

```json
[
  {
    "id": "uuid",
    "type": "like",
    "is_read": false,
    "reference_id": "post_uuid",
    "created_at": "2026-03-07T12:07:00.000Z",
    "actor": {
      "id": "uuid",
      "username": "johnsmith",
      "full_name": "John Smith",
      "avatar_url": "https://example.com/avatar.jpg"
    }
  }
]
```

### Notification Types

| Type      | Trigger                        | `reference_id` points to |
| --------- | ------------------------------ | ------------------------ |
| `follow`  | Someone followed you           | `null`                   |
| `like`    | Someone liked your post        | `post_id`                |
| `comment` | Someone commented on your post | `post_id`                |
| `message` | You received a new message     | `conversation_id`        |

---

### `PATCH /notifications/:notificationId/read`

Mark a single notification as read.

> **Auth:** `requireAuth`

**Path Parameters:**

| Param            | Type   | Description                  |
| ---------------- | ------ | ---------------------------- |
| `notificationId` | `uuid` | Notification to mark as read |

**Response `200`:**

```json
{ "success": true }
```

---

### `PATCH /notifications/read-all`

Mark all notifications for the authenticated user as read.

> **Auth:** `requireAuth`

**Response `200`:**

```json
{ "success": true }
```

---

## Appendix A — Middleware Reference

| Middleware         | Purpose                                                                                        |
| ------------------ | ---------------------------------------------------------------------------------------------- |
| `requireJwtAuth`   | Verifies Supabase JWT. Sets `req.authData`. Does NOT require profile in `public.users`.        |
| `requireAuth`      | Verifies Supabase JWT **and** fetches the user from `public.users`. Sets `req.user`.           |
| `requireCreator`   | Requires `req.user.user_type === 'creator'`. Returns `403` otherwise.                          |
| `requireSpotify`   | Requires `req.user.spotify_connected === true`. Returns `403` otherwise.                       |
| `requireOwner`     | Verifies the authenticated user owns the target resource.                                      |
| `validate(schema)` | Validates `req.body` against a Zod schema. Sets `req.validatedBody`. Returns `400` on failure. |
| `globalLimiter`    | Rate limits all `/api/*` routes. Returns `429` when exceeded.                                  |

---

## Appendix B — Flutter Integration Notes

### Setting up the HTTP client

Use `dio` or `http` and attach the Supabase session JWT to every request:

```dart
// With dio
dio.options.headers['Authorization'] = 'Bearer ${supabase.auth.currentSession!.accessToken}';
dio.options.headers['Content-Type'] = 'application/json';
```

### Token Refresh

Supabase Flutter SDK handles token refresh automatically. Listen to `supabase.auth.onAuthStateChange` to update your HTTP client headers whenever the session is refreshed.

### First Launch Flow

```
1. User signs up / logs in via Supabase Auth (email, Google, Apple)
2. Check if user exists in public.users → call GET /auth/me
   - If 404/401 → profile not set up yet
3. Navigate to profile setup screen → call POST /auth/profile/setup
4. (Optional) Prompt to connect Spotify → call POST /auth/spotify/connect
5. Navigate to main app
```

### Spotify OAuth Flow (mobile)

```
1. Open Spotify Auth URL in in-app browser / external browser
2. Capture the authorization `code` from the redirect URL using a deep link
3. Call POST /auth/spotify/connect with { code, redirect_uri }
4. Store the updated user profile
```

### Conversation Helper

The `/conversations` endpoint returns both `user_one` and `user_two`. To show the "other person" in a chat list:

```dart
final other = conversation.userOne.id == currentUser.id
    ? conversation.userTwo
    : conversation.userOne;
```

### Message Pagination Note

Messages are returned **newest first** (descending by `created_at`). Reverse the list before displaying in a chat UI so the oldest messages appear at the top:

```dart
final messages = response.reversed.toList();
```
