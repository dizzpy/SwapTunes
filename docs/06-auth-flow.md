# SwapTunes — Auth & Onboarding Flow
> Covers: first-time registration, returning login, Spotify connect, and Creator setup flow.

---

## Auth Methods

| Method | Provider | Notes |
|--------|----------|-------|
| Google OAuth | Supabase Auth | Standard Google sign-in |
| Spotify OAuth | Supabase Auth | Sign in + optional Spotify data access |
| Magic Link | Supabase Auth | Email passwordless login |

> Supabase Auth handles all three. After auth, Supabase returns a **JWT** which Flutter stores and sends with every API request.

---

## Flow 1 — First-Time User (New Account)

```
┌─────────────────────────────────────────────────────────────┐
│                      ONBOARDING                             │
│                                                             │
│   [Screen 1] ──► [Screen 2] ──► [Screen 3 + CTA Button]   │
└────────────────────────────┬────────────────────────────────┘
                             │ User taps CTA
                             ▼
                   ┌──────────────────┐
                   │   AUTH POPUP     │
                   │                  │
                   │ • Google         │
                   │ • Spotify        │
                   │ • Magic Link     │
                   └────────┬─────────┘
                            │ User picks method
                            ▼
                  Supabase Auth sign-in
                            │
                            ▼
                 JWT returned to Flutter
                            │
                            ▼
               Check: does public.users row exist?
                            │
                    ┌───────┴───────┐
                    │ NO (new user) │
                    └───────┬───────┘
                            ▼
              ┌─────────────────────────┐
              │    PROFILE SETUP PAGE   │
              │                         │
              │  • Full Name            │
              │  • Username (@handle)   │
              │  • Bio                  │
              │  • Profile Photo        │
              │  • Genre selection      │
              │    (min 3 required)     │
              └────────────┬────────────┘
                           │ POST /auth/profile/setup
                           ▼
              ┌─────────────────────────┐
              │  CONNECT SPOTIFY PAGE   │
              │                         │
              │  ┌─────────────────┐    │
              │  │ Connect Spotify │    │──► Spotify OAuth → tokens stored
              │  └─────────────────┘    │    POST /auth/spotify/connect
              │  ┌─────────────────┐    │
              │  │  Skip for Now   │    │──► Skips, can connect later
              │  └─────────────────┘    │
              └────────────┬────────────┘
                           ▼
              ┌─────────────────────────┐
              │   WELCOME / SUCCESS     │
              │                         │
              │  "You're in!            │
              │   Let's turn your       │
              │   playlists into        │
              │   connections."         │
              │                         │
              │  [ Continue ]           │
              └────────────┬────────────┘
                           ▼
                  LISTENER HOME PAGE
                  (4-tab bottom nav)
```

---

## Flow 2 — Returning User (Has Account)

```
App opens
    │
    ▼
Check for stored JWT (Flutter secure storage)
    │
    ├─► JWT exists + valid ──► LISTENER HOME PAGE (skip auth entirely)
    │
    └─► No JWT / expired
            │
            ▼
        ONBOARDING (or direct to Auth Popup if already seen onboarding)
            │
            ▼
        AUTH POPUP ──► sign in ──► JWT stored ──► HOME PAGE
```

---

## Flow 3 — Connect Spotify Later

If user skipped Spotify during onboarding, they can connect later from:
- **Discover Page** → tap `+` (Create Playlist) → prompted to connect
- **Profile Page** → Settings → Connected Accounts

```
User taps + on Discover
    │
    ▼
spotify_connected = false?
    │
    ├─► YES (not connected) ──► Show "Connect Spotify" prompt
    │                                   │
    │                                   ▼
    │                         Spotify OAuth flow
    │                                   │
    │                                   ▼
    │                         POST /auth/spotify/connect
    │                                   │
    │                                   ▼
    │                         Show Import Playlist Screen
    │
    └─► NO (already connected) ──► Go straight to Import Playlist Screen
```

---

## Flow 4 — Creator Setup Flow

Triggered from own Profile page → "Become a Creator" button.

```
OWN PROFILE PAGE
    │
    └─► Tap "Become a Creator"
              │
              ▼
    ┌──────────────────────────┐
    │  BECOME A CREATOR SCREEN │
    │                          │
    │  Benefits shown:         │
    │  • Post Collab Opps      │
    │  • Creator Badge         │
    │  • Engage with listeners │
    │  • Find artists          │
    │                          │
    │  [ Continue to Setup ]   │
    └──────────┬───────────────┘
               │
               ▼
    ┌──────────────────────────┐
    │   CREATOR SETUP PAGE     │
    │                          │
    │  • Role/Title            │
    │  • Location              │
    │  • Specializations       │
    │    (genre chips)         │
    │  • SoundCloud URL        │
    │  • YouTube URL           │
    │  • Portfolio URL         │
    │                          │
    │  [ Complete Setup ]      │
    └──────────┬───────────────┘
               │ POST /creator/setup
               ▼
    users.user_type = 'creator'
    creator_profiles row created
               │
               ▼
    CREATOR HOME PAGE
    (5-tab nav: Home, Discover, Collab, Inbox, Profile)
```

---

## Token Management

### Supabase JWT
- Stored in Flutter secure storage (`flutter_secure_storage`)
- Sent as `Authorization: Bearer <token>` on every API call
- Auto-refreshed by Supabase Flutter SDK

### Spotify Tokens
- Stored in `users.spotify_access_token` and `users.spotify_refresh_token`
- Express backend refreshes the access token when expired before calling Spotify API
- Tokens are encrypted at rest in Supabase

---

## State After Each Step

| Step | `users` row | `creator_profiles` | `user_type` | `spotify_connected` |
|------|------------|-------------------|-------------|-------------------|
| Auth only (before setup) | ❌ | ❌ | — | false |
| After profile setup | ✅ | ❌ | `listener` | false |
| After Spotify connect | ✅ | ❌ | `listener` | true |
| After creator setup | ✅ | ✅ | `creator` | true/false |
