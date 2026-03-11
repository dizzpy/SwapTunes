# SwapTunes — Data Flow Diagrams
> How data moves through the app for each major feature.  
> Format: Flutter → Express → Supabase → (Realtime back to Flutter)

---

## 1. Home Feed Load

```
User opens Home Page
        │
        ▼
Flutter: GET /posts/feed?limit=20
        │
        ▼
Express posts.service.getFeed(userId, cursor)
        │
        ├─► Query follows table: get list of following_ids
        │
        ├─► Query posts WHERE user_id IN (following_ids)
        │         ORDER BY created_at DESC
        │         LIMIT 20
        │
        ├─► Exclude posts in hidden_posts for this user
        │
        ├─► For each post: check if current user liked it (post_likes)
        │
        └─► Return posts array with pagination cursor
                │
                ▼
        Flutter renders feed
```

---

## 2. Like a Post

```
User taps ❤️ on a post
        │
        ▼
Flutter: POST /posts/:postId/like
        │
        ▼
Express posts.controller → posts.service.likePost(userId, postId)
        │
        ├─► INSERT into post_likes (post_id, user_id)
        │         [UNIQUE constraint prevents double-like]
        │
        ├─► UPDATE posts SET likes_count = likes_count + 1
        │         WHERE id = postId
        │
        └─► notifications.service.create({
                user_id: post.user_id,   ← post owner
                actor_id: userId,        ← who liked
                type: 'like',
                reference_id: postId
            })
                │
                ▼
        Supabase INSERT into notifications table
                │
                ▼
        Realtime broadcasts to post owner's notification channel
                │
                ▼
        Post owner's bell badge increments in real time
```

---

## 3. Send a Message

```
User types message and taps Send
        │
        ▼
Flutter: POST /conversations/:convId/messages
        body: { content: "Hey!" }
        │
        ▼
Express conversations.service.sendMessage(senderId, convId, content)
        │
        ├─► INSERT into messages (conversation_id, sender_id, content)
        │
        ├─► UPDATE conversations SET last_message_at = now()
        │         WHERE id = convId
        │
        └─► notifications.service.create({
                user_id: recipientId,
                actor_id: senderId,
                type: 'message',
                reference_id: convId
            })
                │
                ▼
        Supabase INSERT triggers Realtime CDC
                │
         ┌──────┴──────┐
         ▼             ▼
  Recipient's    Inbox channel
  chat channel   UPDATE fires
  INSERT fires   (re-sort list)
         │
         ▼
  Recipient sees message
  instantly + bell badge
```

---

## 4. Import Spotify Playlist

```
User taps + on Discover → selects playlists → taps Import
        │
        ▼
Flutter: POST /playlists/import
        body: { spotify_playlist_ids: ["37i9dQ...", "2YRe7H..."] }
        Authorization: Bearer <JWT>
        │
        ▼
Express playlists.controller → playlists.service.importPlaylists()
        │
        ├─► Check: user.spotify_connected = true
        │
        ├─► Fetch stored spotify_access_token from users table
        │
        ├─► Check if token expired → if yes, call Spotify /token refresh endpoint
        │         store new access_token in users table
        │
        ├─► For each spotify_playlist_id:
        │     GET https://api.spotify.com/v1/playlists/:id
        │     Extract: name, description, cover_image, track_count, is_public
        │
        └─► INSERT each playlist into playlists table
                (UPSERT on spotify_playlist_id to prevent duplicates)
                │
                ▼
        Return imported playlists to Flutter
                │
                ▼
        Playlists appear on user's profile Playlists tab
```

---

## 5. Post a Collaboration

```
Creator taps + on Collab Page → fills form → taps Create
        │
        ▼
Flutter: POST /collabs
        body: {
          title: "Need Mixing & Mastering",
          description: "...",
          looking_for: ["Mixing", "Mastering"],
          genre_style: ["R&B"],
          payment_type: "paid"
        }
        │
        ▼
Express collabs.controller
        │
        ├─► Middleware: requireAuth + requireCreator
        │         (403 if user_type != 'creator')
        │
        └─► collabs.service.createCollab(creatorId, body)
                │
                ▼
        INSERT into collaborations table
                │
                ▼
        Collab appears in /collabs feed for all creators
        Collab appears in creator's own profile Collabs tab
```

---

## 6. Start a Conversation from Collab

```
Creator views a Collab → taps "Start Conversation"
        │
        ▼
Flutter: POST /conversations
        body: {
          user_id: collab.creator_id,
          collab_id: collab.id
        }
        │
        ▼
Express conversations.service.getOrCreate(userOneId, userTwoId, collabId)
        │
        ├─► Check: does conversation exist between these two users?
        │     SELECT * FROM conversations
        │     WHERE (user_one_id = A AND user_two_id = B)
        │        OR (user_one_id = B AND user_two_id = A)
        │
        ├─► If exists: return existing conversation
        │
        └─► If not: INSERT new conversation with collab_id reference
                │
                ▼
        Flutter navigates to Chat Messaging Page
        for that conversation
```

---

## 7. Follow a User

```
User taps Follow on someone's profile
        │
        ▼
Flutter: POST /users/:userId/follow
        │
        ▼
Express users.service.follow(followerId, followingId)
        │
        ├─► INSERT into follows (follower_id, following_id)
        │         [UNIQUE constraint prevents duplicate follows]
        │         [CHECK constraint prevents self-follow]
        │
        └─► notifications.service.create({
                user_id: followingId,   ← person being followed
                actor_id: followerId,   ← person who followed
                type: 'follow',
                reference_id: followerId
            })
                │
                ▼
        Followed user receives real-time notification
        Their followers count increments
```

---

## 8. Search

```
User types in search bar on Discover → Search Page
        │
        ▼
Flutter: GET /discover/search?q=skrillex&type=all
        │
        ▼
Express discover.service.search(query, type)
        │
        ├─► type = 'users' or 'all':
        │     SELECT * FROM users
        │     WHERE username ILIKE '%skrillex%'
        │        OR full_name ILIKE '%skrillex%'
        │     LIMIT 20
        │
        ├─► type = 'playlists' or 'all':
        │     SELECT * FROM playlists
        │     WHERE name ILIKE '%skrillex%'
        │        OR description ILIKE '%skrillex%'
        │     LIMIT 20
        │
        ├─► type = 'creators' or 'all':
        │     SELECT users.*, creator_profiles.*
        │     FROM users JOIN creator_profiles ON users.id = creator_profiles.user_id
        │     WHERE users.username ILIKE '%skrillex%'
        │        OR creator_profiles.role_title ILIKE '%skrillex%'
        │     LIMIT 20
        │
        └─► Return combined results object
                │
                ▼
        Flutter renders results in Search Page tabs
```

---

## 9. Switch Tab (Listener → Creator view)

```
User completes Creator Setup
        │
        ▼
Express: users.user_type = 'creator'
         creator_profiles row created
        │
        ▼
Flutter receives updated user object
        │
        ▼
State management detects user_type = 'creator'
        │
        ▼
Bottom navigation bar re-renders with 5 tabs:
  Home | Discover | Collab | Inbox | Profile
        │
        ▼
Creator features unlocked throughout app
```
