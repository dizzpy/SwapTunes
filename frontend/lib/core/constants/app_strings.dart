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
  final String noAccount = 'Don’t have an account? ';
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
      'We only read your playlists. We\'ll never post anything without asking.';
  final String connectBtn = 'Connect Spotify Account';
  final String skipBtn = 'Skip for Now';
}

class _WelcomeSuccessStrings {
  const _WelcomeSuccessStrings();

  final String title = 'You\'re in!';
  final String subtitle = 'Let\'s turn your playlists\ninto connections.';
  final String continueBtn = 'Continue';
}

class _FeedStrings {
  const _FeedStrings();

  final String createPostTitle = 'Create post';
  final String postHint = 'What’s on your mind ?';
  final String publishBtn = 'Post';
}
