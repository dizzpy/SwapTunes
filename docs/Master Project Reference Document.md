> **Purpose:** This is the canonical reference for the SwapTunes product and codebase. It is intended for AI coding agents, developers, and academic documentation workflows. The content below reflects implemented behavior in this repository as of April 2026.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Tech Stack](#2-tech-stack)
3. [User Types](#3-user-types)
4. [App Architecture Summary](#4-app-architecture-summary)
5. [Auth and Onboarding Flow](#5-auth-and-onboarding-flow)
6. [Listener Mode - Screens and Features](#6-listener-mode---screens-and-features)
7. [Creator Mode - Screens and Features](#7-creator-mode---screens-and-features)
8. [Shared Screens and Features](#8-shared-screens-and-features)
9. [User Flow Diagrams (Text)](#9-user-flow-diagrams-text)
10. [Navigation Structure](#10-navigation-structure)
11. [Key Integrations](#11-key-integrations)
12. [Terminology Glossary](#12-terminology-glossary)
13. [Current Project Status](#13-current-project-status)

---

## 1. Project Overview

**App Name:** SwapTunes

**Platform:** Flutter mobile app (iOS and Android)

**Concept:** SwapTunes is a music social app for listeners and creators. Users share posts, import and publish playlists, discover people with similar taste, message each other, and (for creators) use a collaboration marketplace.

**Core Value Propositions:**

- Listeners can post, follow, discover playlists/people, and chat.
- Creators get an extended profile and a collab marketplace workflow.
- Spotify connect/import supports music identity and playlist sharing.
- Direct messaging is real-time enabled via Supabase channels.
- Notification flows cover social and collaboration actions.

---

## 2. Tech Stack

| Layer              | Technology (Implemented)                                         |
| ------------------ | ---------------------------------------------------------------- |
| Mobile Frontend    | Flutter (Dart)                                                   |
| Frontend State     | Provider (ChangeNotifier pattern)                                |
| Backend            | Node.js + Express 5                                              |
| Database           | Supabase PostgreSQL                                              |
| Auth               | Supabase Auth (Google OAuth, Spotify OAuth, email OTP)           |
| Music Integration  | Spotify Web API (read-only for playlist/profile data)            |
| Realtime           | Supabase Realtime (messaging + inbox/notification sync patterns) |
| Push Notifications | OneSignal                                                        |
| File Uploads       | Multer + Uploadthing                                             |
| Local Cache        | Isar (frontend), SharedPreferences                               |
| Validation         | Zod (backend request/env validation)                             |
| Logging/Security   | Pino, Helmet, CORS, express-rate-limit, compression              |

**Important implementation notes:**

- The production data layer is Supabase/PostgreSQL (no MongoDB implementation in this repo).
- The app code is Flutter; there is no Swift client implementation in this repo.
- Backend runs behind `/api/v1` with route modules for auth, users, posts, discover, playlists, creator, collabs, conversations, notifications, uploads, health, and dev (non-production).

---

## 3. User Types

SwapTunes uses two runtime user modes from `users.user_type`:

### 3.1 Listener

- Default mode after signup.
- Bottom nav has 4 tabs: Home, Discover, Inbox, Profile.
- Can create/interact with posts, browse discover content, import/manage playlists, follow users, and message.
- Can upgrade to Creator from own profile.

### 3.2 Creator

- Elevated mode enabled by creator setup flow.
- Bottom nav expands to 5 tabs by adding Collab.
- Gets creator profile metadata (role, specializations, links, location).
- Can create, edit, delete, and browse collaborations.
- Can deactivate back to Listener mode.

---

## 4. App Architecture Summary

### 4.1 Frontend Architecture

- Entry point initializes dotenv, OneSignal, Supabase auth service, storage, API client/interceptor, and Isar.
- Auth status listener at app root drives navigation:
  - unauthenticated -> onboarding
  - authenticated without profile -> profile setup
  - profileLoaded -> main layout
- Main layout uses nested navigators per tab and dynamically remaps tab indices when user mode switches listener <-> creator.

### 4.2 Backend Architecture

- Express app middleware stack: Helmet, CORS, JSON parser, compression, Pino HTTP logger, global rate limiter.
- Feature-first route/controller/service structure.
- Centralized error middleware returns structured error payloads.
- Background jobs initialize at boot (Spotify token refresh job).

### 4.3 Data Model Highlights

Core tables implemented include:

- users, user_genres, creator_profiles
- posts, post_likes, comments, post_reports, hidden_posts
- follows
- playlists, playlist_likes
- collaborations
- conversations, messages
- notifications

---

## 5. Auth and Onboarding Flow

### 5.1 Onboarding

- Three-page onboarding carousel.
- CTA on last page opens auth bottom sheet.

### 5.2 Authentication Methods

- Google OAuth
- Spotify OAuth
- Email OTP (passwordless code flow)

### 5.3 New User Setup

1. Profile setup

- Avatar
- Full name
- Username
- Bio
- Genre selection (minimum 3)

2. Connect Spotify (optional)

- Connect via external OAuth browser flow and callback
- Skip available

3. Welcome success screen

- Continue to main app

### 5.4 Returning User

- Existing session/profile goes directly to main layout.

### 5.5 Backend Auth Endpoints

- `POST /api/v1/auth/profile/setup`
- `POST /api/v1/auth/spotify/connect`
- `GET /api/v1/auth/me`

---

## 6. Listener Mode - Screens and Features

### 6.1 Home (Feed)

- Feed timeline with pull-to-refresh and pagination.
- Post input entry point and create/edit/delete post flows.
- Post interactions:
  - Like/unlike
  - Comment list/add/edit/delete
  - Report post
  - Hide post
- Notification icon with unread badge and navigation to notification screen.

Backend endpoints used include:

- `GET /api/v1/posts/feed`
- `POST /api/v1/posts`
- `PATCH /api/v1/posts/:postId`
- `DELETE /api/v1/posts/:postId`
- `POST|DELETE /api/v1/posts/:postId/like`
- `POST /api/v1/posts/:postId/report`
- `POST /api/v1/posts/:postId/hide`
- `GET|POST /api/v1/posts/:postId/comments`
- `PATCH|DELETE /api/v1/posts/:postId/comments/:commentId`

### 6.2 Discover

- Browse genres
- Featured playlists
- Suggested users with follow/unfollow actions
- Search screen with filters supported by backend types:
  - all
  - users
  - playlists
  - creators
- Add playlist action supports:
  - Spotify import flow
  - Manual playlist creation/editing

Backend endpoints used include:

- `GET /api/v1/discover/genres`
- `GET /api/v1/discover/playlists`
- `GET /api/v1/discover/users`
- `GET /api/v1/discover/trending`
- `GET /api/v1/discover/search`
- `GET /api/v1/playlists/spotify/available`
- `POST /api/v1/playlists/import`
- `POST /api/v1/playlists/create`
- `GET|PATCH|DELETE /api/v1/playlists/:playlistId`
- `POST|DELETE /api/v1/playlists/:playlistId/like`

### 6.3 Inbox (Messaging)

- Conversation list with unread counts and delete conversation action.
- Single chat with:
  - optimistic send
  - retry failed sends
  - read receipts
  - soft-delete with undo window
  - realtime subscription and reconnect gap-fill behavior
- Isar cache strategy (stale-while-revalidate) for conversations and messages.

Backend endpoints used include:

- `GET|POST /api/v1/conversations`
- `GET|POST /api/v1/conversations/:conversationId/messages`
- `PATCH /api/v1/conversations/:conversationId/read`
- `DELETE /api/v1/conversations/:conversationId/messages/:messageId`
- `DELETE /api/v1/conversations/:conversationId`

### 6.4 Profile (Own)

- Profile header (avatar + cover interactions)
- Edit profile screen and inline bio editing
- Follows sheets
- Content tabs:
  - Listener: Posts, Playlists
- Settings access
- Become Creator action

### 6.5 Profile (Other Users)

- Public profile view
- Follow/unfollow
- Message
- If target is creator, collaborative action entry point

---

## 7. Creator Mode - Screens and Features

### 7.1 Become Creator

- Intro screen describing creator benefits.
- Continue to setup.

### 7.2 Creator Setup

Fields include:

- role/title
- location
- specializations (multi-select)
- external links (SoundCloud, YouTube, Spotify artist, Apple Music, portfolio)

Backend endpoints:

- `POST /api/v1/creator/setup`
- `PATCH /api/v1/creator/profile`

### 7.3 Creator Deactivation

- Confirmed transition flow back to listener mode with dedicated transition screen.

Backend endpoint:

- `POST /api/v1/creator/deactivate`

### 7.4 Collab Tab (Creator Only)

- Filtered collab feed (All, Vocalist, Producer, Mixing, Mastering, Songwriter, Instrumentalist)
- Collab details screen
- Manage collaborations screen
- New collaboration creation flow

Backend endpoints:

- `GET /api/v1/collabs`
- `GET /api/v1/collabs/me`
- `GET /api/v1/collabs/:collabId`
- `POST|PATCH|DELETE /api/v1/collabs/:collabId` (create uses `/api/v1/collabs`)

### 7.5 Creator Profile Differences

- Profile tabs become: Posts, Collabs, Songs (Songs tab is currently UI-level/placeholder style in parts of the app).
- Creator stats include collab-related visibility and creator metadata sections.

---

## 8. Shared Screens and Features

### 8.1 Notifications

- Notification list with unread state handling.
- Mark read, mark all read, and delete supported via API.

Backend endpoints:

- `GET /api/v1/notifications`
- `PATCH /api/v1/notifications/read-all`
- `PATCH /api/v1/notifications/:notificationId/read`
- `DELETE /api/v1/notifications/:notificationId`

### 8.2 Settings

- Notification preference toggles (push/activity/message/collab)
- OneSignal opt-in/opt-out integration
- Account/logout actions
- Additional settings entries include some placeholders marked coming soon in UI

### 8.3 Uploads

- Image upload endpoint with MIME/type and size constraints (10 MB max)
- Backend stores via Uploadthing and returns hosted URL

Backend endpoint:

- `POST /api/v1/uploads/image`

### 8.4 Health and Dev

- Health route for service checks
- Dev routes available only outside production

Backend endpoints:

- `GET /api/v1/health`
- `GET /api/v1/health/detailed`
- `/api/v1/dev/*` (non-production)

---

## 9. User Flow Diagrams (Text)

### 9.1 Auth Flow

```text
START
  -> Splash
    -> Onboarding
      -> Auth sheet (Google / Spotify / Email OTP)
        -> Authenticated?
          -> no: remain in auth flow
          -> yes: profile exists?
            -> no: Profile Setup -> Connect Spotify (optional) -> Welcome -> Main Layout
            -> yes: Main Layout
```

### 9.2 Listener to Creator Flow

```text
Own Profile
  -> Become a Creator
    -> Creator Setup
      -> Submit
        -> Creator Success
          -> Main Layout (Collab tab appears)
```

### 9.3 Creator to Listener Flow

```text
Own Profile (Creator)
  -> Switch to Listener (confirm)
    -> Transition screen
      -> POST /creator/deactivate
        -> Main Layout remaps to listener tabs
```

### 9.4 Messaging Flow

```text
Inbox list
  -> Open conversation
    -> Load cached messages (if available)
    -> Refresh from API
    -> Realtime subscribe for inserts/updates
    -> Send/retry/delete/undo actions
```

---

## 10. Navigation Structure

### 10.1 Bottom Navigation

| Tab      | Listener | Creator |
| -------- | -------- | ------- |
| Home     | Yes      | Yes     |
| Discover | Yes      | Yes     |
| Collab   | No       | Yes     |
| Inbox    | Yes      | Yes     |
| Profile  | Yes      | Yes     |

### 10.2 Major Screens

- Splash
- Onboarding
- Auth
- Profile setup
- Connect Spotify
- Welcome success
- Main layout tabs and nested tab navigators

### 10.3 Dynamic Tab Behavior

- Main layout updates indices when switching between listener and creator modes to avoid navigation state loss.

---

## 11. Key Integrations

### 11.1 Supabase

- Auth provider and session lifecycle
- PostgreSQL data storage
- Realtime subscriptions (messaging and related live updates)

### 11.2 Spotify

- OAuth sign-in and connect flows
- Read-only fetch/import of playlists
- Access token refresh handled in backend job/service logic

### 11.3 OneSignal

- Frontend initialization and user alias login/logout
- Backend push send service for social events (like/comment/follow/message/collab)
- Fail-safe design: push failure does not block in-app notification writes

### 11.4 Uploadthing

- Backend image upload pipeline for user-generated image assets

### 11.5 Isar and Shared Preferences

- Conversation/message cache and local preference storage

### 11.6 Deep Links

- OAuth and connect callbacks handled through app link listener at app root

---

## 12. Terminology Glossary

| Term                   | Definition                                                           |
| ---------------------- | -------------------------------------------------------------------- |
| Listener               | Default user mode with social/discovery/messaging features           |
| Creator                | Elevated mode with collab marketplace and enriched profile           |
| Collab                 | A creator collaboration listing (role/genre/payment descriptors)     |
| Feed                   | Home timeline of posts and interactions                              |
| Discover               | Genre, playlist, user suggestion, and search surfaces                |
| OTP                    | Email one-time password login code                                   |
| Profile Setup          | First-time post-auth user profile creation flow                      |
| Connect Spotify        | OAuth flow to attach Spotify and enable playlist import              |
| Realtime               | Supabase channel subscriptions for live updates                      |
| Stale-While-Revalidate | UX pattern that shows cached data instantly, then refreshes from API |

---

## 13. Current Project Status

### 13.1 Backend Status

**Completed and operational:**

- Full Express API module set under `/api/v1`
- Auth/profile setup, creator upgrade/deactivation, social graph, feed CRUD/interactions
- Playlist import/manual management + playlist likes
- Collab marketplace CRUD
- Conversations/messages APIs + read/delete flows
- Notifications API + push integration service
- Upload pipeline (Multer + Uploadthing)
- Health endpoints, structured logging, rate limiting, compression, environment validation, global error handling
- Background Spotify token refresh job initialization

### 13.2 Frontend Status

**Substantially implemented and integrated with backend:**

- Auth and onboarding flows wired to Supabase + backend profile setup
- Main listener/creator tab shell implemented with dynamic mode switching
- Feed, discover, messaging, profile, creator setup, collab, notifications, settings screens present and connected
- Realtime messaging and local caching strategy implemented
- OneSignal initialization and user/device auth hooks integrated

### 13.3 Remaining Work Focus (Polish/Release Readiness)

- UI/UX polish and consistency passes across some secondary/edge screens
- Validation of all edge-case error states and recovery paths
- Broader automated test coverage and release QA hardening
- Final production rollout checklist alignment

---

_Document Version: 1.2_  
_Last Updated: April 2026_  
_Project: SwapTunes - Music Social Networking App_
