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

  // Messaging
  final dynamic arrowUp = HugeIcons.strokeRoundedArrowUp02;
}
