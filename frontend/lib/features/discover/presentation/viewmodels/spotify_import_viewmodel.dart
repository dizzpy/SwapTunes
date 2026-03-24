import 'package:flutter/material.dart';
import '../../data/models/spotify_playlist_model.dart';
import '../../data/repositories/discover_repository.dart';

class SpotifyImportViewModel extends ChangeNotifier {
  final DiscoverRepository _repository;

  bool _isSpotifyConnected;
  bool get isSpotifyConnected => _isSpotifyConnected;
  bool _isLoading = false;
  bool _isImporting = false;
  String? _importingId;
  String? _error;
  List<SpotifyPlaylistModel> _playlists = [];

  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String? get importingId => _importingId;
  String? get error => _error;
  List<SpotifyPlaylistModel> get playlists => _playlists;

  // Populated after a successful import — passed to PlaylistEditorScreen
  List<String> lastSuggestedGenres = [];
  List<String> lastSuggestedArtists = [];
  String? lastImportedSpotifyUrl;

  SpotifyImportViewModel({
    required bool isSpotifyConnected,
    required DiscoverRepository repository,
  })  : _isSpotifyConnected = isSpotifyConnected,
        _repository = repository {
    if (_isSpotifyConnected) _loadPlaylists();
  }

  /// Marks the user as connected and loads playlists.
  void markConnected() {
    _isSpotifyConnected = true;
    notifyListeners();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _playlists = await _repository.getAvailableSpotifyPlaylists();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => _loadPlaylists();

  /// Imports a single Spotify playlist. Returns true on success.
  Future<bool> importPlaylist(String spotifyId) async {
    if (_isImporting) return false;
    _isImporting = true;
    _importingId = spotifyId;
    _error = null;
    notifyListeners();

    try {
      final playlist = await _repository.importSpotifyPlaylist(spotifyId);
      lastImportedSpotifyUrl = playlist.primaryUrl;
      lastSuggestedGenres = playlist.genreTags;
      lastSuggestedArtists = playlist.artists;

      // Mark as imported in the list
      _playlists = _playlists
          .map((p) => p.id == spotifyId
              ? SpotifyPlaylistModel(
                  id: p.id,
                  name: p.name,
                  trackCount: p.trackCount,
                  isPublic: p.isPublic,
                  coverImageUrl: p.coverImageUrl,
                  isImported: true,
                )
              : p)
          .toList();

      _isImporting = false;
      _importingId = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isImporting = false;
      _importingId = null;
      notifyListeners();
      return false;
    }
  }
}
