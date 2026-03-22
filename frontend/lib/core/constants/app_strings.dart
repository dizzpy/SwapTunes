/// Defines constant strings used throughout the application to avoid hardcoding.
///
/// Use [AppStrings] to access nested feature-specific strings securely.
class AppStrings {
  static const profileSetup = _ProfileSetupStrings();
  static const auth = _AuthStrings();
  static const onboarding = _OnboardingStrings();
  static const connectSpotify = _ConnectSpotifyStrings();
  static const welcomeSuccess = _WelcomeSuccessStrings();
  static const feed = _FeedStrings();
  static const discover = _DiscoverStrings();
}

class _ProfileSetupStrings {
  const _ProfileSetupStrings();

  final String title = 'Profile Setup';
  final String fullNameLabel = 'Full Name';
  final String fullNameHint = 'Anny Walker';
  final String usernameLabel = 'Username';
  final String usernameHint = 'anny09';
  final String bioLabel = 'Bio';
  final String bioHint = 'Short description';
  final String whatToListenInfo = 'What do you want to listen?';
  final String pickCountInfo = 'Pick 2 or more';
  final String completeButton = 'Complete';
  final String characterCountSuffix = '0/150';
}

class _AuthStrings {
  const _AuthStrings();

  final String welcomeBack = 'Welcome back';
  final String loginToContinue = 'Login to continue';
  final String emailHint = 'Email';
  final String passwordHint = 'Password';
  final String forgotPassword = 'Forgot password?';
  final String loginBtn = 'Login';
  final String orContinueWith = 'or continue with';
  final String continueGoogle = 'Continue with Google';
  final String continueSpotify = 'Continue with Spotify';
  final String noAccount = "Don't have an account? ";
  final String signUp = 'Sign up';
}

class _OnboardingStrings {
  const _OnboardingStrings();

  final String signInBtn = 'Sign In';
  final String createAccount = 'Create an account';
  final String continueMagicLink = 'Continue with Magic Link';
}

class _ConnectSpotifyStrings {
  const _ConnectSpotifyStrings();

  final String title = 'Connect Spotify';
  final String subtitle = 'Import your playlists and share your\nmusic taste';
  final String privacyInfo =
      "We only read your playlists. We'll never post anything without asking.";
  final String connectBtn = 'Connect Spotify Account';
  final String skipBtn = 'Skip for Now';
}

class _WelcomeSuccessStrings {
  const _WelcomeSuccessStrings();

  final String title = "You're in!";
  final String subtitle = "Let's turn your playlists\ninto connections.";
  final String continueBtn = 'Continue';
}

class _FeedStrings {
  const _FeedStrings();

  final String createPostTitle = 'Create post';
  final String postHint = "What's on your mind?";
  final String publishBtn = 'Post';
}

class _DiscoverStrings {
  const _DiscoverStrings();

  // Discover Home sections
  final String browseByGenre = 'Browse by Genre';
  final String futurePlaylists = 'Future Playlists';
  final String suggestForYou = 'Suggest for you';

  // Browse Genres page
  final String browseGenresTitle = 'Browse Genres';

  // Add Playlist bottom sheet
  final String addPlaylistTitle = 'Add Playlist';
  final String importFromSpotify = 'Import from Spotify';
  final String importFromSpotifySubtitle =
      'Bring your Spotify playlists to SwapTunes';
  final String createManually = 'Create Manually';
  final String createManuallySubtitle = 'Build a playlist from scratch';

  // Spotify Import screen
  final String spotifyImportTitle = 'Import from Spotify';
  final String connectSpotifyPrompt =
      'Connect your Spotify to import your playlists';
  final String connectSpotifyBtn = 'Connect Spotify';
  final String yourSpotifyPlaylists = 'Your Spotify Playlists';
  final String alreadyImported = 'Imported';
  final String importing = 'Importing...';
  final String importBtn = 'Import';
  final String noSpotifyPlaylists = 'No playlists found on Spotify';

  // Playlist Editor
  final String createPlaylistTitle = 'Create Playlist';
  final String editPlaylistTitle = 'Edit Playlist';
  final String coverImageLabel = 'Cover Image';
  final String playlistNameLabel = 'Playlist Name';
  final String playlistNameHint = 'Give your playlist a name';
  final String descriptionLabel = 'Description';
  final String descriptionHint = "What's this playlist about?";
  final String sourcePlatformLabel = 'Source Platform';
  final String externalLinksLabel = 'External Links';
  final String externalLinksSubtitle = 'At least one link is required';
  final String spotifyUrlHint = 'Spotify playlist URL';
  final String youtubeMusicUrlHint = 'YouTube Music URL';
  final String appleMusicUrlHint = 'Apple Music URL';
  final String soundcloudUrlHint = 'SoundCloud URL';
  final String categorizationLabel = 'Categorization';
  final String genreTagsLabel = 'Genre Tags';
  final String addGenreHint = 'Add genre...';
  final String featuredArtistsLabel = 'Featured Artists';
  final String addArtistHint = 'Add artist...';
  final String moodLabel = 'Mood / Vibe';
  final String moodSubtitle = 'Pick up to 3';
  final String eraLabel = 'Era';
  final String energyLabel = 'Energy Level';
  final String occasionLabel = 'Occasion';
  final String vocalStyleLabel = 'Vocal Style';
  final String languageLabel = 'Language';
  final String visibilityLabel = 'Visibility';
  final String publicLabel = 'Public';
  final String privateLabel = 'Private';
  final String publishBtn = 'Publish Playlist';
  final String saveChangesBtn = 'Save Changes';
  final String atLeastOneLink = 'Add at least one external link to continue';
  final String nameRequired = 'Playlist name is required';

  // Playlist Detail
  final String listenOn = 'Listen on';
  final String tracksCount = 'tracks';
  final String deletePlaylist = 'Delete Playlist';
  final String deletePlaylistMessage =
      'This playlist will be permanently removed.';
  final String editPlaylist = 'Edit Playlist';

  // Genre Detail
  final String noPlaylistsInGenre = 'No playlists in this genre yet';
  final String noPlaylistsSubtitle = 'Be the first to add one!';

  // Playlist Detail
  final String openOn = 'Open on';
  final String trackListLabel = 'Tracks';
  final String addedOnLabel = 'Added';
  final String loadingTracks = 'Loading tracks...';
  final String noTracksAvailable = 'Track list not available for this platform';
  final String viewAllTracks = 'View all on';
  final String likeCount = 'likes';

  // Playlist Editor — platform link input
  final String primaryLinkLabel = 'Playlist Link';
  final String invalidUrlFormat = 'Invalid link format';
  final String addMorePlatforms = '+ Add more platforms';
  final String hideSecondaryLinks = 'Show less';
  final String suggested = 'Suggested';
  final String noPlatformSelected = 'Select a platform first';

  // Empty / error states
  final String noGenres = 'No genres available yet';
  final String loadingError = 'Something went wrong. Please try again.';
  final String retry = 'Retry';
  final String loadMore = 'Load more';
}
