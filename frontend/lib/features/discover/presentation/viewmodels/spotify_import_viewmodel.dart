import 'package:flutter/material.dart';

/// Represents a Spotify playlist available for import.
class SpotifyPlaylistItem {
  final String id;
  final String name;
  final int trackCount;
  final String? coverImageUrl;
  final bool isImported;

  const SpotifyPlaylistItem({
    required this.id,
    required this.name,
    required this.trackCount,
    this.coverImageUrl,
    this.isImported = false,
  });
}

class SpotifyImportViewModel extends ChangeNotifier {
  bool _isSpotifyConnected = false;
  final bool _isLoading = false;
  bool _isImporting = false;
  String? _importingId;
  String? _error;

  bool get isSpotifyConnected => _isSpotifyConnected;
  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String? get importingId => _importingId;
  String? get error => _error;

  // Mock data — will be replaced with API calls in the data layer phase
  final List<SpotifyPlaylistItem> playlists = [
    const SpotifyPlaylistItem(
      id: 'sp1',
      name: 'Heavy Bass Drops 2026',
      trackCount: 45,
      coverImageUrl: 'https://picsum.photos/seed/sp1/200/200',
      isImported: false,
    ),
    const SpotifyPlaylistItem(
      id: 'sp2',
      name: 'Late Night Study Vibes',
      trackCount: 32,
      coverImageUrl: 'https://picsum.photos/seed/sp2/200/200',
      isImported: true,
    ),
    const SpotifyPlaylistItem(
      id: 'sp3',
      name: 'Summer R&B Essentials',
      trackCount: 28,
      coverImageUrl: 'https://picsum.photos/seed/sp3/200/200',
      isImported: false,
    ),
    const SpotifyPlaylistItem(
      id: 'sp4',
      name: 'K-Pop Bangers',
      trackCount: 35,
      coverImageUrl: 'https://picsum.photos/seed/sp4/200/200',
      isImported: false,
    ),
  ];

  // Populated after a successful import — passed to PlaylistEditorScreen
  List<String> lastSuggestedGenres = [];
  List<String> lastSuggestedArtists = [];
  String? lastImportedSpotifyUrl;

  void connectSpotify() {
    // Will trigger OAuth flow via AuthViewModel in the data layer phase
    _isSpotifyConnected = true;
    notifyListeners();
  }

  /// Imports a single Spotify playlist and extracts genre/artist suggestions
  /// from the track data. Returns true on success.
  Future<bool> importPlaylist(String spotifyId) async {
    if (_isImporting) return false;
    _isImporting = true;
    _importingId = spotifyId;
    notifyListeners();

    // Simulates Spotify API call — will be wired to real API in data layer phase.
    // In production, the backend extracts top artists + their genres from tracks.
    await Future.delayed(const Duration(milliseconds: 800));

    // Mock suggestions extracted from the playlist tracks
    lastSuggestedGenres = ['Electronic', 'Dubstep', 'Bass'];
    lastSuggestedArtists = ['Skrillex', 'Excision', 'Virtual Riot'];
    lastImportedSpotifyUrl = 'https://open.spotify.com/playlist/$spotifyId';

    _isImporting = false;
    _importingId = null;
    notifyListeners();
    return true;
  }
}
