# Report Testing Summary

Source files read: every Dart file under `frontend/test/`. The requested path `apps/mobile/test/` does not exist in this checkout.

## Test Files

| Test file | Type | What it tests |
|---|---|---|
| `frontend/test/helpers/fixtures.dart` | Helper | Shared fixture data for models/viewmodels. |
| `frontend/test/helpers/mocks.dart` | Helper | Mocktail mocks for auth, feed, profile, messaging, creator, collab, discover, notification repositories and feed/profile/messaging datasources. |
| `frontend/test/integration/feed/feed_cache_integration_test.dart` | Integration | Feed Isar cache: fresh cache hit, empty cache fetch/store, stale cache refresh, stale fallback on API failure, force refresh bypass, and page > 1 not cached. |
| `frontend/test/integration/messaging/messaging_cache_integration_test.dart` | Integration | Messaging Isar cache: conversations cache, messages cache, stale fallbacks, force refresh, delete conversation cache invalidation, send message cache invalidation, and older-message pagination not cached. |
| `frontend/test/integration/profile/profile_cache_integration_test.dart` | Integration | Profile Isar cache: fresh/stale/empty profile cache, force refresh, user posts cache, and profile cache invalidation. |
| `frontend/test/unit/auth/auth_viewmodel_test.dart` | Unit | Google/Spotify OAuth, OTP send, deep-link handling, auto login, profile setup, Spotify connect, current user refresh, logout, error clearing, and Supabase auth stream events. |
| `frontend/test/unit/auth/otp_viewmodel_test.dart` | Unit | OTP send success, verify without pending email, invalid code error, expired code error, and resend availability. |
| `frontend/test/unit/collab/collab_viewmodel_test.dart` | Unit | Collaboration list loading, error handling, create success/failure, and loading own collaborations. |
| `frontend/test/unit/creator/creator_viewmodel_test.dart` | Unit | Creator setup success/failure and creator deactivation success/failure. |
| `frontend/test/unit/discover/discover_viewmodel_test.dart` | Unit | Discover initial load of genres/playlists/suggested users, follow/unfollow toggling, and retry after initial failure. |
| `frontend/test/unit/feed/feed_viewmodel_test.dart` | Unit | Feed load/more, optimistic likes with debounce, create/update/delete/hide/report posts, comments cache and optimistic comment operations, and liker loading. |
| `frontend/test/unit/messaging/chats_list_viewmodel_test.dart` | Unit | Conversation list loading, error handling, concurrent guard, and optimistic delete/restore behavior. |
| `frontend/test/unit/messaging/single_chat_viewmodel_test.dart` | Unit | Message loading, chronological ordering, pagination, optimistic send/retry failure state, soft delete, undo, 5-second delete flush, and dispose behavior. |
| `frontend/test/unit/notifications/notification_viewmodel_test.dart` | Unit | Notification load/unread count, load errors, group mark-read, mark-all-read, and deletion. |
| `frontend/test/unit/profile/profile_viewmodel_test.dart` | Unit | Profile setup submission success/failure and loading state. |
| `frontend/test/unit/profile/user_profile_viewmodel_test.dart` | Unit | Public/own profile loading, silent refresh, local profile edit, follow debounce/revert, user posts loading guards, and local post removal. |
| `frontend/test/widget/auth/auth_screen_test.dart` | Widget | Auth screen rendering, email input, send code action, Google sign-in action, and Spotify sign-in action. |
| `frontend/test/widget/feed/feed_screen_test.dart` | Widget | Feed loading skeleton, loaded posts, error/retry state, empty feed input box, and like button callback. |
| `frontend/test/widget/feed/post_card_test.dart` | Widget | Post card rendering, content/username/count display, and like callback. |
| `frontend/test/widget/profile/creator_info_section_test.dart` | Widget | Creator role/location/link display and link bottom sheet. |
| `frontend/test/widget/profile/profile_cover_header_test.dart` | Widget | Profile cover/avatar rendering for listener and creator modes, avatar/cover callbacks, and no-callback state. |

## Mock Files

| File | Mocks included |
|---|---|
| `frontend/test/helpers/mocks.dart` | `MockAuthRepository`, `MockFeedRepository`, `MockProfileRepository`, `MockMessagingRepository`, `MockCreatorRepository`, `MockCollabRepository`, `MockDiscoverRepository`, `MockNotificationRepository`, `MockFeedRemoteDatasource`, `MockProfileRemoteDatasource`, `MockMessagingRemoteDatasource`. |
| Individual widget/unit tests | Several private fake classes implement viewmodels/services where widget tests need simple controlled state, for example fake auth/feed viewmodels and fake storage service. |

## Coverage Estimate

| Metric | Count |
|---|---:|
| Feature implementation files under `frontend/lib/features` | 165 |
| Test/helper files under `frontend/test` | 21 |
| Unit test files | 11 |
| Widget test files | 5 |
| Integration test files | 3 |

Approximate file-count test ratio: 18 actual test files against 165 feature files, about 11%. This is a rough structural estimate only; no coverage report was generated from source.

## Feature Coverage By Area

| Feature area | Test status |
|---|---|
| Auth | Unit and widget tests present. |
| OTP | Unit tests present. |
| Onboarding | No direct test file found. |
| Feed | Unit, widget, and cache integration tests present. |
| Discover | Unit tests for main discover viewmodel present; no widget/integration tests found for playlist editor, genre detail, search, Spotify import, or featured/suggested screens. |
| Profile | Unit, widget, and cache integration tests present. |
| Creator | Unit tests for creator viewmodel present; no widget tests found for creator setup/loading/success screens. |
| Collaboration | Unit tests for collab viewmodel present; no widget/integration tests found for collab screens. |
| AI Collab Match | No direct test file found. |
| AI Song Builder | No direct test file found. |
| Messaging | Unit and cache integration tests present; no widget tests found for chat UI widgets/screens. |
| Notifications | Unit tests present; no widget/integration tests found. |
| Settings | No direct test file found. |
| Splash | No direct test file found. |
| Dev tools | No direct test file found. |

## Known Gaps

- No tests were found for AI Collab Match or AI Song Builder.
- No direct tests were found for settings, splash, dev tools, onboarding screen behavior, creator screens, and many discover screens.
- Realtime subscriptions are present in source, but no integration tests were found for Supabase Realtime callbacks.
- CI runs `flutter test` with `continue-on-error: true`, so test failure currently does not fail the full CI job.





