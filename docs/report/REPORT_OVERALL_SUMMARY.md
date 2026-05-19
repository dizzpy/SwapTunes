# Report Overall Summary

Source files read from implementation only. Requested monorepo files `melos.yaml`, root `pubspec.yaml`, `apps/mobile/**`, `packages/ui/**`, and `packages/data/**` were not present. The actual Flutter app is under `frontend/`.

## Architecture

The implemented system is a Flutter mobile app in `frontend/` that uses a layered, feature-first structure. `main.dart` initializes environment variables, OneSignal, Supabase Auth, SharedPreferences storage, an HTTP API client, and an Isar database. It then constructs datasources and repositories and injects them into Provider `ChangeNotifier` viewmodels.

Data flow in the Flutter app is: screens/widgets -> Provider viewmodels -> repositories -> remote datasources -> Express backend API. Supabase is used directly in the Flutter client for Auth and Realtime subscriptions. Backend API calls use a stored Supabase JWT as a bearer token. Local cache is handled by Isar and SharedPreferences.

## Dependency List

| Package | Purpose found from source |
|---|---|
| `flutter` | Flutter SDK UI framework. |
| `cupertino_icons` | iOS-style icon font dependency. |
| `hugeicons` | Icon set used throughout navigation and UI. |
| `flutter_svg` | SVG rendering; icons asset folder is declared. |
| `flutter_confetti` | Confetti effects for success screens. |
| `provider` | Dependency injection and `ChangeNotifier` state management. |
| `http` | HTTP client for backend API calls and multipart upload responses. |
| `shared_preferences` | Local key-value storage for token, user ID, onboarding, recent searches, and notification preferences. |
| `supabase_flutter` | Supabase initialization, Auth, OAuth/OTP, auth state stream, and Realtime channels. |
| `app_links` | Deep-link handling for Supabase/Spotify callbacks. |
| `flutter_dotenv` | Loads `.env` values for Supabase, backend URL, OneSignal, and redirect config. |
| `image_picker` | Provides `XFile` image inputs for upload flows. |
| `flutter_image_compress` | Compresses uploaded images to 1920 px max and 85% quality. |
| `cached_network_image` | Network image caching/display dependency. |
| `http_parser` | Media type handling for multipart image uploads. |
| `custom_refresh_indicator` | Pull/refresh UI support. |
| `url_launcher` | Opens OAuth URLs and external creator/profile links. |
| `isar` | Local persistent object database for feed, profile, and messaging caches. |
| `isar_flutter_libs` | Flutter binaries for Isar. |
| `onesignal_flutter` | Push notification SDK. |
| `path_provider` | Locates app documents directory for Isar database storage. |
| `rename_app` | App renaming utility dependency. |
| `flutter_test` | Flutter test framework. |
| `flutter_lints` | Static analysis lint rules. |
| `isar_generator` | Generates Isar collection code. |
| `build_runner` | Runs code generation. |
| `mocktail` | Mocks in unit/integration tests. |
| `fake_async` | Timer/debounce testing. |
| `change_app_package_name` | App package name change utility. |

## Implemented Features

| Feature | Implemented screens / flows |
|---|---|
| Splash | Splash screen while auth state resolves. |
| Onboarding | Onboarding screen and local completion state. |
| Auth | Auth screen, Google OAuth, Spotify OAuth, email OTP, deep-link handling, profile setup, Spotify connect, welcome success. |
| Main layout | Bottom tabs with listener/creator role differences and nested navigators. |
| Feed | Feed list, create/edit/post preview, post card, likes sheet, options, comments, image upload, hide/report/delete. |
| Discover | Discover home, browse genres, genre detail, featured playlists, playlist detail/editor, search, Spotify import, suggested users. |
| Profile | Own profile, public profile, profile setup, edit profile, avatar/cover picker, follow sheets, profile stats/tabs, creator info, saved song plans. |
| Creator | Become creator, creator setup/loading/success, listener transition, deactivate creator. |
| Collab | Collaboration feed/details/manage/new collaboration and creator-only tab. |
| AI Collab Match | Loading/results screens, match cards, match fetching and cancellation. |
| AI Song Builder | Input/loading/result screens, generated structure display, regenerate, save, and message-recipient sheet. |
| Messaging | Chat list, single chat, chat tiles, bubbles, input field, date separators, Realtime updates. |
| Notifications | Notifications screen, notification list state, unread count, mark read/delete, Realtime inserts. |
| Settings | Settings screen, sections/tiles, notification preferences, OneSignal opt-in/opt-out support in service layer. |
| Dev | Dev tools screen exists. |

## Folder Structure

| Folder | Description |
|---|---|
| `frontend/lib/app` | Root app widget, auth listener, route constants. |
| `frontend/lib/core/constants` | API URLs, strings, assets, spacing, Spotify/Supabase constants. |
| `frontend/lib/core/network` | API client, auth header interceptor, network exception types. |
| `frontend/lib/core/services` | Isar, navigation, OneSignal, SharedPreferences storage, Supabase Auth services. |
| `frontend/lib/core/theme` | Central colors, text styles, and dark Material theme. |
| `frontend/lib/core/utils` | Haptics, snackbars, extensions, validators. |
| `frontend/lib/core/widgets` | Reusable app-level UI widgets. |
| `frontend/lib/features/ai` | AI Collab Match and AI Song Builder feature modules. |
| `frontend/lib/features/auth` | Auth datasource/model/repository, auth screens/viewmodel/widgets. |
| `frontend/lib/features/collab` | Collaboration datasource/model/repository, screens/viewmodel/widgets. |
| `frontend/lib/features/creator` | Creator setup/deactivation datasource/model/repository, screens/viewmodel/widgets. |
| `frontend/lib/features/dev` | Development tools screen. |
| `frontend/lib/features/discover` | Playlist/discover datasources/models/repository, screens/viewmodels/widgets. |
| `frontend/lib/features/feed` | Feed datasource/models/repository, screens/viewmodel/widgets and Isar cached post model. |
| `frontend/lib/features/messaging` | Messaging datasource/models/repository, chat screens/viewmodels/widgets and Isar caches. |
| `frontend/lib/features/notifications` | Notification datasource/model/repository, screen/viewmodel/widget. |
| `frontend/lib/features/onboarding` | Onboarding repository, screen, and viewmodel. |
| `frontend/lib/features/profile` | Profile datasource/models/repository, screens/viewmodels/widgets and Isar caches. |
| `frontend/lib/features/settings` | Settings screen and reusable settings widgets. |
| `frontend/lib/features/splash` | Splash screen. |
| `frontend/lib/shared/widgets` | Shared buttons, icon button, auth guard, input box, and progress indicator. |
| `supabase/migrations` | Supabase schema migration files; one playlist discover migration exists. |
| `.agent/rules` | Project coding/architecture/theme/data rules. |
| `.github/workflows` | CI and deployment workflows; `ci.yml` analyzes/tests/builds frontend and calls backend lint workflow. |

## State Management

The app uses the Provider package with `ChangeNotifier` viewmodels. Global providers are registered in `main.dart` through `MultiProvider`, including auth, onboarding, profile setup, feed, creator, collab, AI match, AI song builder, API client, profile repository, discover repository, storage service, and messaging repository. Some screens create per-screen viewmodels for isolated state, such as public profiles and chat screens.

## AI Implementation

| Feature | Provider / viewmodel | Backend call | Payload / result |
|---|---|---|---|
| AI Collab Match | `CollabMatchViewModel` | `POST /collabs/:id/match` | Sends the collab ID in the path. Parses a list of `CollabMatchResult` with `userId`, `matchScore`, `reason`, and `MatchedCreatorProfile` fields. Prompt structure could not be determined from Flutter source because generation occurs behind the backend endpoint. |
| AI Song Builder | `SongBuilderViewModel` | `POST /creator/song-builder` | Sends `idea`, `genre`, optional `lyrics`, and `type`. Parses `SongBuilderResult` with `title`, `vibe`, `bpm`, `key`, `genre`, `type`, `sampleHook`, `sections`, `instruments`, and `hasUserLyrics`. Prompt structure could not be determined from Flutter source because generation occurs behind the backend endpoint. |
| Save song plan | `SongBuilderViewModel.savePlan` | `POST /creator/song-builder/save` | Saves title and full generated plan JSON. |

## Notification System

OneSignal is initialized in `main.dart` through `OnesignalService.initialize()`. If `ONESIGNAL_APP_ID` is empty, initialization is skipped. On login, `AuthViewmodel` calls `OnesignalService.login(userId)` after loading the profile; on logout it calls `OnesignalService.logout()`. Foreground notifications are displayed by OneSignal. Notification taps are logged, and source comments state deep-link routing can be wired later.

In-app notifications use `NotificationDatasource`, `NotificationRepository`, and `NotificationViewmodel`. The viewmodel loads paginated notifications from `/notifications`, maintains unread count, supports mark-as-read, mark-all-read, delete, and subscribes to Supabase Realtime inserts on the `notifications` table filtered by the current `user_id`.

## Caching

| Area | Exact implementation |
|---|---|
| Feed | `FeedRepository` caches page-1 posts in Isar `CachedPost` rows for 5 minutes and returns stale page-1 cache on API failure. |
| Profile | `ProfileRepository` caches profiles by username in Isar `CachedProfile` for 5 minutes and can invalidate by username. |
| Profile posts | `ProfileRepository` caches page-1 user posts in Isar `CachedUserPost` for 5 minutes. |
| Messaging inbox | `MessagingRepository` caches conversations in Isar `CachedConversation` per user ID for 2 minutes and returns stale cache on API failure. |
| Chat messages | `MessagingRepository` caches page-1 messages in Isar `CachedMessages` per conversation ID for 1 minute; `SingleChatViewmodel` renders stale cache first, then refreshes. |
| Key-value state | `StorageService` uses SharedPreferences for token, user ID, onboarding completion, recent searches, and notification preferences. |
