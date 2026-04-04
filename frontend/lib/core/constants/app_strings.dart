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
  static const messaging = _MessagingStrings();
  static const creator = _CreatorStrings();
  static const collab = _CollabStrings();
}

class _MessagingStrings {
  const _MessagingStrings();

  // Chats List Screen
  final String chatsTitle = 'Chats';
  final String searchChatHint = 'Search chat';
  final String conversationsSection = 'Conversations';
  final String noChatHistory = 'No messages yet';

  // Chat Detail Screen
  final String writeMessageHint = 'Write a message...';
  final String onlineStatus = 'online';
  final String offlineStatus = 'offline';
  final String typingStatus = 'typing...';
  final String todayLabel = 'Today';
  final String yesterdayLabel = 'Yesterday';
  final String lastWeekLabel = 'Last week';

  // Message actions
  final String messageDeletedPlaceholder = 'This message was deleted';
  final String deleteMessageAction = 'Delete message';
  final String deleteMessageUndo = 'Message deleted';
  final String cancelAction = 'Cancel';

  // Delete conversation dialog
  final String deleteConversationTitle = 'Delete conversation';
  final String deleteConversationMessage =
      'This will remove the conversation from your inbox. The other person will not be affected.';
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
  final String continueWithEmail = 'Continue with Email';
  
  // Email input screen
  final String emailInputTitle = 'Sign in with Email';
  final String emailInputSubtitle = 'Enter your email and we\'ll send you a verification code.';
  final String sendCodeBtn = 'Send Code';
  
  // OTP input screen
  final String otpTitle = 'Enter verification code';
  final String otpSubtitle = 'We sent an 8-digit code to';
  final String otpResend = 'Resend code';
  final String otpResendIn = 'Resend in';
  final String otpInvalid = 'Invalid code. Please try again.';
  final String otpExpired = 'Code expired. Please request a new one.';
  final String otpVerifying = 'Verifying...';
}

class _ConnectSpotifyStrings {
  const _ConnectSpotifyStrings();

  final String title = 'Connect Spotify';
  final String subtitle = 'Import your playlists and share your\nmusic taste';
  final String privacyInfo =
      "We only read your playlists. We'll never post anything without asking.";
  final String permissionsTitle = 'What we access';
  final String permissionPlaylists = 'Your public and private playlists';
  final String permissionCollaborative = 'Collaborative playlists you follow';
  final String permissionNever =
      'We never modify your library or post on your behalf';
  final String connectBtn = 'Connect Spotify Account';
  final String skipBtn = 'Skip for Now';
  final String nevermindBtn = 'Nevermind';
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

class _CreatorStrings {
  const _CreatorStrings();

  // Become a Creator screen
  final String becomeCreatorTitle = 'Ready to Become\na Creator?';
  final String becomeCreatorSubtitle =
      'Join the community of artists and start\nbuilding your music network today';
  final String featureCollabTitle = 'Post Collaboration Opportunities';
  final String featureCollabSubtitle = 'Find artists for your next track';
  final String featureBadgeTitle = 'Creator Badge';
  final String featureBadgeSubtitle = 'Get verified as an active creator';
  final String featureEngageTitle = 'Engage with Listeners';
  final String featureEngageSubtitle = 'Grow your audience and fanbase';
  final String featurePortfolioTitle = 'Showcase Your Portfolio';
  final String featurePortfolioSubtitle =
      'Display your links and social profiles';
  final String continueToSetupBtn = 'Continue to Setup';

  // Creator Setup screen
  final String creatorSetupTitle = 'Creator Setup';
  final String professionalInfoSection = 'Professional Information';
  final String roleTitleLabel = 'Your Role / Title';
  final String roleTitleHint = 'e.g. Music Producer';
  final String locationLabel = 'Location';
  final String locationHint = 'City, Country';
  final String specializationSection = 'Specialization';
  final String portfolioSection = 'Portfolio & Links';
  final String soundcloudHint = 'SoundCloud Link';
  final String youtubeHint = 'YouTube Link';
  final String spotifyArtistHint = 'Spotify Artist URL';
  final String appleMusicHint = 'Apple Music URL';
  final String portfolioHint = 'Portfolio Link';
  final String completeSetupBtn = 'Complete Setup';
  final String nevermindBtn = 'Nevermind';

  // Creator success screen
  final String creatorSuccessTitle = "You're a Creator Now!";
  final String creatorSuccessSubtitle =
      'Your profile is live. Start posting collaborations\nand get discovered by the community.';
  final String goToProfileBtn = 'Go to Profile';

  // Deactivation dialog
  final String switchToListenerTitle = 'Switch to Listener?';
  final String switchToListenerMessage =
      'Your open collaborations will be closed. Your creator profile data will be saved if you want to switch back later.';
  final String switchBtn = 'Switch';
  final String cancelBtn = 'Cancel';
}

class _DiscoverStrings {
  const _DiscoverStrings();

  // Discover Home sections
  final String browseByGenre = 'Browse by Genre';
  final String featuredPlaylists = 'Featured Playlists';
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

  // Playlist Detail (continued)
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
  final String saveError = 'Failed to save playlist. Please try again.';
  final String importError = 'Failed to import playlist. Please try again.';
  final String retry = 'Retry';
  final String loadMore = 'Load more';
}

class _CollabStrings {
  const _CollabStrings();

  // Screen titles
  final String screenTitle = 'Collaborations';
  final String detailTitle = 'Collaboration';
  final String manageTitle = 'My Collaborations';
  final String newCollabTitle = 'New Collaboration';
  final String editCollabTitle = 'Edit Collaboration';

  // Filter
  final String filterAll = 'All';

  // Feed
  final String noCollabsFound = 'No collaborations found';
  final String noCollabsSubtitle = 'Check back later or adjust your filter';
  final String loadingError =
      'Failed to load collaborations. Please try again.';

  // Manage screen
  final String manageInfoBanner = 'Manage your active collaboration posts';
  final String activePosts = 'Active Posts';
  final String noMyCollabs = "You haven't posted any collaborations yet";
  final String noMyCollabsSubtitle =
      'Tap the button above to create your first post';

  // Card actions
  final String editAction = 'Edit';
  final String deleteAction = 'Delete';
  final String editComingSoon = 'Edit feature coming soon';

  // Delete dialog
  final String deleteDialogTitle = 'Delete Post?';
  final String deleteDialogBody =
      'This action cannot be undone. Are you sure you want to delete this collaboration post?';
  final String deleteDialogCancel = 'Cancel';
  final String deleteDialogConfirm = 'Delete';
  final String deleteSuccess = 'Post deleted';
  final String deleteError = 'Failed to delete post. Please try again.';

  // Detail screen
  final String aboutProject = 'About this Project';
  final String lookingForSection = 'Looking For';
  final String genresSection = 'Genres & Styles';
  final String viewProfile = 'View';
  final String yourPost = 'Your Post';
  final String editPost = 'Edit Post';
  final String deletePost = 'Delete';
  final String deleteConfirmMessage =
      'Are you sure you want to delete this collaboration? This cannot be undone.';

  // Create form
  final String titleFieldLabel = 'What are you looking for?';
  final String titleFieldHint = 'e.g. Vocalist for R&B track';
  final String descriptionFieldLabel = 'Description';
  final String descriptionFieldHint =
      'Tell potential collaborators about your project, style and goals...';
  final String lookingForSectionTitle = "I'm Looking for";
  final String lookingForSectionSubtitle = 'Select all that apply';
  final String genreSectionTitle = 'Genre / Style';
  final String genreSectionSubtitle = 'Choose up to 3 genres';
  final String projectTypeSectionTitle = 'Project Type';
  final String projectTypeSectionSubtitle = 'Select your compensation model';
  final String postButton = 'Post Collaboration';
  final String postSuccess = 'Collaboration posted successfully!';
  final String postError = 'Failed to post collaboration. Please try again.';
  final String editButton = 'Save Changes';
  final String editSuccess = 'Collaboration updated successfully!';
  final String editError = 'Failed to update collaboration. Please try again.';

  // Validation
  final String titleRequired = 'Please enter a title (min 5 characters)';
  final String descriptionRequired =
      'Please enter a description (min 10 characters)';
  final String lookingForRequired = 'Please select at least one role';

  // Project type options
  final String paidProject = 'Paid Project';
  final String paidProjectDesc = 'Direct payment for work';
  final String revenueShare = 'Revenue Share';
  final String revenueShareDesc = 'Share profits from the project';
  final String forFun = 'For Fun/Experience';
  final String forFunDesc = 'Non-commercial collaboration';

  // Message button
  final String messageButton = 'Message';

  // Generic
  final String retry = 'Retry';
  final String createNewCollab = 'Create New Collab';
}
