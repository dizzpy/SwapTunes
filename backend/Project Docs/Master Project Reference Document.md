

> **Purpose:** This document is the single source of truth for the SwapTunes project. It is intended to be fed into AI coding agents, LLMs, and used as the foundation for generating university/academic documentation. Anyone (human or AI) reading this document should gain a complete understanding of the app — what it is, how it works, every screen, every feature, and every user flow.

---

## Table of Contents

1. [Project Overview](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#1-project-overview)
2. [Tech Stack](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#2-tech-stack)
3. [User Types](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#3-user-types)
4. [App Architecture Summary](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#4-app-architecture-summary)
5. [Auth & Onboarding Flow](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#5-auth--onboarding-flow)
6. [Listener Mode — All Screens & Features](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#6-listener-mode--all-screens--features)
7. [Creator Mode — All Screens & Features](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#7-creator-mode--all-screens--features)
8. [Shared Screens & Features](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#8-shared-screens--features)
9. [User Flow Diagrams (Text)](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#9-user-flow-diagrams-text)
10. [Navigation Structure](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#10-navigation-structure)
11. [Key Integrations](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#11-key-integrations)
12. [Terminology Glossary](https://claude.ai/chat/fb0beb1c-5d3a-4a59-8053-5a986baebd28#12-terminology-glossary)

---

## 1. Project Overview

**App Name:** SwapTunes

**Platform:** Mobile App (iOS & Android)

**Concept:** SwapTunes is a music-centric social networking platform that connects music listeners and music creators. It allows users to share their music taste via Spotify playlist imports, discover new music through a community feed, and enables artists, producers, and other music creators to find and collaborate with each other.

**Core Value Propositions:**

- Listeners can share playlists, follow creators, and discover music through a social feed.
- Creators (artists, producers, songwriters, etc.) get a dedicated profile mode with collaboration tools to find other creators for projects.
- Spotify integration allows seamless playlist importing and music identity sharing.
- A built-in messaging system allows direct communication between users.
- A Collab marketplace lets creators post and find collaboration opportunities (e.g., "Need a mixing engineer", "Looking for vocalist for R&B track").

**Target Users:**

- Music listeners who want to share taste and discover new music socially.
- Independent artists, producers, songwriters, mixing engineers, and other music creators who want to network and collaborate.

---

## 2. Tech Stack

|Layer|Technology|
|---|---|
|Mobile Frontend|Flutter (primary) or Swift (iOS)|
|Backend|Node.js with Express.js (REST API)|
|Database|Supabase (PostgreSQL) or MongoDB|
|Authentication|Google OAuth, Spotify OAuth, Magic Link|
|Music Integration|Spotify API (playlist import, read-only)|
|Real-time (Messaging)|Supabase Realtime or WebSockets via Node.js|

**Notes for AI agents:**

- The frontend is Flutter (Dart). All UI screens described in this document map to Flutter widgets/pages.
- The backend exposes REST API endpoints consumed by the Flutter app.
- Spotify integration is read-only: SwapTunes reads playlists and music data but never posts to Spotify on behalf of the user without explicit consent.
- The database schema will need tables for: `users`, `creators`, `posts`, `playlists`, `collaborations`, `messages`, `conversations`, `follows`, `likes`, `comments`, `notifications`, `genres`.

---

## 3. User Types

SwapTunes has two distinct user modes. A user starts as a **Listener** and can optionally upgrade to a **Creator**.

### 3.1 Listener

- Default account type after registration.
- Can browse the home feed, discover playlists, follow creators and other listeners, send messages, and interact with posts (like, comment, report/hide).
- Can import Spotify playlists to their profile.
- Does NOT have access to the Collab page or Creator-specific features.
- Can switch to Creator mode from their own Profile page.

### 3.2 Creator

- An elevated account mode that a Listener opts into.
- Has all Listener features PLUS:
    - A dedicated **Collab** tab in the bottom navigation bar.
    - A **Creator Profile** with additional fields: role/title, specialization genres, portfolio & external links (SoundCloud, YouTube, Apple Music, Spotify).
    - Ability to post, browse, and manage **Collaborations**.
    - A **"Collaborate"** button visible on their public profile for others to initiate collabs.
    - Creator badge on their profile.
    - Stat display includes "Collabs" count in addition to followers, following, and posts.

---

## 4. App Architecture Summary

The app has two navigation structures depending on user type:

### Listener Bottom Navigation (4 tabs):

1. Home
2. Discover
3. Inbox
4. Profile

### Creator Bottom Navigation (5 tabs):

1. Home
2. Discover
3. Collab _(new tab, only for creators)_
4. Inbox
5. Profile

All screens are mobile-first. Dark theme with green (`#1DB954` Spotify-green inspired) as the primary accent color.

---

## 5. Auth & Onboarding Flow

### 5.1 Onboarding Screens (3 screens)

- Three introductory onboarding slides that introduce the app's value proposition to new users.
- The 3rd onboarding screen contains a **call-to-action button** that opens the **Auth Popup/Modal**.

### 5.2 Auth Screen (Popup Modal)

Triggered from the 3rd onboarding screen. Contains three sign-in/sign-up options:

|Option|Description|
|---|---|
|Continue with Google|Standard Google OAuth sign-in|
|Continue with Spotify|Spotify OAuth sign-in; imports user identity|
|Continue with Magic Link|Email-based passwordless authentication|

### 5.3 New User Flow (has no account)

After authenticating for the first time, new users go through:

1. **Profile Setup Page**
    
    - Upload profile photo
    - Enter Full Name
    - Enter Username (`@username`)
    - Write a Bio ("Tell us about your vibe...")
    - Select music genres they listen to (multi-select chips): Classical, Dubstep, Country, Jazz, Pop, Indie, Electronic, Gospel, etc. (Pick 3+)
2. **Connect Spotify Page**
    
    - Prompts the user to connect their Spotify account.
    - Explains: "Import your playlists and share your music taste."
    - Privacy note: "We only read your playlists. We never post anything without asking."
    - Two actions:
        - **Connect Spotify Account** (green CTA button)
        - **Skip for Now** (secondary button — user can connect later)
3. **Registration Success / Welcome Page**
    
    - Confirmation screen with message: _"You're in! Let's turn your playlists into connections."_
    - Single **Continue** button that takes the user to the Home Page.

### 5.4 Returning User Flow (has account)

- After authenticating, goes directly to the **Listener Home Page**.

### 5.5 Auth Flow Summary

```
Start
  → Onboarding (3 screens)
    → Auth Screen (Popup)
      → Has Account? 
          YES → Home Page (Listener)
          NO  → Profile Setup → Connect Spotify → Welcome Page → Home Page (Listener)
```

---

## 6. Listener Mode — All Screens & Features

### 6.1 Home Page

**App Bar (Top):**

- Left: Hamburger menu icon → opens Drawer (settings, account options)
- Right: Bell icon → opens Notifications page

**Create Post Bar:**

- Profile avatar + "What's on your mind?" text input
- Camera/image icon to attach media

**Feed (Scrollable):**

- Displays posts from followed users and suggested content
- Each post card contains:
    - User avatar, username, verified badge (if creator), timestamp
    - 3-dot overflow menu (top right of post)
    - Post content (text and/or image)
    - Caption/description text
    - Action bar: ❤️ Like count | 💬 Comment count

**Post Interactions:**

- **Like:** Tap heart icon to like/unlike
- **Comment (PopUp):** Opens a comment sheet/modal showing all comments and a text input to add a new comment
- **3-dot Menu (Post Options — Dialog Box):**
    - Report post
    - Hide post

### 6.2 Discover Page

**App Bar:**

- Right: `+` (Create/Publish Playlist) icon and 🔍 (Search) icon

**Browse by Genre Section:**

- Horizontal scrollable genre chips: Hip-Hop, Jazz, Rock, Classical, Reggae, etc.
- "See All" link to view all genres

**Future Playlists Section:**

- Horizontally scrollable playlist cards
- Each card shows: playlist cover image, playlist name, short description
- "See More" link

**Suggested for You Section:**

- Suggested creator/user cards with Follow button
- Each card shows avatar, name, genre/role tag

**Search Page** (accessed via 🔍 icon):

- Search bar at top
- Filter tabs: All | Users | Playlists | Creators | Albums
- **Recent Searches** section with clear all option
- **Trending** hashtag chips: #SummerVibes, #Collaboration, #Now, etc.
- Results populate dynamically based on query and selected filter tab

**Create / Publish Playlist** (accessed via `+` icon):

- If Spotify is not connected: prompts user to connect Spotify account
- If Spotify is connected: shows **Import Playlist Screen**
    - Displays "Connected as @username" with green indicator
    - Lists all available Spotify playlists (e.g., "All the Stars — 31 tracks — Public/Private")
    - User selects playlist(s) to import
    - **Import Playlist** button to confirm

### 6.3 Inbox (Messaging)

**Chat Home Page:**

- Search bar: "Search chat"
- Conversations list: each item shows avatar, name, last message preview, timestamp, unread message count badge

**Chat Messaging Page (Single Conversation):**

- App bar: back arrow, user avatar, name, online status, 3-dot menu
- Message bubbles (sent = right/green, received = left/dark)
- Message input bar at bottom with send button
- Date separators between messages ("Last week", "Today")

### 6.4 Profile Page (Listener — Own)

**Header:**

- Cover/banner image
- Profile avatar (overlapping banner)
- Username, display name, verified badge (if applicable)
- Bio text
- Genre/interest hashtags (e.g., #dubstep, #techno, #trap)
- Role tags (e.g., Producer/Engineer)
- External links (SoundCloud, Spotify, YouTube, Apple Music) — shown as popup when tapped

**Stats Row:**

- Followers | Following | Posts | Playlists
- Tapping Followers/Following opens a popup showing the list

**Action Buttons (Own Profile):**

- **Edit Profile** (PopUp modal to edit name, bio, genres, photo)
- **Become a Creator** button → triggers Creator Setup Flow

**Content Tabs:**

- Posts tab
- Playlists tab

### 6.5 Profile Page (Listener — Public / Others)

Same layout as own profile but action buttons change to:

- **Follow** button
- **Message** button

---

## 7. Creator Mode — All Screens & Features

### 7.1 Become a Creator Screen

- Accessed from own Profile page via "Become a Creator" button
- Full-screen prompt with message: _"Ready to Become a Creator? Join the community of artists and start building your music network today."_
- Lists benefits:
    - Post Collaboration Opportunities
    - Creator Badge
    - Engage with listeners
    - Find artists for your next track
- **Continue to Setup** button → leads to Creator Setup Page
- Back button (top left)

### 7.2 Creator Setup Page

- **Professional Information:**
    - Your Role/Title field (e.g., "Music Producer")
    - Location field (e.g., "Homagama, Sri Lanka")
- **Specialization** (multi-select genre chips): Hip-Hop, Jazz, Rock, Classical, Reggae, Electronic, etc.
- **Portfolio & Links:**
    - SoundCloud Link field
    - YouTube Link field
    - Portfolio Link field
- **Complete Setup** button (primary CTA)

### 7.3 Import Playlist Screen (Creator)

- Same as Listener import flow but accessible during Creator setup or from Discover
- Shows "Connected as @username" confirmation
- Lists available Spotify playlists with track count and public/private status
- Multi-select capability
- **Import Playlist** button

### 7.4 Creator Home Page

- Same as Listener Home Page
- Bottom nav now has 5 tabs: Home | Discover | **Collab** | Inbox | Profile

### 7.5 Creator Discover Page

- Same as Listener Discover Page

### 7.6 Collab Page (Creator Only)

**Collab Home Page:**

- Filter tabs at top: All | Vocalist | Producer | Mixing | Mastering | (more)
- Lists collaboration posts from other creators
- Each collab card shows:
    - Creator avatar, name, role, timestamp
    - Collab title (e.g., "Need Mixing & Mastering")
    - Short description/preview
    - Genre hashtags
    - **View Details** button
    - **Message** button

**Collab Details Page:**

- Back button + 3-dot overflow menu
- Creator info: avatar, name, follow button, timestamp
- Collab title
- Tags: #Collab, #Remont, #Mixing + "Become Brave" badge
- Full description text
- "I'm Looking for" section with role chips
- Genre/Style tags
- **Start Conversation** button (CTA)

**Create New Collab (PopUp Modal):**

- "What are you looking for?" text input
- Description textarea: "Tell potential collaborators about your project, style and goals"
- **I'm Looking For** multi-select role chips: Vocalist, Producer, Mixing, Mastering, Songwriter, Instrumentalist
- **Genre/Style** multi-select chips: Jazz, Rock, Classical, Electronic
- **Payment Type** dropdown/toggle: Paid Project | Revenue Share | For Fun/Experience
- **+ Create New Collab** button
- **Start Conversation About This** button (to immediately message about the collab)

**Manage Collaborations Page:**

- Lists all collabs the creator has posted
- Each item shows: title, posted date/time
- Action buttons per collab: **View** | **Edit** | **Delete**

### 7.7 Creator Profile Page (Own)

Same as Listener own profile PLUS:

- Stats row includes **Collabs** count: Followers | Following | Collabs | Posts | Songs
- Content tabs: **Posts** | **Collabs** | **Songs**
- No "Become a Creator" button (already a creator)
- Edit Profile available

### 7.8 Creator Profile Page (Public / Others)

- Same as Listener public profile PLUS:
- **Collaborate** button (in addition to Follow and Message)
- Collab count in stats
- Posts | Collabs | Songs tabs visible
- "Need Mixing Engineer" collab post visible at bottom

### 7.9 Platform Links Popup

- Triggered when tapping external links on a creator's profile
- Shows linked platforms:
    - SoundCloud: soundcloud.com/dizzpysanchez
    - Spotify: spotify.com/dizzpysanchez
    - YouTube: soundcloud.com/dizzpysanchez
    - Apple Music: applemusic.com/dizzpysanchez

---

## 8. Shared Screens & Features

### 8.1 Settings Page

- Accessible via Drawer (hamburger menu) from Home Page
- Contains account settings, preferences, notification settings, connected accounts (Spotify), privacy, logout

### 8.2 Notifications Page

- Accessible via bell icon in Home Page app bar
- Lists activity notifications: new followers, likes, comments, collab requests, messages

### 8.3 Drawer (Side Menu)

- Accessible from hamburger menu icon on Home Page
- Contains navigation links to Settings and other utility pages

### 8.4 Stats Popup (Followers/Following)

- Triggered by tapping the follower or following count on any profile
- Shows a popup/modal list of followers or following users
- Each entry shows avatar, name, follow/unfollow button

### 8.5 Edit Profile (PopUp)

- Accessible from own Profile page
- Fields: profile photo, name, username, bio, genre tags
- Save / Cancel actions

---

## 9. User Flow Diagrams (Text)

### 9.1 Auth Flow

```
START
  └─► Onboarding Screen 1
        └─► Onboarding Screen 2
              └─► Onboarding Screen 3 [CTA Button]
                    └─► Auth Popup
                          ├─► [Has Account] ──────────────────────────────► Listener Home Page
                          └─► [No Account]
                                └─► Profile Setup Page
                                      └─► Connect Spotify Page
                                            ├─► [Connect Spotify] ──► Welcome Page ──► Listener Home Page
                                            └─► [Skip for Now]   ──► Welcome Page ──► Listener Home Page
```

### 9.2 Creator Setup Flow

```
Listener Own Profile Page
  └─► "Become a Creator" button
        └─► Become a Creator Screen
              └─► Continue to Setup
                    └─► Creator Setup Page
                          └─► Complete Setup
                                └─► Creator Home Page (5-tab nav)
```

### 9.3 Listener Flow (Post-Auth)

```
IS AUTHENTICATED
  ├─► HOME PAGE
  │     └─► Scroll Feed
  │           ├─► Create New Post (PopUp)
  │           ├─► Comments (PopUp)
  │           └─► Post Options: Report / Hide (Dialog Box)
  │
  ├─► DISCOVER PAGE
  │     ├─► Explore Playlists by Genre
  │     ├─► Search Page (🔍) — search users, playlists, creators, albums
  │     └─► Create Playlist (+)
  │           └─► Import from Spotify
  │
  ├─► INBOX
  │     └─► Chat Home Page
  │           └─► Single Chat Screen
  │                 └─► Chat Options (PopUp)
  │
  └─► PROFILE PAGE
        ├─► Own Profile
        │     ├─► Edit Profile (PopUp)
        │     └─► Become a Creator ──► Creator Setup Flow
        └─► Others' Public Profile
              └─► Stats Popup (followers/following count)
```

### 9.4 Creator Flow (Post-Auth)

```
IS AUTHENTICATED (CREATOR)
  ├─► HOME PAGE         [same as Listener]
  ├─► DISCOVER PAGE     [same as Listener]
  │
  ├─► COLLAB PAGE
  │     └─► Collab Home Page
  │           ├─► Create New / Manage Collabs (PopUp)
  │           │     ├─► Manage Collabs (view/edit/delete)
  │           │     └─► Create New Collab
  │           └─► View Single Collab Details
  │
  ├─► INBOX             [same as Listener]
  │
  └─► PROFILE PAGE
        ├─► Own Profile (Creator)
        │     └─► Edit Profile (PopUp)
        └─► Others' Public Profile (Creator)
              └─► Stats Popup (followers/following count)
```

---

## 10. Navigation Structure

### Bottom Navigation Bar

|Tab|Listener|Creator|Icon|
|---|---|---|---|
|Home|✅|✅|House icon|
|Discover|✅|✅|Compass/grid icon|
|Collab|❌|✅|Handshake/people icon|
|Inbox|✅|✅|Chat bubble icon|
|Profile|✅|✅|Person icon|

### App Bar (Home Page)

- Left: Drawer/hamburger menu
- Right: Notifications bell

### App Bar (Discover Page)

- Right: `+` Create Playlist, 🔍 Search

---

## 11. Key Integrations

### 11.1 Spotify Integration

- **Auth:** Users can sign in via Spotify OAuth
- **Playlist Import:** Read-only access to user's Spotify playlists
- **Trigger points:**
    - During onboarding (Connect Spotify screen)
    - From Discover page (`+` button) if not yet connected
    - During Creator Setup (Import Playlist Screen)
- **Permissions:** Read-only. SwapTunes never posts to Spotify.
- **Data used:** Playlist names, track counts, public/private status, playlist cover art

### 11.2 Google OAuth

- Standard sign-in via Google account
- Used for authentication only

### 11.3 Magic Link Auth

- Email-based passwordless login
- User enters email, receives a login link

---

## 12. Terminology Glossary

|Term|Definition|
|---|---|
|Listener|Default user type; can browse, follow, post, and message|
|Creator|Elevated user mode with collaboration and creator profile features|
|Collab|A collaboration opportunity posted by a Creator seeking other music professionals|
|Feed|The scrollable home page stream of posts from followed and suggested users|
|Playlist|A Spotify playlist imported into SwapTunes and shared on the user's profile|
|Magic Link|A passwordless email authentication method|
|PopUp / Modal|A sheet or dialog that appears over the current screen without full navigation|
|Dialog Box|A small confirmation or options dialog (e.g., Report / Hide post)|
|Creator Badge|A verified-style badge shown on creator profiles and posts|
|Collab Marketplace|The Collab page where creators post and browse collaboration opportunities|
|Import Playlist|The process of connecting Spotify and pulling playlists into SwapTunes|
|Onboarding|The 3-screen introductory flow shown to first-time app users|

---

_Document Version: 1.0 — Generated from UI designs, flow diagrams, and project specification._ _Last Updated: February 2026_ _Project: SwapTunes — Music Social Networking App_