# SwapTunes — Flutter App Structure
> Mobile frontend structure for the Flutter application.  
> Pattern: Feature-first folder structure

---

## Folder Structure

```
swaptunes_flutter/
│
├── lib/
│   │
│   ├── main.dart                    # App entry point, Supabase init
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── supabase_config.dart  # Supabase URL + anon key
│   │   │   └── app_config.dart       # API base URL, env flags
│   │   │
│   │   ├── constants/
│   │   │   ├── app_colors.dart       # Color palette (#1DB954 green etc)
│   │   │   ├── app_text_styles.dart  # Typography
│   │   │   └── app_strings.dart      # String constants
│   │   │
│   │   ├── router/
│   │   │   └── app_router.dart       # GoRouter / AutoRoute navigation
│   │   │
│   │   ├── services/
│   │   │   ├── api_service.dart      # HTTP client (Dio) — calls Express backend
│   │   │   ├── auth_service.dart     # Supabase Auth methods
│   │   │   └── realtime_service.dart # Supabase Realtime channel management
│   │   │
│   │   └── utils/
│   │       ├── validators.dart       # Form validators
│   │       └── extensions.dart       # Dart extensions
│   │
│   ├── features/
│   │   │
│   │   ├── auth/
│   │   │   ├── screens/
│   │   │   │   ├── onboarding_screen.dart     # 3 onboarding slides
│   │   │   │   ├── auth_popup.dart            # Bottom sheet auth options
│   │   │   │   ├── profile_setup_screen.dart  # Post-auth profile form
│   │   │   │   ├── connect_spotify_screen.dart
│   │   │   │   └── welcome_screen.dart        # "You're in!" screen
│   │   │   ├── providers/
│   │   │   │   └── auth_provider.dart
│   │   │   └── models/
│   │   │       └── user_model.dart
│   │   │
│   │   ├── home/
│   │   │   ├── screens/
│   │   │   │   └── home_screen.dart           # Feed screen
│   │   │   ├── widgets/
│   │   │   │   ├── post_card.dart             # Single post in feed
│   │   │   │   ├── create_post_bar.dart       # "What's on your mind?"
│   │   │   │   ├── comments_sheet.dart        # Bottom sheet popup
│   │   │   │   └── post_options_dialog.dart   # Report/Hide dialog
│   │   │   └── providers/
│   │   │       └── feed_provider.dart
│   │   │
│   │   ├── discover/
│   │   │   ├── screens/
│   │   │   │   ├── discover_screen.dart
│   │   │   │   ├── search_screen.dart
│   │   │   │   └── import_playlist_screen.dart
│   │   │   ├── widgets/
│   │   │   │   ├── genre_chip_row.dart
│   │   │   │   ├── playlist_card.dart
│   │   │   │   └── suggested_user_card.dart
│   │   │   └── providers/
│   │   │       └── discover_provider.dart
│   │   │
│   │   ├── inbox/
│   │   │   ├── screens/
│   │   │   │   ├── chat_home_screen.dart      # Conversation list
│   │   │   │   └── chat_screen.dart           # Single chat / messaging
│   │   │   ├── widgets/
│   │   │   │   ├── conversation_tile.dart
│   │   │   │   └── message_bubble.dart
│   │   │   └── providers/
│   │   │       ├── conversations_provider.dart
│   │   │       └── messages_provider.dart     # Includes Realtime subscription
│   │   │
│   │   ├── profile/
│   │   │   ├── screens/
│   │   │   │   ├── own_profile_screen.dart
│   │   │   │   ├── public_profile_screen.dart
│   │   │   │   └── edit_profile_sheet.dart    # Bottom sheet popup
│   │   │   ├── widgets/
│   │   │   │   ├── profile_header.dart
│   │   │   │   ├── stats_row.dart
│   │   │   │   ├── stats_popup.dart           # Followers/Following popup
│   │   │   │   └── platform_links_popup.dart  # SoundCloud/Spotify/YouTube links
│   │   │   └── providers/
│   │   │       └── profile_provider.dart
│   │   │
│   │   ├── creator/
│   │   │   ├── screens/
│   │   │   │   ├── become_creator_screen.dart
│   │   │   │   └── creator_setup_screen.dart
│   │   │   └── providers/
│   │   │       └── creator_provider.dart
│   │   │
│   │   ├── collab/                            # CREATOR ONLY
│   │   │   ├── screens/
│   │   │   │   ├── collab_home_screen.dart    # Collab marketplace list
│   │   │   │   ├── collab_detail_screen.dart  # Single collab view
│   │   │   │   └── manage_collabs_screen.dart # Own collabs list
│   │   │   ├── widgets/
│   │   │   │   ├── collab_card.dart
│   │   │   │   └── create_collab_sheet.dart   # Bottom sheet popup
│   │   │   └── providers/
│   │   │       └── collab_provider.dart
│   │   │
│   │   └── notifications/
│   │       ├── screens/
│   │       │   └── notifications_screen.dart
│   │       ├── widgets/
│   │       │   └── notification_tile.dart
│   │       └── providers/
│   │           └── notifications_provider.dart  # Includes Realtime subscription
│   │
│   └── shared/
│       ├── widgets/
│       │   ├── app_bottom_nav.dart       # Listener (4 tabs) / Creator (5 tabs)
│       │   ├── app_drawer.dart           # Side drawer with settings link
│       │   ├── avatar_widget.dart
│       │   ├── loading_indicator.dart
│       │   └── empty_state_widget.dart
│       └── models/
│           ├── user_model.dart
│           ├── post_model.dart
│           ├── playlist_model.dart
│           ├── collab_model.dart
│           ├── message_model.dart
│           └── notification_model.dart
│
├── assets/
│   ├── images/
│   └── icons/
│
├── pubspec.yaml
└── README.md
```

---

## Key Packages (`pubspec.yaml`)

### Core
| Package | Purpose |
|---------|---------|
| `supabase_flutter` | Auth + Realtime |
| `dio` | HTTP client for Express API calls |
| `go_router` | Navigation / routing |
| `flutter_riverpod` | State management |

### UI
| Package | Purpose |
|---------|---------|
| `cached_network_image` | Efficient image loading + caching |
| `flutter_svg` | SVG icon support |
| `shimmer` | Loading skeleton animations |

### Storage & Security
| Package | Purpose |
|---------|---------|
| `flutter_secure_storage` | Store JWT securely |

### Utilities
| Package | Purpose |
|---------|---------|
| `timeago` | Relative timestamps ("3 min ago") |
| `image_picker` | Pick avatar / post images |

---

## Navigation Structure

```dart
// app_router.dart (GoRouter)

GoRouter(
  routes: [
    // Auth flow
    GoRoute(path: '/onboarding', ...),
    GoRoute(path: '/profile-setup', ...),
    GoRoute(path: '/connect-spotify', ...),
    GoRoute(path: '/welcome', ...),

    // Main app shell with bottom nav
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', ...),
        GoRoute(path: '/discover', ...),
        GoRoute(path: '/discover/search', ...),
        GoRoute(path: '/collab', ...),       // creator only
        GoRoute(path: '/collab/:id', ...),
        GoRoute(path: '/inbox', ...),
        GoRoute(path: '/inbox/:convId', ...),
        GoRoute(path: '/profile', ...),
        GoRoute(path: '/profile/:username', ...),
      ],
    ),

    // Creator setup
    GoRoute(path: '/become-creator', ...),
    GoRoute(path: '/creator-setup', ...),
  ],
  redirect: (context, state) {
    // Redirect unauthenticated users to /onboarding
    // Redirect authenticated users away from /onboarding
  },
)
```

---

## State Management Pattern (Riverpod)

```
Provider Types Used:
  FutureProvider      → single async data fetch (profile, collab details)
  StreamProvider      → Realtime message streams
  StateNotifierProvider → mutable state (feed, conversations list)
  Provider            → simple computed values (current user, badge count)
```

---

## `main.dart`

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      child: SwapTunesApp(),
    ),
  );
}
```

---

## Bottom Nav — Dynamic by User Type

```dart
// shared/widgets/app_bottom_nav.dart

final userType = ref.watch(authProvider).user?.userType;

final listenerTabs = [Home, Discover, Inbox, Profile];
final creatorTabs  = [Home, Discover, Collab, Inbox, Profile];

final tabs = userType == 'creator' ? creatorTabs : listenerTabs;
```
