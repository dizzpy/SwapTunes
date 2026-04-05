import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/source_platform.dart';
import '../../data/repositories/discover_repository.dart';

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
  final DiscoverRepository _repository;

  /// Non-null = edit mode. Null = create mode.
  final String? playlistId;

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
  bool _isUploadingImage = false;
  String? _error;

  // ── Per-field validation errors (set on submit attempt) ─────────────────
  String? nameError;
  String? platformError;
  String? linkError;
  bool _hasAttemptedSubmit = false;

  bool get isSaving => _isSaving;
  bool get isUploadingImage => _isUploadingImage;
  String? get error => _error;
  bool get isEditMode => playlistId != null;
  bool get hasAttemptedSubmit => _hasAttemptedSubmit;

  PlaylistEditorViewModel({
    required DiscoverRepository repository,
    this.playlistId,
    this.suggestedGenres = const [],
    this.suggestedArtists = const [],
    SourcePlatform? initialPlatform,
    String? initialPrimaryUrl,
  }) : _repository = repository {
    if (initialPlatform != null) sourcePlatform = initialPlatform;
    if (initialPrimaryUrl != null) primaryUrl = initialPrimaryUrl;
  }

  // ── Cover image ─────────────────────────────────────────────────────────

  Future<bool> pickCoverImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return false;

    _isUploadingImage = true;
    notifyListeners();

    try {
      final url = await _repository.uploadImage(file);
      coverImageUrl = url;
      _isUploadingImage = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isUploadingImage = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void removeCoverImage() {
    coverImageUrl = null;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool get hasAtLeastOneLink => primaryUrl.isNotEmpty;

  bool get isValid =>
      name.trim().isNotEmpty &&
      sourcePlatform != null &&
      hasAtLeastOneLink &&
      primaryUrlError == null;

  /// Runs all field validations and returns the first error message, or null if valid.
  String? validate() {
    _hasAttemptedSubmit = true;

    nameError = name.trim().isEmpty ? 'Playlist name is required' : null;
    platformError = sourcePlatform == null ? 'Select a source platform' : null;

    if (primaryUrl.isEmpty) {
      linkError = 'Playlist link is required';
    } else {
      _validatePrimaryUrl();
      linkError = primaryUrlError;
    }

    notifyListeners();

    // Return first error message for snackbar
    return nameError ?? platformError ?? linkError;
  }

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
    if (_hasAttemptedSubmit) {
      nameError = value.trim().isEmpty ? 'Playlist name is required' : null;
    }
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  void setSourcePlatform(SourcePlatform platform) {
    // Clear primary URL when switching platforms
    if (sourcePlatform != platform) {
      primaryUrl = '';
      linkError = null;
    }
    primaryUrlError = null;
    platformError = null;
    sourcePlatform = platform;
    notifyListeners();
  }

  void setPrimaryUrl(String value) {
    primaryUrl = value;
    _validatePrimaryUrl();
    if (_hasAttemptedSubmit) {
      linkError = primaryUrl.isEmpty
          ? 'Playlist link is required'
          : primaryUrlError;
    }
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
    final validationError = validate();
    if (validationError != null) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    final body = <String, dynamic>{
      'name': name.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
      'cover_image_url': coverImageUrl,
      'is_public': isPublic,
      'source_platform': sourcePlatform!.value,
      'primary_url': primaryUrl,
      'genre_tags': genreTags,
      'artists': artists,
      'mood_tags': moodTags,
      'era': era,
      'energy_level': energyLevel?.toLowerCase(),
      'occasion_tags': occasionTags,
      'vocal_style': vocalStyle?.toLowerCase(),
      'language': language?.toLowerCase(),
    };

    try {
      if (isEditMode) {
        await _repository.updatePlaylist(playlistId!, body);
      } else {
        await _repository.createPlaylist(body);
      }
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
