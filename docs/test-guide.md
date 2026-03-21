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
5. Write tests           →  unit tests first, then widget tests
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

---

## 5. Testing Rules

### What to test

| Test type | What | When |
|---|---|---|
| Unit test | ViewModel logic, debounce, optimistic UI, cache behaviour | After step 4 (caching done) |
| Widget test | Key UI components, happy path only | After unit tests pass |
| Integration test | Skip — not required for this project | — |

### Unit test requirements

Every ViewModel must have unit tests covering:
- Happy path (success response)
- Error path (API failure → correct error state)
- Optimistic UI (UI updates before API, reverts on failure)
- Debounce (rapid calls → single API call, cancel → zero calls)
- Cache hit (no API call when cache is fresh)
- Cache miss (API called when cache is stale)

### Debounce test — three scenarios every time

```
Scenario 1: Rapid taps → only 1 API call fires
Scenario 2: Action → reverse action quickly → 0 API calls fire
Scenario 3: Single action → wait full debounce window → exactly 1 call
```

Use `fake_async` to control time in tests. Never use `Future.delayed` in tests.

### Widget test requirements

Test these things per widget:
- Renders without throwing
- Correct widget shown for each state (loading / data / error / empty)
- User interactions trigger the correct ViewModel method

### What not to test
- Models (pure data, nothing to test)
- Routing logic
- Third-party packages

---

## 6. Pre-Commit Checklist

Run all of these before every commit. All must pass.

```bash
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
- Add integration tests (not required, wastes time)