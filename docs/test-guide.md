# SwapTunes — Testing & Code Quality Rules
> For Claude Code and AI Agents
> Rules-based guide. Apply to any file, any feature, any screen.

---

## Stack
Flutter · Provider · MVVM · Node.js/Express · Supabase · Isar · Spotify Web API

---

## 1. Feature Development Order

Always follow this order. Never skip or reorder steps.

```
1. Build UI screen (layout only, no logic)
2. Wire ViewModel + API  →  working end-to-end with live data
3. Add optimistic UI     →  UI updates before API responds
4. Add Isar caching      →  repository layer only
5. Write tests           →  unit tests first, then widget tests, then integration tests
6. Run all quality checks
7. Move to next feature
```

---

## 2. Architecture Rules

### Layers and what belongs in each

| Layer | Folder pattern | Allowed to do | Never allowed |
|---|---|---|---|
| Screen / Widget | `screens/`, `widgets/` | Read from ViewModel, call ViewModel methods, render UI | Business logic, API calls, DB calls, `setState` if ViewModel exists |
| ViewModel | `viewmodels/` | Call repository/service, call `notifyListeners()` | Import Flutter widgets, call Supabase/HTTP directly |
| Repository | `repositories/`, `datasources/` | Call Supabase, call API, read/write Isar | Business logic, UI logic |
| Model | `models/` | Data shape only | Logic of any kind |

### Hard rules
- Screens read state via `context.watch`, trigger actions via `context.read`
- ViewModels never know about `BuildContext`
- Repositories are the only layer that touches Supabase or the network
- Models are pure data — no methods, no logic

---

## 3. Code Quality Rules

### 3.1 No hardcoded colors

```dart
// ❌ Never
Color(0xFF...)
Colors.green
Color.fromRGBO(...)

// ✅ Always
Theme.of(context).colorScheme.primary
AppColors.someColor  // from core/theme/app_colors.dart
```

Every color must come from `app_colors.dart` or the theme. No exceptions.

---

### 3.2 No raw strings in widgets

```dart
// ❌ Never
Text("Welcome back")
hintText: "Search..."
label: "Save"

// ✅ Always
Text(AppStrings.someKey)  // from core/constants/app_strings.dart
```

All user-visible strings live in `app_strings.dart`. Debug `print()` strings are exempt.

---

### 3.3 No business logic in screens or widgets

Any of these found in a screen or widget file is a violation:

- Direct Supabase calls
- Direct HTTP calls
- `SharedPreferences` access
- `Timer` usage
- Data filtering or transformation (`where`, `map`, `sort` on data lists)
- Conditional logic based on data values

Move it to the ViewModel.

---

### 3.4 No setState when a ViewModel exists

If a screen has a corresponding ViewModel, `setState` is banned in that screen. All state lives in the ViewModel.

---

### 3.5 Always dispose controllers

Any class that creates one of these must override `dispose()` and clean it up:

- `TextEditingController`
- `AnimationController`
- `ScrollController`
- `FocusNode`
- `Timer`
- `StreamSubscription`

```dart
// ✅ Required pattern
@override
void dispose() {
  _controller.dispose();
  _timer?.cancel();
  _subscription.cancel();
  super.dispose();
}
```

---

### 3.6 Optimistic UI pattern

Every mutation (like, follow, save, update) must follow this pattern:

```
1. Snapshot current state
2. Update UI immediately
3. Call API in background
4. On failure → revert to snapshot + show error
```

No mutation should wait for an API response before updating the UI.

---

### 3.7 Debounce pattern

Any action that can be triggered rapidly by the user (like, follow, search) must be debounced.

Rules:
- Debounce timer lives in the ViewModel, never in the widget
- Timer is cancelled and restarted on each call
- If state returns to original within the debounce window — fire zero API calls
- Always clean up timer in `dispose()`

---

## 4. Caching Rules

### Where caching lives
- **Isar** → persistent disk cache for lists (feed posts, playlists, conversations)
- **shared_preferences** → small persistent values (auth token, user profile, settings)
- **ViewModel memory** → session-only cache (search results, transient UI state)

### Which layer owns caching
- Repository is the only layer that reads/writes Isar
- ViewModel never touches Isar directly
- Screens never touch Isar

### Required cache behaviour
- Repository checks cache first, returns if fresh, fetches from API if stale
- Every cached collection has a TTL — stale data triggers a background refresh
- Pull-to-refresh always bypasses cache and forces an API fetch
- On API failure, return stale cache rather than showing an error (silent fallback)

### 4.1 Isar schema rules

Every Isar collection must follow this pattern:

```dart
// ✅ Required schema shape
@Collection()
class CachedFoo {
  Id isarId = Isar.autoIncrement;

  @Index()                  // index on the lookup key (e.g. postId, username)
  late String key;

  late String contentJson;  // full model serialized as JSON string
  late DateTime cachedAt;   // used to evaluate TTL freshness
}
```

Rules:
- One schema per entity type — never reuse a schema for a different model
- `contentJson` stores the full model as a JSON string — no typed Isar fields for model data
- `cachedAt` is always required — no schema without it
- TTL is evaluated in the repository, never in the ViewModel or widget
- Schemas live in `data/models/` alongside the regular model files
- Generated `.g.dart` files must be committed — never gitignored

### 4.2 Isar caching — what gets cached and where

| Data | Cache type | TTL | Repository |
|---|---|---|---|
| Feed posts (page 1) | Isar | 5 min | `FeedRepository` |
| User posts (profile tab) | Isar | 5 min | `ProfileRepository` |
| User profile | Isar | 5 min | `ProfileRepository` |
| Comments per post | ViewModel in-memory | session | `FeedViewmodel` |
| Auth tokens | shared_preferences | — | `StorageService` |

### 4.3 IsarService

A single `IsarService` singleton opens the Isar database on app startup.

```dart
// lib/core/services/isar_service.dart
class IsarService {
  static Isar? _instance;

  static Future<Isar> open() async {
    if (_instance != null) return _instance!;
    _instance = await Isar.open([
      CachedPostSchema,
      CachedProfileSchema,
      CachedUserPostSchema,
    ]);
    return _instance!;
  }
}
```

- Called once in `main.dart` before `runApp`
- Injected into repositories via constructor — repositories never call `IsarService.open()` themselves

### 4.4 Cache-first repository pattern

```dart
// ✅ Required pattern for every cached collection
Future<List<PostModel>> getFeed({int page = 1, bool forceRefresh = false}) async {
  if (!forceRefresh) {
    final cached = await _isar.cachedPosts
        .filter()
        .cachedAtGreaterThan(DateTime.now().subtract(const Duration(minutes: 5)))
        .findAll();
    if (cached.isNotEmpty) return cached.map(_deserialize).toList();
  }

  try {
    final posts = await _datasource.getFeed(page: page);
    await _isar.writeTxn(() async {
      await _isar.cachedPosts.clear();
      await _isar.cachedPosts.putAll(_serialize(posts));
    });
    return posts;
  } catch (_) {
    // Silent fallback — return stale cache rather than error
    final stale = await _isar.cachedPosts.where().findAll();
    return stale.map(_deserialize).toList();
  }
}
```

---

## 5. Testing Rules

### Test dependencies (pubspec.yaml)

Add to `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.0
  fake_async: ^1.3.1
  isar_generator: ^3.1.0+1
  flutter_lints: ^6.0.0
```

Add to `dependencies`:

```yaml
dependencies:
  isar: ^3.1.0+1
  isar_flutter_libs: ^3.1.0+1
```

Run after adding:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### What to test

| Test type | What | When |
|---|---|---|
| Unit test | ViewModel logic, debounce, optimistic UI, cache behaviour | After step 4 (caching done) |
| Widget test | Key UI components, all states (loading / data / error / empty) | After unit tests pass |
| Integration test | ViewModel → Repository → real Isar (in-memory) end-to-end | After widget tests pass |

### Test file structure

```
frontend/test/
├── helpers/
│   └── mocks.dart                               ← shared generated mockito mocks
├── features/
│   ├── auth/
│   │   ├── viewmodels/
│   │   │   └── auth_viewmodel_test.dart
│   │   └── widgets/
│   │       └── auth_screen_test.dart
│   ├── feed/
│   │   ├── viewmodels/
│   │   │   └── feed_viewmodel_test.dart
│   │   └── widgets/
│   │       └── post_card_test.dart
│   └── profile/
│       ├── viewmodels/
│       │   ├── user_profile_viewmodel_test.dart
│       │   └── profile_viewmodel_test.dart
│       └── widgets/
│           └── profile_header_test.dart
└── integration/
    ├── feed_cache_integration_test.dart
    └── profile_cache_integration_test.dart
```

### 5.1 Unit test requirements

Every ViewModel must have unit tests covering:
- Happy path (success response)
- Error path (API failure → correct error state)
- Optimistic UI (UI updates before API, reverts on failure)
- Debounce (rapid calls → single API call, cancel → zero calls)
- Cache hit (no API call when cache is fresh)
- Cache miss (API called when cache is stale)

#### Auth — `AuthViewmodel`

| Test | Scenarios |
|---|---|
| `signInWithGoogle` | happy → `awaitingOAuth` status set; error → error message set |
| `signInWithSpotify` | happy → `awaitingOAuth` status set; error → error message set |
| `sendMagicLink` | happy → returns `true` + `awaitingMagicLink`; error → returns `false` |
| `handleDeepLink` | success → profile loaded; failure → error state |
| `tryAutoLogin` | not logged in → early exit; logged in → user loaded; expired token → logout + unauthenticated |
| `setupProfile` | happy → `profileLoaded` status; error → error message |
| `connectSpotify` | happy → refreshes user; error → error message |
| `refreshCurrentUser` | happy → user loaded; error → clears user |
| `logout` | clears user + sets `unauthenticated` |
| Auth stream — `signedIn` | syncs token + loads profile |
| Auth stream — `signedOut` | clears user + unauthenticated |
| Auth stream — `initialSession` with session | syncs token + loads profile |
| Auth stream — `initialSession` no session | sets unauthenticated |

#### Feed — `FeedViewmodel`

| Test | Scenarios |
|---|---|
| `loadFeed` | happy → posts loaded; error → `feedError` set; `hasMore` true when count == page size; `hasMore` false when count < page size |
| `loadMore` | guard: already loading → no-op; guard: `hasMore` false → no-op; happy → appends posts |
| `createPost` | optimistic placeholder inserted at index 0 immediately; success → placeholder replaced with real post; failure → placeholder removed |
| `toggleLike` — scenario 1 | rapid taps → only 1 API call fires after debounce window |
| `toggleLike` — scenario 2 | like → unlike within debounce window → 0 API calls |
| `toggleLike` — scenario 3 | single tap → wait full 500ms → exactly 1 API call |
| `toggleLike` failure | API fails → reverts `isLiked` and `likesCount` to original state |
| `updatePost` | optimistic text update; success → replaced with server response; failure → reverts content and imageUrl |
| `deletePost` | optimistically removed; failure → reinserted at original index |
| `hidePost` | optimistically removed; failure → reinserted at original index |
| `reportPost` | fire-and-forget; error is silent — no state change |
| `loadComments` | cache hit → shows cached immediately, still fetches fresh in background; cache miss → loading spinner → fetch → cached |
| `addComment` | optimistic append + `commentsCount` increment; failure → comment removed + count decremented |
| `deleteComment` | optimistically removed + count decremented; failure → reinserted + count restored |
| `updateComment` | optimistic content update; failure → reverts to old content |
| `loadLikers` | happy → likers list populated; error → silent, empty list |

#### Profile — `UserProfileViewmodel`

| Test | Scenarios |
|---|---|
| `loadProfile` | happy → profile loaded; error → error message set; guard: already loading → no-op |
| `refresh` | success → profile updated; failure → silent, stale profile stays visible |
| `applyLocalProfileEdit` | fields updated immediately in local state; null profile → no-op |
| `toggleFollow` — optimistic | flips `isFollowing` + adjusts follower count instantly |
| `toggleFollow` — debounce | API called after 800ms; rapid toggle back → 0 API calls |
| `toggleFollow` — failure | reverts `isFollowing` and follower count to original |
| `loadUserPosts` | happy → posts loaded; guard: no profile → no-op; guard: already loading → no-op; guard: already loaded → no-op |
| `removePost` | removed from list + `stats.posts` decremented |

#### Profile — `ProfileViewmodel`

| Test | Scenarios |
|---|---|
| `submitProfileSetup` | happy → returns `true`; error → returns `false` + error message set |

### 5.2 Debounce test — three scenarios every time

```
Scenario 1: Rapid taps → only 1 API call fires
Scenario 2: Action → reverse action quickly → 0 API calls fire
Scenario 3: Single action → wait full debounce window → exactly 1 call
```

Use `fake_async` to control time in tests. Never use `Future.delayed` in tests.

### 5.3 Widget test requirements

Test these things per widget:
- Renders without throwing
- Correct widget shown for each state (loading / data / error / empty)
- User interactions trigger the correct ViewModel method

#### Covered widgets

| File | Widget | States tested | Interactions tested |
|---|---|---|---|
| `auth/widgets/auth_screen_test.dart` | `AuthScreen` | idle, loading | Google sign-in tap, Spotify sign-in tap, magic link submit |
| `feed/widgets/post_card_test.dart` | `PostCard` | data, uploading | like tap → `toggleLike`, options tap |
| `profile/widgets/profile_header_test.dart` | `ProfileHeader` | data, loading follow | follow tap → `toggleFollow` |

### 5.4 Integration test requirements

Integration tests test the full slice: **ViewModel → Repository → real Isar (in-memory)**.
No mocking at the repository layer. Use `Isar.openSync` with in-memory path for test isolation.

#### Feed cache integration

File: `test/integration/feed_cache_integration_test.dart`

| Test | What it proves |
|---|---|
| Fresh cache → no API call | Repository returns cached data without hitting datasource |
| Stale cache → API called + cache updated | TTL expiry triggers network fetch and Isar write |
| API failure + stale cache → returns stale data silently | Silent fallback works end-to-end |
| `forceRefresh: true` → bypasses cache | Pull-to-refresh ignores fresh cache |

#### Profile cache integration

File: `test/integration/profile_cache_integration_test.dart`

| Test | What it proves |
|---|---|
| Fresh profile cache → no API call | Same as feed |
| Fresh user posts cache → no API call | User posts TTL works correctly |
| Stale profile → API called + Isar updated | Full refresh path works |
| `forceRefresh: true` on profile → bypasses cache | Profile pull-to-refresh works |

### 5.5 What not to test
- Models (pure data, nothing to test)
- Routing logic
- Third-party packages

---

## 6. Pre-Commit Checklist

Run all of these before every commit. All must pass.

```bash
# Generate mocks and Isar schemas
dart run build_runner build --delete-conflicting-outputs

# Format
dart format lib/

# Analyze — must return zero issues
flutter analyze

# Tests — must all pass
flutter test

# Scan for hardcoded colors
grep -rn "Color(0x" lib/
grep -rn "Colors\." lib/

# Scan for business logic in UI layer
grep -rn "supabase\." lib/features/**/presentation/
grep -rn "http\." lib/features/**/presentation/
grep -rn "SharedPreferences" lib/features/**/presentation/
grep -rn "Timer(" lib/features/**/presentation/
```

Any grep hit in the UI layer is a blocker. Fix before committing.

---

## 7. What an AI Agent Must Never Do

- Put any logic in a screen or widget file
- Use hardcoded color values anywhere
- Use raw string literals in `Text()` widgets
- Call Supabase or HTTP from a ViewModel
- Call Supabase or HTTP from a screen
- Import `package:flutter/material.dart` in a ViewModel or Repository
- Use `setState` in a screen that has a ViewModel
- Create a controller without a matching `dispose()` call
- Write tests before caching is implemented
- Skip the optimistic UI pattern for any mutation
- Skip the debounce pattern for any rapid-fire user action
- Skip integration tests — they are required for cache behaviour verification
- Use `mocktail` — this project uses `mockito` with code generation
- Use `Future.delayed` in tests — use `fake_async` instead
- Touch Isar directly from a ViewModel or screen
- Define an Isar schema without a `cachedAt` field
- Hardcode TTL values outside of the repository — TTL is a repository concern
