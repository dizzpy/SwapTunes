# SwapTunes — Development Sprint Timeline
> Backend-first · Feature-driven sprints · No fixed dates — move at your own pace  
> Track legend: 🟢 Backend · 🔵 Frontend · 🟣 Full-Stack · 🟠 Infra/Config

---

## Sprint Overview

| Sprint | Name | Track | Depends On |
|--------|------|-------|------------|
| 00 | Project Setup & Infrastructure | 🟠 Infra | — |
| 01 | Auth & User Accounts | 🟢 Backend | 00 |
| 02 | Posts & Social Feed | 🟢 Backend | 01 |
| 03 | Spotify Integration & Playlists | 🟢 Backend | 01 |
| 04 | Creator Mode | 🟢 Backend | 01 |
| 05 | Collaborations | 🟢 Backend | 04 |
| 06 | Messaging & Realtime | 🟣 Full-Stack | 01 |
| 07 | Discover & Search | 🟢 Backend | 02, 03, 04 |
| 08 | Notifications | 🟣 Full-Stack | 02, 05, 06 |
| 09 | Flutter — Auth & Onboarding | 🔵 Frontend | 08 (BE done) |
| 10 | Flutter — Core Listener Screens | 🔵 Frontend | 09 |
| 11 | Flutter — Creator Mode & Collabs | 🔵 Frontend | 10 |
| 12 | Flutter — Chat, Realtime & Notifications | 🔵 Frontend | 10 |
| 13 | Polish, Testing & Launch Prep | 🟣 Full-Stack | 12 |

---

## SPRINT 00 — Project Setup & Infrastructure
🟠 **Track:** Infra/Config  
**Goal:** Get the entire dev environment ready before writing a single feature. This sprint is the foundation everything else runs on.

### Tasks
  - [x] Init Node.js + Express project — folder structure, core deps (express, cors, helmet, dotenv), nodemon
- [ ] Set up Supabase project — create project, save URL + keys in .env, init supabase-js client, enable Realtime
- [ ] Run all DB migrations — create all 14 tables with enums, indexes, constraints, foreign keys
- [ ] Configure Supabase Auth providers — enable Google OAuth, Spotify OAuth, Magic Link, add redirect URLs
- [ ] Set up Supabase Storage buckets — `avatars` and `post-images` buckets with public read policies
- [ ] Enable RLS on all tables — turn on Row Level Security, write base policies per schema doc
- [x] Set up global error handler + response utils — errorHandler.js middleware + response.js helper
- [x] Init Git repo + .env.example — .gitignore (node_modules, .env), push initial structure to GitHub

### ✅ Sprint Deliverable
Running Express server connected to Supabase. All DB tables exist. Auth providers configured. Ready to build features.

---

## SPRINT 01 — Auth & User Accounts
🟢 **Track:** Backend  
**Depends on:** Sprint 00  
**Goal:** Build the full auth middleware and user profile system. Every other sprint depends on this being solid.

### Tasks
- [x] `requireAuth` middleware — verify Supabase JWT, attach user to req.user, return 401 if invalid
- [x] `POST /auth/profile/setup` — create users row after first sign-in, validate full_name + username uniqueness + min 3 genres, insert user_genres
- [x] `GET /users/me` — return full authenticated user profile with genres, stats, creator_profile if applicable
- [ ] `PATCH /users/me` — update own profile (name, bio, avatar, genres), update user_genres atomically
- [x] `GET /users/:username` — public profile by username with stats, genres, creator_profile, is_following flag
- [x] `POST + DELETE /users/:id/follow` — follow/unfollow, handle UNIQUE conflict, prevent self-follow, return updated count
- [ ] `GET /users/:id/followers + /following` — paginated lists with is_following flag per user

### ✅ Sprint Deliverable
Full auth system working. Can sign up, set up profile, view and edit profiles, follow/unfollow users. All endpoints tested in Postman/Bruno.

---

## SPRINT 02 — Posts & Social Feed
🟢 **Track:** Backend  
**Depends on:** Sprint 01  
**Goal:** Build the core social layer — creating posts, the home feed algorithm, likes, comments, and moderation (report/hide).

### Tasks
- [x] `POST /posts` — create post with content + optional image_url
- [ ] `DELETE /posts/:id` — delete own post with requireOwner middleware
- [x] `GET /posts/feed` — cursor-paginated feed from followed users, exclude hidden posts, include is_liked flag
- [x] `POST + DELETE /posts/:id/like` — like/unlike with UNIQUE guard, increment/decrement likes_count, trigger like notification
- [x] `GET + POST /posts/:id/comments` — paginated comments + add comment, increment comments_count, trigger comment notification
- [x] `POST /posts/:id/report` — insert into post_reports, one report per user per post
- [x] `POST /posts/:id/hide` — insert into hidden_posts, per-user only, UNIQUE constraint
- [x] `notifications.service` — build shared `NotificationService.create()` helper, wire to like + comment

### ✅ Sprint Deliverable
Full social feed working. Users can post, like, comment, report, and hide. Feed returns followed users' posts with pagination.

---

## SPRINT 03 — Spotify Integration & Playlists
🟢 **Track:** Backend  
**Depends on:** Sprint 01  
**Goal:** Connect Spotify API — store tokens, refresh them, fetch playlists, and import them into the SwapTunes DB.

### Tasks
- [x] `POST /auth/spotify/connect` — receive Spotify OAuth tokens from Flutter, store in users table, set spotify_connected = true
- [x] `spotify.service` — token refresh logic using stored refresh_token, call Spotify /token endpoint, save new access_token
- [x] `requireSpotify` middleware — guard for playlist endpoints, returns 403 if Spotify not connected
- [x] `GET /playlists/spotify/available` — fetch user's Spotify playlists via Spotify Web API, auto-refresh token if expired
- [x] `POST /playlists/import` — accept array of spotify_playlist_ids, fetch from Spotify, UPSERT into playlists table
- [ ] `GET /playlists/user/:userId` — return public playlists for any user
- [ ] `DELETE /playlists/:id` — remove imported playlist from profile, requireOwner guard

### ✅ Sprint Deliverable
Full Spotify flow working. User can connect Spotify, fetch their playlists, import them to their profile. Tokens auto-refresh silently.

---

## SPRINT 04 — Creator Mode
🟢 **Track:** Backend  
**Depends on:** Sprint 01  
**Goal:** Build the creator account upgrade flow — switching user type, saving creator profiles, exposing creator-specific data on profiles.

### Tasks
- [x] `requireCreator` middleware — checks user_type === 'creator', returns 403 with clear message
- [x] `POST /creator/setup` — atomically update users.user_type = 'creator' AND insert creator_profiles row
- [ ] `PATCH /creator/profile` — update any creator profile field, all optional, partial updates
- [x] Update `GET /users/me` + `GET /users/:username` — include creator_profile data, collabs count in stats, platform links

### ✅ Sprint Deliverable
Creator mode fully functional. User can switch to creator, fill in creator profile. API correctly distinguishes listener vs creator in all responses.

---

## SPRINT 05 — Collaborations
🟢 **Track:** Backend  
**Depends on:** Sprint 04  
**Goal:** Build the full Collab marketplace — create, browse, filter, view, edit, and delete collaboration posts. Creator only.

### Tasks
- [x] `POST /collabs` — create collab post with requireCreator guard, validate title + description + looking_for + payment_type
- [x] `GET /collabs` — paginated open collabs with role/genre/payment_type filters + creator info, cursor pagination
- [ ] `GET /collabs/me` — all collabs posted by current user for manage view
- [x] `GET /collabs/:id` — full collab details with creator's public profile
- [x] `PATCH /collabs/:id` — edit own collab with requireOwner guard, partial updates, support status open/closed
- [x] `DELETE /collabs/:id` — delete own collab, requireOwner guard, cascades to conversations (SET NULL)

### ✅ Sprint Deliverable
Full Collab marketplace API complete. Creators can post, browse, filter, edit, and delete collabs. All endpoints tested.

---

## SPRINT 06 — Messaging & Realtime
🟣 **Track:** Full-Stack  
**Depends on:** Sprint 01  
**Goal:** Build the DM system with REST for history/init and Supabase Realtime for live delivery. Most technically complex sprint.

### Tasks
- [x] `POST /conversations` — idempotent create-or-get, handle optional collab_id link, UNIQUE constraint handles race conditions
- [x] `GET /conversations` — inbox list sorted by last_message_at DESC, include other user info + last message + unread count
- [x] `POST /conversations/:id/messages` — insert message, update last_message_at, trigger message notification, Realtime fires on INSERT
- [x] `GET /conversations/:id/messages` — paginated history with `before` cursor for older messages
- [ ] `PATCH /conversations/:id/read` — mark all messages as is_read = true, return updated count
- [ ] Enable Realtime on `messages` + `conversations` tables via SQL publication
- [x] Wire message notification in `notifications.service`

### ✅ Sprint Deliverable
Full messaging system working. Messages send via REST, deliver instantly via Realtime. Inbox shows sorted conversations with unread counts.

---

## SPRINT 07 — Discover & Search
🟢 **Track:** Backend  
**Depends on:** Sprints 02, 03, 04  
**Goal:** Build the Discover page API — featured playlists by genre, suggested users, and full search across all content types.

### Tasks
- [x] `GET /discover/playlists` — featured/public playlists with optional genre filter, paginated
- [x] `GET /discover/suggested-users` — users not yet followed, prioritise shared genres, include is_following flag
- [x] `GET /discover/search` (users) — ILIKE search on username + full_name, return user previews with follow status
- [x] `GET /discover/search` (playlists) — ILIKE search on name + description, public playlists only with owner info
- [x] `GET /discover/search` (creators) — JOIN users + creator_profiles, search on username + role_title
- [x] `GET /discover/search?type=all` — run all 3 searches in parallel (Promise.all), return combined results object

### ✅ Sprint Deliverable
Discover API complete. Genre-filtered playlists, user suggestions, and full-text search across users/playlists/creators all working.

---

## SPRINT 08 — Notifications
🟣 **Track:** Full-Stack  
**Depends on:** Sprints 02, 05, 06  
**Goal:** Complete the notification system REST endpoints and wire Realtime delivery of all 5 notification types.

### Tasks
- [ ] Enable Realtime on `notifications` table, verify RLS allows users to receive only their own events
- [x] `GET /notifications` — all notifications DESC with unread_only filter, actor info, reference_id, unread_count in response
- [x] `PATCH /notifications/read-all` — mark all unread as read, return updated count
- [x] Wire follow notification in `users.service` — `NotificationService.create()` on follow
- [x] Wire collab notification in `collabs.service` — fire 'collab' type when conversation started from collab post

### Notification Types Summary
| Type | Triggered By | Recipient |
|------|-------------|-----------|
| `like` | User likes a post | Post owner |
| `comment` | User comments on a post | Post owner |
| `follow` | User follows another | Followed user |
| `collab` | Conversation started on collab | Collab post owner |
| `message` | Message sent | Conversation recipient |

### ✅ Sprint Deliverable
✅ **Backend complete.** All 40+ API endpoints built and tested. Notifications fire for all 5 event types. Realtime works on messages and notifications.

---

## SPRINT 09 — Flutter: Auth & Onboarding
🔵 **Track:** Frontend  
**Depends on:** Sprint 08 (all backend done)  
**Goal:** Build the complete Flutter app foundation and the full auth/onboarding flow from first open to home screen.

### Tasks
- [ ] Flutter project init + add all packages (supabase_flutter, dio, go_router, riverpod, flutter_secure_storage)
- [ ] Theme + design system — app_colors.dart, app_text_styles.dart, dark theme, green #1DB954 primary
- [ ] Supabase init + AuthService — signInWithGoogle, signInWithSpotify, signInWithMagicLink, signOut, JWT storage
- [ ] GoRouter + auth redirect — unauthenticated → /onboarding, authenticated skip onboarding, profile_complete check
- [ ] 3 Onboarding screens — PageView with dot indicator, 3rd screen CTA opens auth bottom sheet
- [ ] Auth popup bottom sheet — 3 options (Google, Spotify, Magic Link), loading states, error handling
- [ ] Profile setup screen — avatar picker, full name, username, bio, genre chips (min 3), call POST /auth/profile/setup
- [ ] Connect Spotify screen + Welcome screen — Spotify OAuth flow, skip option, POST /auth/spotify/connect, Welcome → Home

### ✅ Sprint Deliverable
Full onboarding flow works end-to-end on device. New user can sign up, set up profile, connect Spotify, and land on the home screen.

---

## SPRINT 10 — Flutter: Core Listener Screens
🔵 **Track:** Frontend  
**Depends on:** Sprint 09  
**Goal:** Build all 4 listener tabs: Home feed, Discover, Inbox, and Profile. The main app experience for all users.

### Tasks
- [ ] App shell + dynamic bottom nav — ShellRoute, 4 tabs listener / 5 tabs creator, app bar with drawer + bell icon
- [ ] Home feed screen — infinite scroll, PostCard widget, create post bar, pull-to-refresh
- [ ] Like, Comment, Report/Hide — optimistic like, comments bottom sheet, 3-dot menu with report dialog + hide
- [ ] Create post popup — text input + image picker bottom sheet, call POST /posts, prepend to feed
- [ ] Discover screen — genre chips, featured playlists horizontal scroll, suggested users with Follow button
- [ ] Search screen — search bar + filter tabs, recent searches, trending hashtags, debounced live results
- [ ] Import playlist screen — Spotify connected check, playlist checkboxes, call POST /playlists/import
- [ ] Own profile screen — banner, avatar, stats row, Posts + Playlists tabs, Edit Profile sheet, Become a Creator button
- [ ] Public profile screen — Follow + Message buttons, creator profile extra links popup, stats popup on tap

### ✅ Sprint Deliverable
Full listener experience on device. All 4 tabs working — feed, discover, search, profiles, follow/unfollow complete.

---

## SPRINT 11 — Flutter: Creator Mode & Collabs
🔵 **Track:** Frontend  
**Depends on:** Sprint 10  
**Goal:** Build the creator upgrade flow UI and the full Collab tab — browse, create, view details, and manage collabs.

### Tasks
- [ ] Become a Creator screen — benefits list, Continue to Setup button, dark green design
- [ ] Creator setup screen — role/title, location, specialization chips, external links, call POST /creator/setup, switch to 5-tab nav
- [ ] Collab home screen — filter chips, paginated collab cards, View Details + Message buttons
- [ ] Collab detail screen — creator header with Follow, full collab info, looking_for chips, Start Conversation button
- [ ] Create collab bottom sheet — looking_for, description, role chips, genre chips, payment type toggle, call POST /collabs
- [ ] Manage collabs screen — own collabs list with View/Edit/Delete, edit pre-fills create sheet, delete confirmation dialog
- [ ] Creator profile updates — Collabs count in stats, Posts/Collabs/Songs tabs, Collaborate button, platform links popup

### ✅ Sprint Deliverable
Full creator experience live. Users can switch to creator, browse and post collabs, manage listings. Creator profiles show all extra data.

---

## SPRINT 12 — Flutter: Chat, Realtime & Notifications
🔵 **Track:** Frontend  
**Depends on:** Sprint 10  
**Goal:** Build the Inbox screens and wire Supabase Realtime for live messaging and bell badge notifications.

### Tasks
- [ ] Chat home screen — conversation list sorted by last_message_at, avatar + name + unread badge + last message preview
- [ ] Chat messaging screen — load history, message bubbles (sent right green / received left), date separators, mark read on open
- [ ] Supabase Realtime — messages channel: subscribe on chat open, append new messages instantly, unsubscribe on dispose
- [ ] Supabase Realtime — inbox channel: subscribe on Inbox screen, re-sort list on conversation UPDATE
- [ ] Notifications screen — list with actor avatar, type icon, description, timestamp, mark all read on open, tap to navigate
- [ ] Supabase Realtime — notifications channel: subscribe globally on app start, increment bell badge on INSERT

### ✅ Sprint Deliverable
Live messaging and real-time notifications fully working on device. Messages appear instantly. Bell badge updates in real time. Inbox stays sorted.

---

## SPRINT 13 — Polish, Testing & Launch Prep
🟣 **Track:** Full-Stack  
**Depends on:** Sprint 12  
**Goal:** Fix edge cases, add loading states, test on real devices, and get the app ready for submission or deployment.

### Tasks
- [ ] Loading skeletons + empty states — shimmer on feed/discover/profile/inbox, empty state widgets everywhere
- [ ] Error handling + offline states — network errors, retry buttons, 401 redirect to auth, toast messages
- [ ] Settings screen — account settings, Spotify disconnect, sign out, notification preferences
- [ ] End-to-end testing on device — all major flows on real iOS + Android, fix device-specific bugs
- [ ] Backend deployment — deploy Express to Railway/Render, set env vars, update Flutter API base URL, test against prod
- [ ] Performance pass — cache images, lazy load feed, check N+1 queries, add missing indexes, profile Flutter rebuilds
- [ ] Final documentation update — update README, update master reference doc with any changes, prepare for university submission

### ✅ Sprint Deliverable
🚀 SwapTunes is complete, deployed, and ready. All features working, all edge cases handled, backend live, app tested on real devices.

---

## Dependency Map

```
00 (Infra)
 └──► 01 (Auth)
        ├──► 02 (Posts)
        │      └──► 07 (Discover) ◄── 03, 04
        ├──► 03 (Spotify)
        ├──► 04 (Creator)
        │      └──► 05 (Collabs)
        └──► 06 (Messaging)
                └──► 08 (Notifications) ◄── 02, 05
                       └──► [BACKEND COMPLETE]
                              └──► 09 (Flutter Auth)
                                     └──► 10 (Core Screens)
                                            ├──► 11 (Creator/Collab)
                                            └──► 12 (Chat/Realtime)
                                                   └──► 13 (Polish/Launch)
```

---

## Backend Completion Checklist

Before moving to Flutter (Sprint 09), all of these must be done:

- [ ] All 40+ API endpoints built and returning correct responses
- [ ] All endpoints tested in Postman / Bruno / Thunder Client
- [ ] Supabase Realtime working on messages + notifications tables
- [ ] All 5 notification types firing correctly
- [ ] Spotify token refresh working without manual intervention
- [ ] RLS policies set on all tables
- [ ] Backend deployable (env vars documented in .env.example)
