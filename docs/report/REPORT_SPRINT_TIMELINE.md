# Report Sprint Timeline

This timeline is inferred from git-traceable file creation dates and the only migration timestamp found in `supabase/migrations/`. It is not a confirmed project management record.

## Evidence Used

| Evidence | Source |
|---|---|
| Migration timestamp | `supabase/migrations/20260322000000_playlists_discover.sql` |
| Feature creation dates | `git log --diff-filter=A --name-only --format='COMMIT %ad %h' --date=short -- frontend/lib/features supabase/migrations` |

## Sprint Groupings

| Sprint | Approximate date range | What was built | Pivots / notable changes |
|---:|---|---|---|
| 1 | 2026-03-07 to 2026-03-11 | Initial onboarding, auth screens, profile setup, auth datasource/repository/model, auth viewmodel, onboarding repository/viewmodel, profile setup repository/viewmodel. | Auth started with OAuth/profile setup flows. A file named `magic_link_input.dart` appears in git history but is not present in the current feature tree; current auth uses email OTP via `email_input.dart` and `otp_input.dart`. |
| 2 | 2026-03-17 to 2026-03-21 | Feed screens and widgets, post preview/create flow, post card/actions/likes sheet, feed datasource/repository/viewmodel, post/comment/liker models, splash screen, own/user profile screens, profile header/stats/actions/tabs, edit profile, follow model, full profile model, profile caches, feed cache. | Persistent Isar caching was introduced for feed/profile. Profile grew from setup-only into public/own profile with tabs and editing. |
| 3 | 2026-03-22 to 2026-03-24 | Discover screens, playlist editor/detail/search/import, genre browsing, playlist/Spotify playlist/source platform models, discover datasource/repository/viewmodels/widgets. | Migration timestamp 2026-03-22 supports the Discover playlist pivot: manual playlists were enabled by making `spotify_playlist_id` nullable, metadata columns were added, and `playlist_likes` was created. |
| 4 | 2026-03-26 to 2026-03-29 | Messaging screens, conversation/message models, chat widgets, messaging datasource/repository, chat list and single chat viewmodels, Isar caches for conversations and messages. | Realtime messaging was added in the viewmodels, with cache TTLs and stale-while-revalidate behavior for chat messages. |
| 5 | 2026-03-31 to 2026-04-02 | Creator profile setup/reactivation/deactivation, creator loading/success/listener transition screens, dev tools screen, collaboration feed/details/manage/new screens, collab model/datasource/repository/viewmodel/widgets. | Role behavior expanded: creators get a dedicated Collab tab while listeners do not. |
| 6 | 2026-04-04 to 2026-04-05 | Settings screen/widgets, OTP input widget, featured playlists, suggested users, notifications datasource/model/repository/viewmodel/screen/widgets, listener transition screen. | Notifications were added with Supabase Realtime and OneSignal already existed in core services. Settings include notification preferences, while delete account remains TODO. |
| 7 | 2026-04-11 to 2026-04-12 | AI Collab Match and AI Song Builder. AI match files first appear under `features/collab` in git history, while current source places them under `features/ai/collab_match`. Song Builder appears in git history under `features/creator`, while current source places it under `features/ai/song_builder`. Saved song plans were added to profile. | Clear AI feature consolidation pivot: current code has an `features/ai/` namespace for collab matching and song building. |

## Migration-Based Timeline Notes

| Date | Evidence | Interpretation |
|---|---|---|
| 2026-03-22 | Migration filename `20260322000000_playlists_discover.sql` | Discover playlist database support was introduced around this date. |
| 2026-03-24 | Git creation commit for discover datasource/repository and migration | Flutter Discover data integration was connected shortly after or alongside schema changes. |

## Unclear Items

- The repository contains only one Supabase migration, so earlier base tables such as `users`, `playlists`, `posts`, `messages`, `conversations`, and `notifications` could not be dated from migrations.
- Folder creation order was inferred from Git file-add dates. Git history may not represent actual sprint boundaries if files were moved, squashed, or imported.
