/// Defines constant string paths for assets used throughout the application to avoid hardcoding.
///
/// Use [AppAssets] to access all asset paths (SVG, PNG, Lottie, etc).
class AppAssets {
  static const icons = _Icons();
}

class _Icons {
  const _Icons();

  final String spotifyLogo = 'icons/spotify-logo.svg';
  final String googleLogo = 'icons/google-logo.svg';
}
