import 'package:flutter/material.dart';
import '../../data/models/source_platform.dart';

/// Predefined mood tags — max 3 selectable per playlist.
const List<String> kMoodTags = [
  'energetic',
  'chill',
  'dark',
  'upbeat',
  'melancholic',
  'heavy',
  'smooth',
  'aggressive',
  'dreamy',
  'romantic',
  'nostalgic',
  'euphoric',
  'raw',
  'peaceful',
  'hypnotic',
];

const List<String> kOccasionTags = [
  'workout',
  'study',
  'party',
  'driving',
  'sleep',
  'cooking',
  'gaming',
  'travel',
  'meditation',
  'hangout',
];

const List<String> kEraOptions = [
  '2020s',
  '2010s',
  '2000s',
  '90s',
  '80s',
  'mixed',
];

const List<String> kEnergyOptions = ['Low', 'Medium', 'High'];
const List<String> kVocalStyleOptions = ['Instrumental', 'Vocal', 'Mixed'];
const List<String> kLanguageOptions = [
  'English',
  'Spanish',
  'Korean',
  'Japanese',
  'Hindi',
  'Mixed',
  'Instrumental',
  'Other',
];

/// URL validation patterns per platform.
final Map<SourcePlatform, RegExp> _kUrlPatterns = {
  SourcePlatform.spotify: RegExp(
    r'^https://open\.spotify\.com/playlist/[A-Za-z0-9]+',
  ),
  SourcePlatform.youtubeMusic: RegExp(
    r'^https://(music\.youtube\.com|(?:www\.)?youtube\.com/playlist)',
  ),
  SourcePlatform.appleMusic: RegExp(r'^https://music\.apple\.com/'),
  SourcePlatform.soundcloud: RegExp(r'^https://soundcloud\.com/'),
  SourcePlatform.other: RegExp(r'^https?://'),
};

class PlaylistEditorViewModel extends ChangeNotifier {
  // ── Auto-suggest data (populated on Spotify import) ──────────────────────
  final List<String> suggestedGenres;
  final List<String> suggestedArtists;

  // ── Form fields ───────────────────────────────────────────────────────────
  String name = '';
  String description = '';
  String? coverImageUrl;
  SourcePlatform? sourcePlatform;
  bool isPublic = true;

  // Single platform link — validated against the selected platform's URL format
  String primaryUrl = '';
  String? primaryUrlError;

  // ── Blueprint / categorization metadata ──────────────────────────────────
  final List<String> genreTags = [];
  final List<String> artists = [];
  final List<String> moodTags = [];
  String? era;
  String? energyLevel;
  final List<String> occasionTags = [];
  String? vocalStyle;
  String? language;

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isSaving = false;
  String? _error;

  bool get isSaving => _isSaving;
  String? get error => _error;

  PlaylistEditorViewModel({
    this.suggestedGenres = const [],
    this.suggestedArtists = const [],
    SourcePlatform? initialPlatform,
    String? initialPrimaryUrl,
  }) {
    if (initialPlatform != null) {
      sourcePlatform = initialPlatform;
    }
    if (initialPrimaryUrl != null) {
      primaryUrl = initialPrimaryUrl;
    }
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get hasAtLeastOneLink => primaryUrl.isNotEmpty;

  bool get isValid =>
      name.trim().isNotEmpty &&
      sourcePlatform != null &&
      hasAtLeastOneLink &&
      primaryUrlError == null;

  String _platformHint(SourcePlatform platform) {
    switch (platform) {
      case SourcePlatform.spotify:
        return 'https://open.spotify.com/playlist/...';
      case SourcePlatform.youtubeMusic:
        return 'https://music.youtube.com/playlist?list=...';
      case SourcePlatform.appleMusic:
        return 'https://music.apple.com/playlist/...';
      case SourcePlatform.soundcloud:
        return 'https://soundcloud.com/user/sets/...';
      case SourcePlatform.other:
        return 'https://...';
    }
  }

  String get primaryUrlHint =>
      sourcePlatform != null ? _platformHint(sourcePlatform!) : '';

  void _validatePrimaryUrl() {
    if (primaryUrl.isEmpty) {
      primaryUrlError = null;
      return;
    }
    final pattern = _kUrlPatterns[sourcePlatform ?? SourcePlatform.other];
    primaryUrlError = (pattern != null && pattern.hasMatch(primaryUrl))
        ? null
        : 'Invalid link format';
  }

  // ── Setters ───────────────────────────────────────────────────────────────

  void setName(String value) {
    name = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  void setSourcePlatform(SourcePlatform platform) {
    // Clear primary URL when switching platforms
    if (sourcePlatform != platform) primaryUrl = '';
    primaryUrlError = null;
    sourcePlatform = platform;
    notifyListeners();
  }

  void setPrimaryUrl(String value) {
    primaryUrl = value;
    _validatePrimaryUrl();
    notifyListeners();
  }

  void setPublic(bool value) {
    isPublic = value;
    notifyListeners();
  }

  // ── Genre / artist ────────────────────────────────────────────────────────

  void addGenreTag(String tag) {
    if (tag.trim().isEmpty || genreTags.contains(tag.trim())) return;
    genreTags.add(tag.trim());
    notifyListeners();
  }

  void removeGenreTag(String tag) {
    genreTags.remove(tag);
    notifyListeners();
  }

  void addArtist(String artistName) {
    if (artistName.trim().isEmpty || artists.contains(artistName.trim())) {
      return;
    }
    artists.add(artistName.trim());
    notifyListeners();
  }

  void removeArtist(String artistName) {
    artists.remove(artistName);
    notifyListeners();
  }

  // ── Mood / occasion ───────────────────────────────────────────────────────

  void toggleMoodTag(String tag) {
    if (moodTags.contains(tag)) {
      moodTags.remove(tag);
    } else if (moodTags.length < 3) {
      moodTags.add(tag);
    }
    notifyListeners();
  }

  void toggleOccasionTag(String tag) {
    if (occasionTags.contains(tag)) {
      occasionTags.remove(tag);
    } else {
      occasionTags.add(tag);
    }
    notifyListeners();
  }

  // ── Blueprint metadata ────────────────────────────────────────────────────

  void setEra(String? value) {
    era = value;
    notifyListeners();
  }

  void setEnergyLevel(String? value) {
    energyLevel = value;
    notifyListeners();
  }

  void setVocalStyle(String? value) {
    vocalStyle = value;
    notifyListeners();
  }

  void setLanguage(String? value) {
    language = value;
    notifyListeners();
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<bool> savePlaylist() async {
    if (!isValid) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    // Simulates network call — will be wired to real API in data layer phase
    await Future.delayed(const Duration(milliseconds: 800));

    _isSaving = false;
    notifyListeners();
    return true;
  }
}
