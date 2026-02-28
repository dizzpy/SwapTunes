# SwapTunes — System Architecture
> Full overview of how all layers of the system connect and communicate.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MOBILE CLIENT                                │
│                    Flutter (iOS & Android)                          │
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐   │
│  │  UI Layer│  │  State   │  │ Services │  │  Supabase Client │   │
│  │(Widgets) │  │(Riverpod/│  │  Layer   │  │   (Realtime +    │   │
│  │          │  │  Bloc)   │  │(API calls│  │    Auth SDK)     │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────────────┘   │
└───────────────────────────┬────────────────────────┬───────────────┘
                            │ REST (HTTPS)           │ WebSocket
                            │                        │ (Realtime)
           ┌────────────────▼───────────┐   ┌────────▼────────────────┐
           │      EXPRESS BACKEND       │   │     SUPABASE REALTIME   │
           │    Node.js + Express.js    │   │  (Postgres CDC / WSS)   │
           │                            │   │                         │
           │  ┌────────────────────┐    │   │  • messages channel     │
           │  │   Route Handlers   │    │   │  • notifications channel│
           │  │   Middleware       │    │   │  • conversations channel │
           │  │   Controllers      │    │   └─────────────────────────┘
           │  │   Services         │    │
           │  └────────┬───────────┘    │
           │           │                │
           │  ┌────────▼───────────┐    │
           │  │  Supabase Client   │    │
           │  │   (supabase-js)    │    │
           │  └────────┬───────────┘    │
           └───────────┼────────────────┘
                       │
           ┌───────────▼─────────────────────────────┐
           │              SUPABASE                    │
           │                                          │
           │  ┌─────────────┐   ┌──────────────────┐ │
           │  │  PostgreSQL  │   │   Supabase Auth  │ │
           │  │  (Database) │   │ (Google/Spotify/ │ │
           │  │             │   │   Magic Link)    │ │
           │  └─────────────┘   └──────────────────┘ │
           │                                          │
           │  ┌─────────────┐   ┌──────────────────┐ │
           │  │  Storage    │   │   Row Level      │ │
           │  │  (avatars,  │   │   Security (RLS) │ │
           │  │  post-imgs) │   │                  │ │
           │  └─────────────┘   └──────────────────┘ │
           └──────────────────────────────────────────┘
                       │
           ┌───────────▼──────────────────┐
           │         SPOTIFY API          │
           │  (Read-only playlist access) │
           └──────────────────────────────┘
```

---

## Layer Breakdown

### 1. Mobile Client (Flutter)
| Layer | Responsibility |
|-------|---------------|
| **UI Layer** | Screens, widgets, navigation |
| **State Management** | Riverpod or Bloc for app state |
| **Service Layer** | HTTP calls to Express backend (`dio` or `http` package) |
| **Supabase Flutter SDK** | Auth sign-in, Realtime subscriptions |

The Flutter app communicates with **two endpoints**:
- The **Express backend** for all business logic (REST)
- **Supabase directly** for Auth and Realtime only

---

### 2. Express Backend (Node.js)
| Layer | Responsibility |
|-------|---------------|
| **Routes** | Define API paths and map to controllers |
| **Middleware** | JWT validation, creator-guard, owner-guard, error handler |
| **Controllers** | Request/response handling, input validation |
| **Services** | Business logic (e.g. feed algorithm, notification creation) |
| **Supabase Client** | DB reads/writes via `@supabase/supabase-js` |

The backend is the **single source of business logic**. It validates all requests, enforces permissions, and writes to the database.

---

### 3. Supabase
| Feature | Used For |
|---------|---------|
| **PostgreSQL** | Primary database for all app data |
| **Supabase Auth** | Google OAuth, Spotify OAuth, Magic Link |
| **Realtime** | Live messaging and notification push |
| **Storage** | Avatar images, post images |
| **RLS (Row Level Security)** | Data access control at DB level |

---

### 4. Spotify API
| Usage | Notes |
|-------|-------|
| OAuth sign-in | Users can sign in via Spotify |
| Read playlists | Fetch user's Spotify playlists for import |
| **Never writes** | SwapTunes never posts to Spotify |

OAuth tokens (access + refresh) are stored in `users.spotify_access_token` and `users.spotify_refresh_token`. The Express backend handles token refresh automatically.

---

## Communication Protocols

| Connection | Protocol | Notes |
|------------|----------|-------|
| Flutter → Express | HTTPS REST | All business logic |
| Flutter → Supabase Auth | HTTPS | Login/logout only |
| Flutter → Supabase Realtime | WSS (WebSocket Secure) | Live messages + notifications |
| Express → Supabase DB | HTTPS (supabase-js) | All DB reads/writes |
| Express → Spotify API | HTTPS | Playlist fetch, token refresh |

---

## Auth Flow Architecture

```
Flutter App
    │
    ├─► [Google OAuth]    ──► Supabase Auth ──► returns JWT
    ├─► [Spotify OAuth]   ──► Supabase Auth ──► returns JWT
    └─► [Magic Link]      ──► Supabase Auth ──► returns JWT
                                   │
                                   ▼
                         Flutter stores JWT
                                   │
                                   ▼
                    All API calls to Express backend
                    include: Authorization: Bearer <JWT>
                                   │
                                   ▼
                    Express middleware verifies JWT
                    with Supabase Auth SDK
                                   │
                                   ▼
                    Request proceeds with authenticated user ID
```

---

## Realtime Architecture

```
User A sends message
        │
        ▼
Flutter → POST /conversations/:id/messages → Express
        │
        ▼
Express inserts message row into Supabase `messages` table
        │
        ▼
Supabase detects INSERT via Postgres CDC (Change Data Capture)
        │
        ▼
Supabase broadcasts change on channel:
   "messages:conversation_id=eq.<convId>"
        │
        ▼
User B's Flutter app (subscribed to channel) receives event
        │
        ▼
New message appears in User B's chat screen instantly
```

---

## Notification Architecture

```
Action occurs (like, comment, follow, collab, message)
        │
        ▼
Express Controller handles the action
        │
        ▼
Express NotificationService.create({
  user_id: recipient,
  actor_id: current user,
  type: 'like' | 'comment' | 'follow' | 'collab' | 'message',
  reference_id: post/collab/conversation id
})
        │
        ▼
Row inserted into `notifications` table in Supabase
        │
        ▼
Supabase Realtime broadcasts on:
   "notifications:user_id=eq.<recipientId>"
        │
        ▼
Recipient Flutter app receives event
        │
        ▼
Bell icon badge count increments in real time
```

---

## Deployment Overview

| Service | Suggested Platform |
|---------|-------------------|
| Express Backend | Railway / Render / Fly.io |
| Supabase | Supabase Cloud (managed) |
| Mobile App | App Store (iOS) + Google Play (Android) |
| Environment Variables | `.env` file — never committed to git |

### Required Environment Variables (Backend)
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxxxx
SPOTIFY_CLIENT_ID=xxxxx
SPOTIFY_CLIENT_SECRET=xxxxx
PORT=3000
NODE_ENV=production
```
