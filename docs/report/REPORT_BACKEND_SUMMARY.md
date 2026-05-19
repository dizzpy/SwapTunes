# Report Backend Summary

Source files read: every file under `backend/src/`, including app/router setup, route modules, controllers, services, repositories, middleware, event listeners, jobs, and `shared/services/ai.service.js`.

## API Routes

Base mount: `app.use('/api/v1', router)`. Global middleware applies to `/api/` before the versioned router.

| Method | Path | Auth required | What it does |
|---|---|---|---|
| GET | `/api/v1/health` | No | Liveness check; returns status and timestamp. |
| GET | `/api/v1/health/detailed` | No | Readiness check for Supabase and Spotify config, plus uptime, memory, environment, version, and Node version. |
| POST | `/api/v1/dev/reset-role` | No; route only mounted outside production | Development-only role reset by username, with optional creator profile deletion. |
| POST | `/api/v1/auth/profile/setup` | Supabase JWT only via `requireJwtAuth` | Creates a new `users` row and `user_genres` rows after Supabase signup. |
| POST | `/api/v1/auth/spotify/connect` | Full app user via `requireAuth` | Exchanges Spotify auth code for tokens and marks the user as Spotify connected. |
| GET | `/api/v1/auth/me` | `requireAuth` | Returns authenticated database user profile from `req.user`. |
| PATCH | `/api/v1/users/me` | `requireAuth` | Updates current user profile fields and genres; enforces 7-day username cooldown. |
| GET | `/api/v1/users/:username` | `requireAuth` | Loads public/own profile by username, genres, creator profile, stats, and follow state. |
| GET | `/api/v1/users/:userId/posts` | `requireAuth` | Lists posts for a user profile tab. |
| GET | `/api/v1/users/:userId/collabs` | `requireAuth` | Lists open collaborations created by a user. |
| GET | `/api/v1/users/:userId/followers` | `requireAuth` | Lists followers with pagination. |
| GET | `/api/v1/users/:userId/following` | `requireAuth` | Lists following users with pagination. |
| GET | `/api/v1/users/:userId/songs` | `requireAuth` | Lists saved song plans for a user profile. |
| POST | `/api/v1/users/:userId/follow` | `requireAuth` | Follows another user and creates a follow notification. |
| DELETE | `/api/v1/users/:userId/unfollow` | `requireAuth` | Unfollows another user. |
| POST | `/api/v1/creator/setup` | `requireAuth` | Creates or reactivates a creator profile and sets `users.user_type` to `creator`. |
| PATCH | `/api/v1/creator/profile` | `requireAuth` + `requireCreator` | Updates the authenticated creator profile. |
| POST | `/api/v1/creator/deactivate` | `requireAuth` + `requireCreator` | Closes creator's open collaborations and switches user back to listener. |
| POST | `/api/v1/creator/song-builder` | `requireAuth` + `requireCreator` | Builds an AI song plan using Gemini. |
| POST | `/api/v1/creator/song-builder/save` | `requireAuth` + `requireCreator` | Saves a generated song plan to `saved_song_plans`. |
| GET | `/api/v1/posts/feed` | `requireAuth` | Returns paginated feed posts excluding hidden posts and includes current user's like state. |
| POST | `/api/v1/posts` | `requireAuth` | Creates a post with content and optional image URL. |
| PATCH | `/api/v1/posts/:postId` | `requireAuth` | Updates current user's post content/image. |
| DELETE | `/api/v1/posts/:postId` | `requireAuth` | Deletes current user's post. |
| POST | `/api/v1/posts/:postId/like` | `requireAuth` | Likes a post, increments like count RPC, and creates a like notification. |
| DELETE | `/api/v1/posts/:postId/like` | `requireAuth` | Unlikes a post and decrements like count RPC. |
| POST | `/api/v1/posts/:postId/hide` | `requireAuth` | Inserts a hidden-post row for the user. |
| POST | `/api/v1/posts/:postId/report` | `requireAuth` | Reports a post with a reason. |
| GET | `/api/v1/posts/:postId/comments` | `requireAuth` | Lists paginated comments for a post. |
| POST | `/api/v1/posts/:postId/comments` | `requireAuth` | Adds a comment, increments comment count RPC, and creates a comment notification. |
| PATCH | `/api/v1/posts/:postId/comments/:commentId` | `requireAuth` | Updates current user's comment. |
| DELETE | `/api/v1/posts/:postId/comments/:commentId` | `requireAuth` | Deletes current user's comment and decrements comment count RPC. |
| GET | `/api/v1/posts/:postId/likers` | `requireAuth` | Lists up to 50 users who liked a post. |
| GET | `/api/v1/discover/genres` | `requireAuth` | Returns unique genres from public playlists and user genres. |
| GET | `/api/v1/discover/playlists` | `requireAuth` | Lists public playlists, optionally filtered by genre. |
| GET | `/api/v1/discover/users` | `requireAuth` | Lists suggested users excluding self and already-followed users. |
| GET | `/api/v1/discover/trending` | `requireAuth` | Returns top genres by public playlist tag frequency. |
| GET | `/api/v1/discover/search` | `requireAuth` | Searches users, playlists, and/or creators by query and type. |
| GET | `/api/v1/playlists/spotify/available` | `requireAuth` + `requireSpotify` | Fetches Spotify playlists and marks which are already imported. |
| POST | `/api/v1/playlists/import` | `requireAuth` + `requireSpotify` | Imports selected Spotify playlists via upsert on `spotify_playlist_id`. |
| POST | `/api/v1/playlists/create` | `requireAuth` | Creates a manual playlist with discover metadata. |
| GET | `/api/v1/playlists/user/:userId` | No route auth | Lists public playlists for a user. |
| GET | `/api/v1/playlists/:playlistId` | No route auth | Reads a single playlist by UUID. |
| PATCH | `/api/v1/playlists/:playlistId` | `requireAuth` | Updates owned playlist fields; ownership checked by matching `user_id`. |
| DELETE | `/api/v1/playlists/:playlistId` | `requireAuth` | Deletes an owned playlist. |
| POST | `/api/v1/playlists/:playlistId/like` | `requireAuth` | Likes a playlist and calls `increment_playlist_likes`. |
| DELETE | `/api/v1/playlists/:playlistId/like` | `requireAuth` | Unlikes a playlist and calls `decrement_playlist_likes` only if a row was deleted. |
| GET | `/api/v1/collabs` | `requireAuth` | Lists open collaboration posts with optional role filter. |
| GET | `/api/v1/collabs/me` | `requireAuth` + `requireCreator` | Lists authenticated creator's collaboration posts. |
| GET | `/api/v1/collabs/:collabId` | `requireAuth` | Loads one collaboration post. |
| POST | `/api/v1/collabs` | `requireAuth` + `requireCreator` | Creates a collaboration post. |
| PATCH | `/api/v1/collabs/:collabId` | `requireAuth` + `requireCreator` | Updates creator-owned collaboration. |
| DELETE | `/api/v1/collabs/:collabId` | `requireAuth` + `requireCreator` | Deletes creator-owned collaboration. |
| POST | `/api/v1/collabs/:collabId/match` | `requireAuth` + `requireCreator` | Runs AI Collab Match for the creator's own listing. |
| GET | `/api/v1/conversations` | `requireAuth` | Lists conversations via `get_conversations_for_user` RPC. |
| POST | `/api/v1/conversations` | `requireAuth` | Starts or returns a one-to-one conversation, optionally linked to a collab. |
| GET | `/api/v1/conversations/:conversationId/messages` | `requireAuth` | Lists messages with optional `before` cursor and limit. |
| POST | `/api/v1/conversations/:conversationId/messages` | `requireAuth` | Sends a message and creates a message notification for the other participant. |
| PATCH | `/api/v1/conversations/:conversationId/read` | `requireAuth` | Marks other participant's messages as read. |
| DELETE | `/api/v1/conversations/:conversationId/messages/:messageId` | `requireAuth` | Soft-deletes a message; sender only. |
| DELETE | `/api/v1/conversations/:conversationId` | `requireAuth` | Soft-deletes conversation for current user; permanently deletes when both users delete. |
| GET | `/api/v1/notifications` | `requireAuth` | Lists current user's notifications with actor data. |
| PATCH | `/api/v1/notifications/read-all` | `requireAuth` | Marks all current user's notifications as read. |
| PATCH | `/api/v1/notifications/:notificationId/read` | `requireAuth` | Marks one current-user notification as read. |
| DELETE | `/api/v1/notifications/:notificationId` | `requireAuth` | Deletes one current-user notification. |
| POST | `/api/v1/uploads/image` | `requireAuth` | Accepts one image file through multer memory storage, uploads to UploadThing, and returns CDN URL. |

## AI Service

File: `backend/src/shared/services/ai.service.js`.

### Gemini Model

The backend uses `@google/generative-ai` and creates the model with:

```js
genAI.getGenerativeModel({ model: 'gemini-3-flash-preview' })
```

If `GEMINI_API_KEY` is missing, `getModel()` throws `503 AI_NOT_CONFIGURED`.

### Response Parsing Logic

Both AI features call `model.generateContent(prompt)` and parse `result.response.text()` through:

```js
const clean = text.replace(/```json|```/g, '').trim()
return JSON.parse(clean)
```

This strips JSON markdown fences and parses the remaining string as JSON. There is no schema validation after parsing.

### AI Collab Match Prompt Structure

Function: `matchCreatorsForCollab(collab, creators)`.

The prompt:

- Sets role: “You are a music collaboration assistant for a platform called SwapTunes.”
- Includes collaboration listing fields:
  - `Title: ${collab.title}`
  - `Roles needed: ${collab.looking_for.join(', ')}`
  - `Genres: ${(collab.genre_style ?? []).join(', ')}`
  - `Description: ${collab.description}`
- Includes active creators as pretty JSON: `JSON.stringify(creators, null, 2)`.
- Instructs Gemini to analyze each creator’s `specializations`, `role_title`, and description context against the listing.
- Requests top 5 matches ranked by compatibility score.
- Requires valid JSON only, no extra text, no markdown.
- Required response shape:

```json
{
  "matches": [
    {
      "userId": "string (the user_id field from the creator data)",
      "matchScore": 92,
      "reason": "One to two sentence explanation of why they match"
    }
  ]
}
```

Service enrichment after AI:

- `collabs.service.js` loads the collab and verifies `collab.creator_id === requestingUserId`.
- It loads creator profiles excluding the requesting user.
- It calls `matchCreatorsForCollab`.
- It maps `aiResult.matches` to the local creator records by matching `creator.user_id === match.userId`.
- It returns `{ userId, matchScore, reason, profile }` and filters out matches whose profile was not found.

### AI Song Builder Prompt Structure

Function: `buildSongPlan({ idea, genre, lyrics, type })`.

Branching logic:

| Branch | Condition | Prompt focus |
|---|---|---|
| EDM instrumental | `genre` is `EDM` or `Electronic`, and `type === 'instrumental'` | Complete EDM production plan with Intro, Buildup 1, Drop 1, Breakdown, Buildup 2, Drop 2, Outro. Drop sections must set `isDrop: true`. |
| Non-EDM instrumental | `type === 'instrumental'` | Complete instrumental arrangement with 5-7 sections, dynamics, instrument roles, emotional arc, and all `isDrop: false`. |
| Vocal with lyrics | `lyrics` is non-empty | Places user lyrics into the best section, builds structure around them, suggests remaining sections, and generates a hook if needed. Only one section should have `isUserLyrics: true`. |
| Vocal without lyrics | Default branch | Complete songwriting plan with structure, section directions, hook suggestion, and all `isDrop: false`. |

All branches require valid JSON only, no markdown. All branches require this result family:

```json
{
  "title": "Creative or suggested track title",
  "vibe": "Short punchy vibe description",
  "bpm": "string BPM",
  "key": "musical key",
  "genre": "input genre",
  "type": "instrumental or vocal",
  "sampleHook": "string or null",
  "hasUserLyrics": true,
  "sections": [
    {
      "name": "section name",
      "timestamp": "timestamp string or null",
      "direction": "section creative/production direction",
      "userLyrics": "lyrics string or null",
      "isUserLyrics": false,
      "isDrop": false
    }
  ],
  "instruments": ["instrument1", "instrument2", "instrument3"]
}
```

AI error mapping:

| Condition in caught error message | Error returned |
|---|---|
| Contains `429`, `Too Many Requests`, or `quota` | `429 AI_QUOTA_EXCEEDED` |
| Contains `403`, `API_KEY`, or `invalid` | `503 AI_NOT_CONFIGURED` |
| Any other Collab Match error | `502 AI_MATCH_FAILED` |
| Any other Song Builder error | `502 AI_BUILD_FAILED` |

## OneSignal And Notification Triggers

OneSignal file: `backend/src/shared/services/onesignal.service.js`.

`NotificationsService.createNotification()` writes an in-app notification through `NotificationsRepository.createNotification()` and then calls `_sendPush()` without awaiting it. `_sendPush()` fetches the actor username, formats it as `@username` or `Someone`, and calls `oneSignalService.sendPushNotification()`.

OneSignal request details:

| Field | Value |
|---|---|
| API URL | `https://onesignal.com/api/v1/notifications` |
| Required env vars | `ONESIGNAL_APP_ID`, `ONESIGNAL_REST_API_KEY` |
| Targeting | `include_aliases: { external_id: [userId] }` |
| Channel | `target_channel: 'push'` |
| Heading | `SwapTunes` |
| Data payload | `{ type, reference_id: referenceId ?? null }` |

Notification title/body templates:

| Type | Text |
|---|---|
| `like` | `${actor} liked your post` |
| `comment` | `${actor} commented on your post` |
| `follow` | `${actor} started following you` |
| `message` | `${actor} sent you a message` |
| `collab` | `${actor} is interested in your collab` |

Actual service-level triggers:

| Trigger source | Event | Notification type | Push? |
|---|---|---|---|
| `posts.service.js` `likePost` | User likes another user's post | `like` | Yes, via `notificationsService.createNotification()` |
| `posts.service.js` `addComment` | User comments on another user's post | `comment` | Yes |
| `users.service.js` `followUser` | User follows another user | `follow` | Yes |
| `conversations.service.js` `sendMessage` | User sends a message to the other participant | `message` | Yes |

Event listener notes:

- `shared/events/listeners/notification.listener.js` listens for `post.liked` and `post.commented`, but writes only through `notificationsRepository.createNotification()`, not `notificationsService.createNotification()`, so those listener paths do not send OneSignal pushes.
- No `emitter.emit(...)` calls were found under `backend/src`, so those event listener paths appear unused from current source.
- The comment “Add other notification listeners (follow, collab, message) here” exists, but no such event listeners are implemented.
- No implemented `collab` notification trigger was found, despite the OneSignal text template supporting `collab`.

## Error Handling

Controllers use `try/catch` and call `next(err)` for service errors. `app.js` installs `errorHandler` after the router.

Error response format from `errorHandler`:

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "message",
    "stack": "development only"
  }
}
```

Flow:

1. Route middleware may return errors directly, for example `requireAuth`, `requireJwtAuth`, `requireCreator`, `requireSpotify`, and validation middleware.
2. Controllers call services/repositories and pass thrown errors to `next(err)`.
3. Services commonly throw plain objects with `statusCode`, `code`, and `message`.
4. `AppError` subclasses exist (`NotFoundError`, `UnauthorizedError`, `ForbiddenError`, `ValidationError`, `InternalError`), but most services use plain thrown objects. `notifications.repository.js` uses `InternalError`.
5. `errorHandler` uses `err.statusCode || 500`, `err.code || 'INTERNAL_SERVER_ERROR'`, and `err.message || 'An unexpected error occurred'`.
6. `errorHandler` logs status 500 as `Unhandled Exception` with method, URL, and body; non-500 errors are logged as `Operational Error` with method and URL.

Middleware direct responses:

| Middleware | Failure behavior |
|---|---|
| `requireAuth` | Missing/invalid token or missing DB user returns `401 UNAUTHORIZED`; on success sets `req.user`. |
| `requireJwtAuth` | Missing/invalid token returns `401 UNAUTHORIZED`; on success sets `req.authData.user`. |
| `requireCreator` | Non-creator returns `403 FORBIDDEN`. |
| `requireSpotify` | User without Spotify connection returns `403 FORBIDDEN`. |
| `validate` | Invalid body returns `400 VALIDATION_ERROR` with Zod formatted details; on success sets `req.validatedBody`. |
| `validateParams` | Invalid params returns `400 INVALID_PARAMS` with Zod formatted details. |
| `uploads.routes.js` multer filter | Non-image file creates a 400 error with message `Only image files are allowed`. |

## Rate Limiting

File: `backend/src/shared/middleware/rateLimiter.js`.

Global limiter:

| Setting | Value |
|---|---|
| Applied in app | `app.use('/api/', globalLimiter)` |
| Window | `15 * 60 * 1000` ms, 15 minutes |
| Max | 150 requests per IP per window |
| Standard headers | `true`, returns `RateLimit-*` headers |
| Legacy headers | `false`, disables `X-RateLimit-*` headers |
| Response | `TOO_MANY_REQUESTS`, message: `Too many requests from this IP, please try again after 15 minutes.` |

Auth limiter:

| Setting | Value |
|---|---|
| Window | `60 * 60 * 1000` ms, 1 hour |
| Max | 10 requests per IP per window |
| Response | `TOO_MANY_REQUESTS`, message: `Too many auth attempts from this IP, please try again after 1 hour.` |
| Usage found | Exported as `authLimiter`, but not applied to any route in current `backend/src` source. |

## Other Backend Notes

- `app.js` uses `helmet`, `cors`, `express.json`, `compression`, and `pino-http`.
- `supabase` client uses `SUPABASE_SERVICE_ROLE_KEY` when available, otherwise falls back to `SUPABASE_ANON_KEY`, with `autoRefreshToken: false` and `persistSession: false`.
- Default pagination helper uses page `1`, limit `20`, max limit `50`; messaging overrides message limit max to `100`.
- Image upload uses multer memory storage with max file size `10 * 1024 * 1024` bytes and accepts only `image/*`.
- A Spotify token refresh cron job is scheduled every 45 minutes, but the implementation body is a placeholder that logs success.





