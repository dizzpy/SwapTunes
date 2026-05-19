# Report Requirements

Source files read from implementation: `frontend/pubspec.yaml`, `frontend/lib/main.dart`, `frontend/lib/app/app.dart`, `frontend/lib/app/router.dart`, `frontend/lib/core/**`, `frontend/lib/features/**`, `supabase/migrations/**`, `frontend/test/**`, `.agent/rules/**`, and `.github/workflows/ci.yml`. Requested paths such as `melos.yaml`, root `pubspec.yaml`, `apps/mobile/**`, `packages/ui/**`, and `packages/data/**` were not present in this checkout.

## Functional Requirements

1. The app shall show onboarding before authentication and store onboarding completion locally through `SharedPreferences`.
2. The app shall authenticate users through Supabase Google OAuth.
3. The app shall authenticate users through Supabase Spotify OAuth.
4. The app shall authenticate users through email OTP, including OTP verification, resend, and a 60-second resend cooldown.
5. The app shall handle Supabase OAuth and magic-link callbacks through app links using the configured redirect scheme.
6. The app shall create a profile after first authentication with full name, username, optional bio/avatar, and selected genres.
7. The app shall connect a user's Spotify account after profile setup by launching Spotify authorization and exchanging the callback code with the backend.
8. The app shall load the current authenticated profile from `GET /auth/me` and route users either to setup or the main app depending on profile existence.
9. The app shall support logout by clearing Supabase session, stored token/user data, and OneSignal user binding.
10. The main layout shall provide Home, Discover, Inbox, and Profile tabs for listeners.
11. The main layout shall add a creator-only Collab tab for users whose `userType` is `creator`.
12. The feed shall load paginated posts, create posts with optional uploaded images, edit/delete posts, hide/report posts, like/unlike posts, list likers, and manage comments.
13. The feed shall optimistically update likes with a 500 ms debounce before sending like/unlike API calls.
14. The discover feature shall load genres, suggested users, playlists, trending genres, search results, and genre-filtered playlist lists.
15. Users shall create, update, delete, like, and unlike playlists.
16. Users shall import available Spotify playlists.
17. Users shall upload playlist images through the backend image upload endpoint.
18. Users shall view playlist details and browse featured playlists, genre details, suggested users, search, and Spotify import screens.
19. Users shall view own and public profiles by username.
20. Users shall edit profile fields, upload avatar/cover images, and invalidate cached profile data after edits.
21. Users shall follow/unfollow other users with optimistic UI and an 800 ms debounce.
22. Profile tabs shall load a user's posts, collaborations, and saved song plans.
23. Creator setup shall upgrade or reactivate a user as a creator with role title, specializations, optional location, and optional music/profile links.
24. Creators shall be able to switch back to listener mode by deactivating creator status.
25. Creators shall create, update, delete, view, and manage their collaboration posts.
26. Users shall browse collaboration posts with pagination and optional role filtering.
27. Users shall view collaboration details.
28. The AI Collab Match feature shall request creator matches for a collaboration using `POST /collabs/:id/match`, show match scores/reasons/profile data, cache loaded matches in memory, and allow cancellation/reset of the match flow.
29. The AI Song Builder feature shall submit an idea, genre, optional lyrics, and type to `POST /creator/song-builder`, display generated title/vibe/BPM/key/sections/instruments/sample hook, regenerate from the last inputs, and save plans to `POST /creator/song-builder/save`.
30. Messaging shall list conversations, start a conversation with a recipient and optional collab ID, delete conversations, load paginated messages, send messages optimistically, retry failed sends, soft-delete messages with an undo window, and mark messages read.
31. Messaging shall use Supabase Realtime for conversation inbox insert/update events and message insert/update events.
32. Notifications shall load paginated notification records, calculate unread count, mark notification groups as read, mark all as read, delete notifications, and subscribe to Supabase Realtime notification inserts.
33. Push notifications shall initialize OneSignal when `ONESIGNAL_APP_ID` exists, display foreground notifications, bind devices on login, unbind on logout, and support opt-in/opt-out methods.
34. Settings shall expose persisted notification preferences for push, activity, message, and collaboration notification categories.
35. A development tools screen exists, but its exact behavior was not required by navigation constants and was not deeply documented here.

## Creator vs Listener Differences

| Role | Implemented behavior |
|---|---|
| Listener | Main tabs are Home, Discover, Inbox, Profile. Listener does not see the Collab tab. |
| Creator | Main tabs are Home, Discover, Collab, Inbox, Profile. Creator can manage collaborations and use creator profile features. |
| Switching | `CreatorViewmodel.setupCreator` upgrades/reactivates creator mode; `CreatorViewmodel.deactivateCreator` switches back to listener mode. Main layout remaps tab indices when user type changes. |

## AI Features

| Feature | Source implementation | What it does |
|---|---|---|
| AI Collab Match | `features/ai/collab_match/**` | Calls backend `POST /collabs/:id/match`, parses `CollabMatchResult` with `userId`, `matchScore`, `reason`, and creator profile fields, and displays matched creators for a collaboration. |
| AI Song Builder | `features/ai/song_builder/**` | Calls backend `POST /creator/song-builder` with `idea`, `genre`, optional `lyrics`, and `type`; parses generated song plan data; supports regenerate and save. |

## Real-Time Features

| Feature | Source implementation | Behavior |
|---|---|---|
| Inbox updates | `ChatsListViewmodel.subscribeToInboxUpdates` | Subscribes to Supabase `conversations` insert/update events using two channels filtered by `user_one_id` and `user_two_id`. |
| Chat messages | `SingleChatViewmodel.subscribeToMessages` | Subscribes to Supabase `messages` insert/update events filtered by `conversation_id`; appends incoming messages, updates deleted messages, debounces read receipts, and gap-fills after reconnect. |
| Notifications | `NotificationViewmodel.subscribeToNotifications` | Subscribes to Supabase `notifications` inserts filtered by `user_id`, increments unread count, and reloads first page. |

## Non-Functional Requirements

### Performance

| Area | Value / behavior found |
|---|---|
| Feed page size | 20 posts. |
| Comments page size | 30 comments. |
| Discover page size | 20 playlists. |
| Browse genres visible increment | 12 genres. |
| Collaboration page size | 20 collaboration posts. |
| Messaging message page size | 30 messages. |
| Notifications page size | 20 notifications. |
| Feed like debounce | 500 ms. |
| Search debounce | 400 ms. |
| Follow debounce | 800 ms. |
| Message read debounce | 600 ms. |
| Message delete undo window | 5 seconds. |
| Image upload compression | Max dimension 1920 px, JPEG quality 85, EXIF not kept. |

### Security

| Area | Behavior found |
|---|---|
| Authentication | Supabase Auth with PKCE flow, Google OAuth, Spotify OAuth, email OTP, deep-link session recovery. |
| API authentication | Supabase JWT stored in `StorageService` and attached as `Authorization: Bearer <token>` by `ApiInterceptor`. |
| RLS | `playlist_likes` has RLS enabled with read, insert, and delete policies. Other RLS policies could not be determined from available migrations. |
| Backend rate limiting | `backend/src/app.js` contains `app.use('/api/', globalLimiter)`. Exact limiter parameters were not read from this requested frontend-focused source set. |
| CI | `flutter analyze` runs in CI; `flutter test` is currently `continue-on-error: true`. Android debug APK smoke build runs after analyze/test job. |

### Caching

| Cache | Library | TTL / behavior |
|---|---|---|
| Feed page 1 | Isar | Fresh for 5 minutes; stale page 1 used silently on API failure. |
| Profile by username | Isar | Fresh for 5 minutes; bypassable with `forceRefresh`; invalidatable after edits. |
| User profile posts page 1 | Isar | Fresh for 5 minutes. |
| Conversations list per user | Isar | Fresh for 2 minutes; stale cache used silently on API failure. |
| Page-1 messages per conversation | Isar | Fresh for 1 minute; stale cache used for immediate rendering and fallback. |
| Auth token, user ID, onboarding, recent searches, notification preferences | SharedPreferences | Persistent key-value storage. |
| Network images | `cached_network_image` dependency | Used as dependency; exact cache settings could not be determined from source scan. |

### Platform Support

Flutter app dependencies and project layout indicate mobile Flutter support. `flutter build apk --debug` is run in CI, confirming Android smoke build support. `frontend/ios/Podfile.lock` exists, indicating an iOS project is present. Could not determine full platform support from manifests because Android/iOS manifests were not part of the requested file list.

## Requirements Changed Or Dropped

| Evidence | Source | Meaning |
|---|---|---|
| `playlists.spotify_playlist_id` changed from not-null to nullable | Supabase migration | Manual playlists were introduced or supported after Spotify-only playlist IDs. |
| Unique Spotify playlist constraint replaced by partial unique index | Supabase migration | Multiple null Spotify IDs are allowed while imported Spotify IDs remain unique. |
| Playlist discover metadata added | Supabase migration | Discover evolved to include source platform, URLs, artists, mood/occasion tags, era, energy, vocal style, language, and like counts. |
| `playlist_likes` added | Supabase migration | Playlist likes became a separate table with atomic counter functions. |
| `TODO: Migrate to GoRouter when shell navigation is implemented` | `frontend/lib/app/router.dart` | Named route constants exist, but navigation still uses `MaterialApp`, nested `Navigator`, and manual routing. |
| `TODO: Add endpoints if onboarding state is tracked on the backend` | `onboarding_repository.dart` | Onboarding is local-only for now. |
| `TODO: open camera`, `TODO: open gallery`, `TODO: remove photo` | `profile_image_picker_sheet.dart` | Some profile image picker actions are deferred. |
| `TODO: implement with isOwnProfile flag and follow state` | `profile_action_buttons.dart` | Profile action button behavior is incomplete or planned. |
| `TODO: wire up delete account API call` | `settings_screen.dart` | Delete account action is not fully implemented. |

No explicit feature-flag framework or `if (false)` disabled code block was found in the scanned source.
