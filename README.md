# SwapTunes

A music-centric social platform for listeners and creators — share your taste, discover new music, and find your next collab.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Node.js](https://img.shields.io/badge/Node.js-20-339933?logo=node.js)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## What is SwapTunes?

SwapTunes is a mobile app (iOS & Android) where music lovers connect through what they listen to. Listeners import their Spotify playlists, share posts, and discover others with similar taste. Creators — artists, producers, songwriters, engineers — use the Collab Marketplace to find collaborators and grow their network.

---

## Features

- **Social Feed** — Post, like, comment, and discover music from people you follow
- **Spotify Integration** — Import playlists and connect your music identity
- **Creator Mode** — Opt-in creator profile with specializations and portfolio links
- **Collab Marketplace** — Browse and post collaboration opportunities by role and genre
- **Direct Messaging** — Real-time 1:1 messaging powered by Supabase Realtime
- **Discovery** — Search by genre, explore creators, get personalized suggestions
- **Auth** — Google OAuth, Spotify OAuth, and Magic Link sign-in

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter (Dart) |
| Backend | Node.js + Express.js |
| Database | Supabase (PostgreSQL + RLS) |
| Auth | Supabase Auth |
| Real-time | Supabase Realtime |
| Storage | Supabase Storage + Uploadthing |
| Music API | Spotify Web API |
| Local Cache | Isar (Flutter) |
| State | Provider |
| Container | Docker |

---

## Monorepo Structure

```
swaptunes-mono/
├── frontend/          # Flutter app (iOS & Android)
│   └── lib/
│       └── features/  # auth, feed, discover, collab, messaging, profile ...
├── backend/           # Node.js + Express API
│   └── src/
│       ├── features/  # collabs, posts, users, messaging, notifications ...
│       └── shared/    # middleware, validators, events, jobs, utils
├── supabase/          # Migrations and local Supabase config
├── docs/              # Architecture, schema, API reference
└── docker-compose.yml
```

---

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) SDK
- [Node.js](https://nodejs.org/) 20+
- [Supabase](https://supabase.com/) project
- [Spotify Developer](https://developer.spotify.com/) app (for Spotify features)

---

### Backend

```bash
cd backend
cp .env.example .env   # fill in your Supabase + Spotify credentials
npm install
npm run dev            # starts with hot-reload on :3000
```

Or with Docker:

```bash
docker-compose up
```

**Required env vars (`backend/.env`):**

```env
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
SPOTIFY_CLIENT_ID=
SPOTIFY_CLIENT_SECRET=
PORT=3000
NODE_ENV=development
```

---

### Frontend

```bash
cd frontend
cp .env.example .env   # fill in your Supabase credentials
flutter pub get
flutter run
```

**Required env vars (`frontend/.env`):**

```env
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_REDIRECT_SCHEME=
SUPABASE_REDIRECT_URL=
SPOTIFY_CLIENT_ID=
SPOTIFY_CONNECT_REDIRECT_URI=
```

---

### Database

Migrations are in `supabase/migrations/`. Apply them via the Supabase dashboard or CLI:

```bash
supabase db push
```

---

## API

Base URL: `/api/v1`

| Route group | Description |
|---|---|
| `/auth` | Profile setup, Spotify connect |
| `/users` | Profiles, follow, followers/following |
| `/posts` | Feed, create, like, comment, report |
| `/collabs` | Collaboration marketplace |
| `/conversations` | Direct messaging |
| `/discover` | Search and suggestions |
| `/notifications` | User notifications |
| `/health` | Health check |

Full API reference: [docs/API.md](docs/API.md)

---

## Docs

- [Architecture](docs/ARCHITECTURE.md)
- [Database Schema](docs/SCHEMA.md)
- [Flutter conventions](docs/FLUTTER_RULES.md)

---

## License

[MIT](LICENSE) © 2026 dizzpy
