import 'package:flutter/material.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/discover_repository.dart';

class DiscoverViewModel extends ChangeNotifier {
  final DiscoverRepository _repository;

  bool _isLoading = true;
  String? _error;
  List<String> _genres = [];
  List<PlaylistModel> _playlists = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get genres => _genres;
  List<PlaylistModel> get playlists => _playlists;

  // Suggested users — no backend endpoint yet, keeping as mock
  final List<Map<String, String>> suggestedUsers = [
    {
      'name': 'Skrillex',
      'subtitle': 'Dubstep Anthems',
      'avatar': 'https://picsum.photos/seed/skrillex/100/100',
    },
    {
      'name': 'Tiësto',
      'subtitle': 'Dance & EDM',
      'avatar': 'https://picsum.photos/seed/tiesto/100/100',
    },
  ];

  DiscoverViewModel(this._repository) {
    _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getGenres(),
        _repository.getDiscoverPlaylists(page: 1, limit: 10),
      ]);
      _genres = results[0] as List<String>;
      _playlists = results[1] as List<PlaylistModel>;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Silent refresh — no loading spinner, just re-fetches data in the background.
  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _repository.getGenres(),
        _repository.getDiscoverPlaylists(page: 1, limit: 10),
      ]);
      _genres = results[0] as List<String>;
      _playlists = results[1] as List<PlaylistModel>;
      _error = null;
      notifyListeners();
    } catch (_) {
      // Silently ignore — stale data is better than a blank screen
    }
  }

  Future<void> retry() => _load();
}
