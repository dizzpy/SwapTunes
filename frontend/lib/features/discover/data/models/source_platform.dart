import 'package:flutter/material.dart';

/// Represents the music platform a playlist originates from.
enum SourcePlatform {
  spotify,
  youtubeMusic,
  appleMusic,
  soundcloud,
  other;

  /// API value used for serialization.
  String get value {
    switch (this) {
      case SourcePlatform.spotify:
        return 'spotify';
      case SourcePlatform.youtubeMusic:
        return 'youtube_music';
      case SourcePlatform.appleMusic:
        return 'apple_music';
      case SourcePlatform.soundcloud:
        return 'soundcloud';
      case SourcePlatform.other:
        return 'other';
    }
  }

  /// Human-readable label shown in the UI.
  String get displayName {
    switch (this) {
      case SourcePlatform.spotify:
        return 'Spotify';
      case SourcePlatform.youtubeMusic:
        return 'YouTube Music';
      case SourcePlatform.appleMusic:
        return 'Apple Music';
      case SourcePlatform.soundcloud:
        return 'SoundCloud';
      case SourcePlatform.other:
        return 'Other';
    }
  }

  /// Brand color for the platform badge.
  Color get color {
    switch (this) {
      case SourcePlatform.spotify:
        return const Color(0xFF1DB954);
      case SourcePlatform.youtubeMusic:
        return const Color(0xFFFF0000);
      case SourcePlatform.appleMusic:
        return const Color(0xFFFC3C44);
      case SourcePlatform.soundcloud:
        return const Color(0xFFFF5500);
      case SourcePlatform.other:
        return const Color(0xFFA7A9A9);
    }
  }

  /// Parses from the API value string.
  static SourcePlatform fromValue(String value) {
    return SourcePlatform.values.firstWhere(
      (p) => p.value == value,
      orElse: () => SourcePlatform.other,
    );
  }
}
