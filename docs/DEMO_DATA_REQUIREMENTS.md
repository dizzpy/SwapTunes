# SwapTunes — Demo Data Requirements (Viva Prep)

This document lists all the **real / seed data** you need to add to the app before
the viva demo, so every screen looks alive instead of empty.

Goal: when the examiner opens any tab (Feed, Discover, Profile, Messages,
Notifications, Collabs, AI), there is realistic content to show.

---

## 0. Accounts to create first

Everything else depends on having users. Create at least **6–8 users** so the feed,
follows and chats look natural. Mix of both types.

| # | Role | Purpose |
|---|------|---------|
| 1 | **listener** | Your main demo account — log in live during viva |
| 2 | listener | A friend the demo account follows / chats with |
| 3 | **creator** | Shows the creator profile + collaborations |
| 4 | creator | Second creator for the Discover / collab list |
| 5 | creator | Owns several playlists |
| 6–8 | mixed | Fill the feed and follower counts |

For each user fill: `full_name`, `username`, `bio`, `avatar_url`, `user_type`,
and a few `user_genres` rows (e.g. `Pop`, `Hip-Hop`, `Lo-fi`).
Creators also need a `creator_profiles` row (`role_title`, `location`,
`specializations`, social URLs).

> Tip: use real-looking avatars (e.g. a profile-image URL) so the UI is not full
> of placeholder icons.

---

## 1. Posts (Feed tab) — `posts`, `post_likes`, `comments`

The feed is the first thing shown. Empty feed = bad demo.

**Add:** ~15–20 posts spread across the 6–8 users.

Per post:
- `content` — real text (a few sentences, varied: announcements, questions, song shares)
- `image_url` — optional, but include images on ~half of them so the feed isn't all text
- `created_at` — **spread the timestamps** over the last few days so ordering looks real

Then add engagement so counters aren't zero:
- `post_likes` — several likes per post (counts must match `likes_count`)
- `comments` — 2–4 comments on the most visible posts (update `comments_count`)

Checklist:
- [ ] 15–20 posts with varied content
- [ ] Images on roughly half
- [ ] Likes + comments on the top posts
- [ ] Timestamps spread over recent days
- [ ] Your demo account has 1–2 of its own posts (to show "My posts" on profile)

---

## 2. Playlists (Discover tab) — `playlists`, `playlist_likes`

Discover shows shared playlists with rich metadata.

**Add:** ~10–12 playlists owned by the creator accounts.

Per playlist:
- `name`, `description`, `cover_image_url`, `track_count`
- `source_platform` (`spotify` / `apple` / `youtube` / `soundcloud` / `other`)
- `primary_url` — a real link so "Open playlist" works in the demo
- `genre_tags`, `mood_tags`, `artists`, `era`, `energy_level`,
  `occasion_tags`, `vocal_style`, `language`
- `is_public = true`

Fill the metadata properly — Discover **filters/searches on these tags**, so the
filter UI looks empty if they're blank.

Then:
- [ ] Add `playlist_likes` so `likes_count` is non-zero
- [ ] Cover images on every playlist (most visible field)
- [ ] At least one Spotify-sourced playlist (matches the Spotify connect feature)

---

## 3. Follows — `follows`

So profiles show real follower / following numbers.

- [ ] Demo account follows 3–5 others
- [ ] Demo account is followed by 3–5 others
- [ ] Creators have higher follower counts than listeners (looks realistic)

---

## 4. Collaborations (Collab tab) — `collaborations`

**Add:** ~5–6 collaboration posts owned by the creator accounts.

Per collab:
- `title`, `description` (real wording)
- `looking_for` (e.g. `Vocalist`, `Producer`, `Mixing Engineer`)
- `genre_style`
- `payment_type` — mix of `paid`, `revenue_share`, `free`
- `status` — mostly `open`, one or two `closed`

Checklist:
- [ ] 5–6 collabs, varied payment types
- [ ] At least one owned by the creator account you'll show in the demo

---

## 5. Messaging (Messages tab) — `conversations`, `messages`

**Add:** 3–4 conversations involving your demo account.

Per conversation:
- Link `user_one_id` / `user_two_id` (one of them = demo account)
- One collab-linked conversation (`collab_id` set) to show that flow
- 5–10 `messages` each, back-and-forth, with spread `created_at`
- Set `last_message_at` on the conversation to the latest message time
- Leave a few incoming messages `is_read = false` so the unread badge shows

Checklist:
- [ ] 3–4 conversations on the demo account
- [ ] Realistic back-and-forth message history
- [ ] At least one unread conversation

---

## 6. Notifications (Notifications tab) — `notifications`

**Add:** ~8–10 notifications **for the demo account** (`user_id = demo`).

Cover every type so the screen is varied:
- `like` — someone liked your post (`reference_id` = post id)
- `comment` — someone commented (`reference_id` = post id)
- `follow` — someone followed you (`reference_id` = follower id)
- `collab` — collab interest (`reference_id` = collab id)
- `message` — new message (`reference_id` = conversation id)

Checklist:
- [ ] All 5 types represented
- [ ] Mix of `is_read = true / false`
- [ ] `actor_id` points to real users (so names/avatars render)

---

## 7. AI features — `ai/song_builder`, `ai/collab_match`

These generate output live, so they don't need seed rows — but verify before viva:
- [ ] API key / backend AI endpoint is configured and working
- [ ] Run Song Builder once and confirm it returns a result
- [ ] Run Collab Match once — it needs creators + collabs from steps 1–4 to match against

---

## 8. Demo account final state

Before the viva, the account you log in with live should have:
- [ ] Avatar, bio, genres set
- [ ] 1–2 own posts
- [ ] Following / followers populated
- [ ] 3–4 conversations with history
- [ ] Unread notifications + unread message badge
- [ ] (If creator) creator profile + 1–2 playlists + 1 collab

---

## How to add the data

Pick whichever is easier:

1. **Through the app UI** — most realistic, but slow. Good for the demo account's
   own posts/messages so they look authentic.
2. **Supabase SQL / Table editor** — fastest for bulk seed data (posts, playlists,
   likes, follows). Insert directly into the tables.
3. **A seed SQL script** — write one `seed.sql` with all the INSERTs so you can
   re-run it if the database is reset. Recommended — ask and I can generate it.

> ⚠️ Counter columns (`likes_count`, `comments_count`, `track_count`,
> `playlists.likes_count`) are **not auto-updated** when you insert rows directly.
> If you bulk-insert likes/comments via SQL, set the count columns to match,
> or call the RPC functions (`increment_likes`, etc.).

---

## Priority order (if short on time)

1. Users + avatars/bios
2. Posts + likes + comments (Feed)
3. Playlists (Discover)
4. Follows
5. Notifications
6. Conversations + messages
7. Collaborations
8. Verify AI endpoints
