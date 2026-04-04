import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Centralized asset management for the application.
///
/// Following the mandatory project rules.
class AppAssets {
  static const img = _Images();
  static const icon = _Icons();
}

class _Images {
  const _Images();

  final String spotifyLogo = 'icons/spotify-logo.svg';
  final String googleLogo = 'icons/google-logo.svg';
}

class _Icons {
  const _Icons();

  // Navigation
  final dynamic home = HugeIcons.strokeRoundedHome01;
  final dynamic discover = HugeIcons.strokeRoundedDiscoverCircle;
  final dynamic message = HugeIcons.strokeRoundedMessage01;
  final dynamic profile = HugeIcons.strokeRoundedUserCircle;
  final dynamic search = HugeIcons.strokeRoundedSearch01;
  final dynamic add = HugeIcons.strokeRoundedAdd01;
  final dynamic arrowLeft = HugeIcons.strokeRoundedArrowLeft01;
  final dynamic clock = HugeIcons.strokeRoundedClock02;
  final dynamic cancelCircle = HugeIcons.strokeRoundedCancelCircle;

  // Feed Actions
  final dynamic favoriteOutline = HugeIcons.strokeRoundedFavourite;
  final dynamic favoriteFilled = Icons.favorite;
  final dynamic comment = HugeIcons.strokeRoundedComment01;
  final dynamic more = HugeIcons.strokeRoundedMoreHorizontal;
  final dynamic edit = HugeIcons.strokeRoundedEdit02;
  final dynamic delete = HugeIcons.strokeRoundedDelete02;
  final dynamic report = HugeIcons.strokeRoundedFlag01;
  final dynamic hide = HugeIcons.strokeRoundedViewOff;

  // Other
  final dynamic notification = HugeIcons.strokeRoundedNotification01;
  final dynamic menu = HugeIcons.strokeRoundedMenu02;
  final dynamic image = HugeIcons.strokeRoundedImage02;
  final dynamic verified = Icons.verified;
  final dynamic camera = HugeIcons.strokeRoundedCamera01;
  final dynamic music = HugeIcons.strokeRoundedMusicNote01;
  final dynamic close = HugeIcons.strokeRoundedCancel01;
  final dynamic gallery = HugeIcons.strokeRoundedImage01;
  final dynamic externalLink = HugeIcons.strokeRoundedLink01;
  final dynamic link = HugeIcons.strokeRoundedLinkSquare02;
  final dynamic check = HugeIcons.strokeRoundedCheckmarkCircle02;
  final dynamic globe = HugeIcons.strokeRoundedGlobe02;
  final dynamic send = HugeIcons.strokeRoundedSent;
  final dynamic location = HugeIcons.strokeRoundedLocation01;
  final dynamic starCircle = HugeIcons.strokeRoundedStarCircle;

  final dynamic collab = HugeIcons.strokeRoundedPlaylist02;

  // Messaging
  final dynamic arrowUp = HugeIcons.strokeRoundedArrowUp02;

  // Settings
  final dynamic settings = HugeIcons.strokeRoundedSettings01;
  final dynamic userEdit = HugeIcons.strokeRoundedUserEdit01;
  final dynamic lockPassword = HugeIcons.strokeRoundedLockPassword;
  final dynamic spotify = HugeIcons.strokeRoundedMusicNote01;
  final dynamic google = HugeIcons.strokeRoundedGoogle;
  final dynamic starCreator = HugeIcons.strokeRoundedStarCircle;
  final dynamic bellNotification = HugeIcons.strokeRoundedNotification02;
  final dynamic activityHeart = HugeIcons.strokeRoundedHeartCheck;
  final dynamic messageAlert = HugeIcons.strokeRoundedMessageNotification01;
  final dynamic collabHandshake = HugeIcons.strokeRoundedUserSharing;
  final dynamic privateEye = HugeIcons.strokeRoundedViewOff;
  final dynamic dmLock = HugeIcons.strokeRoundedMessageLock01;
  final dynamic blockedUser = HugeIcons.strokeRoundedUserBlock01;
  final dynamic mutedUser = HugeIcons.strokeRoundedVolumeOff;
  final dynamic playlist = HugeIcons.strokeRoundedPlaylist02;
  final dynamic genreFilter = HugeIcons.strokeRoundedFilterVertical;
  final dynamic hideLike = HugeIcons.strokeRoundedFavouriteSquare;
  final dynamic themeMoon = HugeIcons.strokeRoundedMoon01;
  final dynamic language = HugeIcons.strokeRoundedLanguageCircle;
  final dynamic appInfo = HugeIcons.strokeRoundedInformationCircle;
  final dynamic terms = HugeIcons.strokeRoundedFile01;
  final dynamic privacyShield = HugeIcons.strokeRoundedShieldUser;
  final dynamic licenses = HugeIcons.strokeRoundedBook01;
  final dynamic logout = HugeIcons.strokeRoundedLogout01;
  final dynamic deleteAccount = HugeIcons.strokeRoundedDelete02;
  final dynamic chevronRight = HugeIcons.strokeRoundedArrowRight01;
}
