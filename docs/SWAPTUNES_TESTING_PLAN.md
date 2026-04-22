# SwapTunes — Testing Implementation Plan

> **For Claude Code:** Read this file fully before writing any test. Investigate the existing codebase first, reuse patterns from `test/helpers/mocks.dart` and `test/helpers/fixtures.dart`, and match the architecture already in place.

---

## Current State (as of April 2026)

### Frontend (~40% covered)

Already tested: Auth, Feed, Messaging, Profile — with unit + integration + widget tests.
Infrastructure ready: `test/helpers/mocks.dart`, `test/helpers/fixtures.dart`, Mocktail configured.

### Backend (0% covered)

No framework installed. Clean Controller → Service → Repository → Validator architecture ready to test.

---

## Rules Before Writing Any Test

### Flutter

- ✅ Always mock at the **Repository** layer — never mock the datasource or Supabase directly
- ✅ Reuse existing mocks from `test/helpers/mocks.dart` — add new ones there, never inline
- ✅ Reuse fixtures from `test/helpers/fixtures.dart` — add new factories there
- ✅ Follow AAA pattern: Arrange → Act → Assert
- ✅ ViewModel tests go in `test/unit/<feature>/`
- ✅ Widget tests go in `test/widget/<feature>/`
- ✅ Cache integration tests go in `test/integration/<feature>/`
- ❌ Never test Flutter internals or Provider internals — test your own logic only
- ❌ Never use `sleep()` — use `fake_async` or `pump()` for time-based tests

### Backend

- ✅ Install Jest + Supertest before writing any test: `npm install --save-dev jest supertest`
- ✅ Always mock Supabase at the config level: `jest.mock('../../src/config/supabase.js')` BEFORE importing the service
- ✅ Unit tests mock the repository; integration tests mock Supabase directly
- ✅ Use ES module syntax (`import/export`) — backend uses `"type": "module"`
- ❌ Never hit real Supabase in tests
- ❌ Never import service before mocking its dependencies

---

## Part 1 — Flutter: What to Build Next

### Priority 1 — Unit Tests (ViewModel layer)

These are the highest-value tests for the viva. They prove MVVM architecture is correct.

#### 1a. `test/unit/auth/otp_viewmodel_test.dart`

Test: OTP request flow, OTP verify flow, error states, loading states.

```
- requestOtp(email) → sets isLoading, calls repo, sets success/error state
- verifyOtp(email, otp) → sets isLoading, calls repo, navigates on success
- verifyOtp with wrong OTP → sets errorMessage
- verifyOtp with expired OTP → sets errorMessage
- requestOtp with invalid email → sets validation error without calling repo
```

#### 1b. `test/unit/creator/creator_viewmodel_test.dart`

Test: Creator setup, deactivation, AI song concept generation.

```
- setupCreator(bio, genres) → calls repo, sets isCreator = true
- setupCreator with empty bio → sets errorMessage, never calls repo
- setupCreator with no genres → sets errorMessage
- deactivateCreator() → calls repo, sets isCreator = false
- generateSongConcept(genre, mood, theme) → sets isLoading → calls repo → sets concept
- generateSongConcept API error → sets errorMessage, clears isLoading
- generateSongConcept in Sinhala → passes language param to repo
```

#### 1c. `test/unit/creator/collab_viewmodel_test.dart`

Test: Collab listing creation and AI match fetching.

```
- loadCollabs() → sets isLoading → calls repo → populates collabs list
- createCollab(title, description, roles) → calls repo → adds to list optimistically
- createCollab API error → reverts optimistic add, sets errorMessage
- getAIMatches(collabId) → sets isLoadingMatches → calls repo → populates matches list
- getAIMatches uses cached result if available
- getAIMatches API error → sets errorMessage
```

#### 1d. `test/unit/discover/discover_viewmodel_test.dart`

Test: Search, genre filter, trending load.

```
- loadTrending() → calls repo → populates trendingPlaylists
- search(query) → calls repo → populates searchResults
- search with empty query → clears searchResults, does not call repo
- filterByGenre(genre) → calls repo with genre param
- search debounces rapid calls — only fires once with final query (use fake_async)
- search API error → sets errorMessage, keeps previous results
```

#### 1e. `test/unit/notifications/notifications_viewmodel_test.dart`

Test: Load, mark read, mark all read, delete.

```
- loadNotifications() → calls repo → populates list, sets unreadCount
- markAsRead(id) → calls repo → decrements unreadCount
- markAllAsRead() → calls repo → sets unreadCount = 0
- deleteNotification(id) → calls repo → removes from list
- loadNotifications API error → sets errorMessage
```

---

### Priority 2 — Widget Tests

Test that screens render correctly and react to ViewModel state. Keep these simple — render, find widget, tap, verify state change.

#### 2a. `test/widget/feed/feed_screen_test.dart`

```
- renders CircularProgressIndicator when isLoading = true
- renders list of PostCards when posts are loaded
- renders error message widget when errorMessage is set
- tapping like button calls viewmodel.likePost(postId)
- renders empty state widget when posts list is empty
```

#### 2b. `test/widget/auth/otp_screen_test.dart`

```
- renders email input and submit button
- submit button disabled when email field empty
- shows loading indicator when isLoading = true
- shows error text when errorMessage is set
- navigates to OTP verify screen on success
```

#### 2c. `test/widget/profile/creator_badge_test.dart`

```
- renders creator badge when user.isCreator = true
- does not render creator badge when user.isCreator = false
- creator-only action buttons visible for creator users
- creator-only action buttons hidden for listener users
```

---

### Priority 3 — Integration Tests (Isar cache)

Match the pattern in `test/integration/profile/profile_cache_integration_test.dart` exactly.

#### 3a. `test/integration/feed/feed_cache_integration_test.dart`

```
- first load hits API, writes to Isar cache
- second load within TTL returns cached data without hitting API
- cache invalidated after TTL expires → hits API again
- liking a post updates cached post's likeCount
- hiding a post removes it from cache
```

#### 3b. `test/integration/messaging/messaging_cache_integration_test.dart`

```
- conversation list cached after first load
- new message appended to cached conversation
- read status updated in cache on markAsRead
- cache cleared on conversation delete
```

---

## Part 2 — Backend: Full Setup + Tests

### Step 1 — Install and configure Jest

```bash
cd backend
npm install --save-dev jest supertest
```

Add to `backend/package.json`:

```json
"scripts": {
  "test": "node --experimental-vm-modules node_modules/.bin/jest",
  "test:watch": "node --experimental-vm-modules node_modules/.bin/jest --watch",
  "test:coverage": "node --experimental-vm-modules node_modules/.bin/jest --coverage"
}
```

Create `backend/jest.config.js`:

```javascript
export default {
  testEnvironment: "node",
  transform: {},
  testMatch: ["**/tests/**/*.test.js"],
  collectCoverageFrom: ["src/**/*.js", "!src/server.js", "!src/app.js"],
  coverageThreshold: {
    global: { lines: 50, functions: 50, branches: 50, statements: 50 },
  },
};
```

Create directory structure:

```bash
mkdir -p backend/tests/{unit/services,unit/middleware,integration/routes,helpers}
```

### Step 2 — Create test helpers

**`backend/tests/helpers/supabase-mock.js`**

```javascript
export const createMockSupabaseClient = () => ({
  from: jest.fn().mockReturnValue({
    select: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnThis(),
    update: jest.fn().mockReturnThis(),
    delete: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    in: jest.fn().mockReturnThis(),
    order: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    range: jest.fn().mockReturnThis(),
    single: jest.fn().mockReturnThis(),
    maybeSingle: jest.fn().mockReturnThis(),
  }),
  auth: { admin: { getUserById: jest.fn() } },
  rpc: jest.fn(),
});
```

**`backend/tests/helpers/fixtures.js`**

```javascript
const uid = () => Math.random().toString(36).substr(2, 9);

export const fixtures = {
  user: (o = {}) => ({
    id: `user-${uid()}`,
    username: "testuser",
    full_name: "Test User",
    user_type: "listener",
    created_at: new Date().toISOString(),
    ...o,
  }),
  creator: (o = {}) => ({
    id: `user-${uid()}`,
    username: "creator1",
    user_type: "creator",
    bio: "I make music",
    genres: ["rock"],
    created_at: new Date().toISOString(),
    ...o,
  }),
  post: (o = {}) => ({
    id: `post-${uid()}`,
    user_id: "user-123",
    caption: "Test post",
    genres: ["rock"],
    likes_count: 0,
    comments_count: 0,
    created_at: new Date().toISOString(),
    ...o,
  }),
  comment: (o = {}) => ({
    id: `comment-${uid()}`,
    post_id: "post-123",
    user_id: "user-123",
    text: "Test comment",
    created_at: new Date().toISOString(),
    ...o,
  }),
  conversation: (o = {}) => ({
    id: `conv-${uid()}`,
    created_at: new Date().toISOString(),
    ...o,
  }),
  message: (o = {}) => ({
    id: `msg-${uid()}`,
    conversation_id: "conv-123",
    sender_id: "user-123",
    content: "Test message",
    created_at: new Date().toISOString(),
    read_at: null,
    ...o,
  }),
  collab: (o = {}) => ({
    id: `collab-${uid()}`,
    creator_id: "user-123",
    title: "Looking for vocalist",
    description: "Rock track",
    roles: ["vocalist"],
    created_at: new Date().toISOString(),
    ...o,
  }),
  songConcept: (o = {}) => ({
    title: "Midnight Drive",
    mood: "melancholic",
    genre: "indie",
    bpm_range: "90-110",
    instruments: ["guitar", "piano"],
    structure: "verse-chorus-verse",
    hook: "Sample hook line",
    ...o,
  }),
};
```

**`backend/tests/helpers/test-app.js`**

```javascript
import express from "express";

export const createTestApp = (router, prefix = "/api/v1") => {
  const app = express();
  app.use(express.json());
  app.use(prefix, router);
  app.use((err, req, res, next) => {
    res.status(err.status || 500).json({ error: { message: err.message } });
  });
  return app;
};
```

### Step 3 — Unit tests to write (services)

Investigate the real service files before writing. Match exact function names and signatures.

#### `backend/tests/unit/services/posts.service.test.js`

```
- getFeed(userId, page, limit) → calls repository, returns posts array
- getFeed excludes hidden posts for that user
- createPost(userId, data) → calls repository, returns created post
- createPost with missing caption → throws validation error
- likePost(postId, userId) → inserts like, returns result
- likePost duplicate → throws 'already liked' error
- unlikePost(postId, userId) → deletes like
- addComment(postId, userId, text) → inserts comment, returns it
- addComment with empty text → throws validation error
- reportPost(postId, userId, reason) → inserts report
```

#### `backend/tests/unit/services/ai.service.test.js`

```
- generateCollabMatches(collabId) → calls Gemini, returns array of 5 matches with scores
- generateCollabMatches returns cached result if exists in Supabase
- generateCollabMatches stores new result in cache after generation
- generateSongConcept(genre, mood, theme, language) → calls Gemini, returns concept object
- generateSongConcept with language='si' → includes Sinhala in prompt
- generateSongConcept Gemini error → throws structured error
- getModel() returns 'gemini-3-flash-preview' (not gemini-2.0-flash)
```

#### `backend/tests/unit/services/messaging.service.test.js`

```
- getConversations(userId) → returns conversations with last_message and unread_count (single SQL RPC, not N+1)
- getMessages(conversationId, userId) → returns messages, verifies user is participant
- getMessages by non-participant → throws 403
- sendMessage(conversationId, senderId, content) → inserts message, returns it
- markAsRead(conversationId, userId) → updates read_at for messages
- deleteConversation(conversationId, userId) → soft deletes, verifies ownership
```

#### `backend/tests/unit/middleware/auth.middleware.test.js`

```
- valid JWT → sets req.user, calls next()
- missing Authorization header → returns 401
- malformed token → returns 401
- expired token → returns 401
- valid token with user_type='creator' → sets req.user.user_type correctly
```

#### `backend/tests/unit/middleware/requireCreator.middleware.test.js`

```
- req.user.user_type = 'creator' → calls next()
- req.user.user_type = 'listener' → returns 403
- no req.user → returns 401
```

### Step 4 — Integration tests to write (routes via supertest)

Investigate actual route files and middleware order before writing. Use `createTestApp` helper.

#### `backend/tests/integration/routes/posts.routes.test.js`

```
POST /posts
- 201 with valid auth + data
- 401 without auth header
- 400 with missing caption
- 400 with empty genres array

GET /posts/feed
- 200 with valid auth, returns array
- 401 without auth

POST /posts/:postId/like
- 200 with valid auth
- 401 without auth
- 409 on duplicate like

POST /posts/:postId/comments
- 201 with valid auth + text
- 400 with empty text
- 401 without auth
```

#### `backend/tests/integration/routes/ai.routes.test.js`

```
POST /ai/collab-match
- 200 returns array of 5 matches with matchScore and explanation
- 401 without auth
- 403 for listener role (creator-only)
- 200 returns cached result without calling Gemini again

POST /ai/song-concept
- 200 returns concept with all required fields (title, mood, bpm_range, instruments, structure, hook)
- 200 with language='si' returns Sinhala concept
- 400 with missing genre
- 401 without auth
- 403 for listener role
```

#### `backend/tests/integration/routes/messaging.routes.test.js`

```
GET /conversations
- 200 returns array with last_message and unread_count per conversation
- 401 without auth

POST /conversations/:id/messages
- 201 with valid auth + content
- 403 when sender is not a participant
- 400 with empty content
- 401 without auth

PATCH /conversations/:id/read
- 200 marks messages as read
- 403 for non-participant
```

---

## Part 3 — Test Plan Document (for viva/report)

Create `TEST_PLAN.md` at the project root with:

```markdown
# SwapTunes — Test Plan

## Scope

Covers unit, widget, and integration tests for the Flutter frontend and unit + integration tests for the Node.js backend. E2E tests and Supabase internals are out of scope.

## Test Types

| Type                  | Tool                    | Purpose                               |
| --------------------- | ----------------------- | ------------------------------------- |
| Unit (Flutter)        | flutter_test + mocktail | ViewModel business logic in isolation |
| Widget (Flutter)      | flutter_test            | Screen rendering and UI state         |
| Integration (Flutter) | flutter_test + Isar     | Cache layer behavior                  |
| Unit (Backend)        | Jest                    | Service logic in isolation            |
| Integration (Backend) | Jest + Supertest        | API route contract testing            |

## Coverage Targets

- Flutter ViewModels: 80%+
- Backend Services: 70%+
- Backend Routes: critical paths only (auth, feed, AI, messaging)

## Exclusions

- Spotify OAuth (requires real tokens)
- Supabase Realtime (requires live connection)
- Push notifications (device-dependent)
- E2E (out of time scope for viva)
```

---

## Quick Reference: Run Tests

```bash
# Flutter — all tests
flutter test

# Flutter — one feature
flutter test test/unit/feed/

# Flutter — with coverage
flutter test --coverage

# Backend — all tests
cd backend && npm test

# Backend — coverage
cd backend && npm run test:coverage

# Backend — single file
cd backend && npm test -- ai.service.test.js
```

---

## Viva Talking Points

- "I separated tests by layer — unit tests prove ViewModel logic, widget tests prove UI reactions, integration tests prove the cache layer. Each layer tests a different concern."
- "Backend services are tested in isolation by mocking Supabase at the config level. This means tests are fast and deterministic."
- "The AI service tests verify both fresh generation and cache retrieval paths — this maps directly to the free vs paid user monetization strategy."
- "I deliberately excluded E2E tests because Supabase Realtime requires a live connection and Spotify OAuth requires real credentials — both are non-deterministic in a test environment."
- "The `getConversations` endpoint uses a single SQL RPC with LEFT JOIN LATERAL to avoid the N+1 problem. The unit test for this verifies the RPC is called once, not N times."
