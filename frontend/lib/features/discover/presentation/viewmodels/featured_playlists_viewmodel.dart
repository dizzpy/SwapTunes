import 'package:flutter/material.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/discover_repository.dart';

class FeaturedPlaylistsViewModel extends ChangeNotifier {
  static const int _pageSize = 20;

  final DiscoverRepository _repository;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  final List<PlaylistModel> _playlists = [];
  int _page = 1;
  bool _hasMore = true;

  // ── Filter state ───────────────────────────────────────
  List<String> _genres = [];
  String? _activeGenre;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<PlaylistModel> get playlists => List.unmodifiable(_playlists);
  List<String> get genres => _genres;
  String? get activeGenre => _activeGenre;

  FeaturedPlaylistsViewModel(this._repository) {
    _load(fetchGenres: true);
  }

  Future<void> _load({bool fetchGenres = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final futures = <Future>[
        _repository.getDiscoverPlaylists(
          page: 1,
          limit: _pageSize,
          genre: _activeGenre,
        ),
        if (fetchGenres) _repository.getGenres(),
      ];

      final results = await Future.wait(futures);
      final playlists = results[0] as List<PlaylistModel>;

      _playlists
        ..clear()
        ..addAll(playlists);
      _page = 1;
      _hasMore = playlists.length == _pageSize;

      if (fetchGenres) {
        _genres = results[1] as List<String>;
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void setGenre(String? genre) {
    if (_activeGenre == genre) return;
    _activeGenre = genre;
    _load();
  }

  Future<void> retry() => _load(fetchGenres: _genres.isEmpty);

  Future<void> refresh() async {
    try {
      final results = await Future.wait([
        _repository.getDiscoverPlaylists(
          page: 1,
          limit: _pageSize,
          genre: _activeGenre,
        ),
        if (_genres.isEmpty) _repository.getGenres(),
      ]);

      final playlists = results[0] as List<PlaylistModel>;
      _playlists
        ..clear()
        ..addAll(playlists);
      _page = 1;
      _hasMore = playlists.length == _pageSize;

      if (_genres.isEmpty && results.length > 1) {
        _genres = results[1] as List<String>;
      }

      _error = null;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final results = await _repository.getDiscoverPlaylists(
        page: _page + 1,
        limit: _pageSize,
        genre: _activeGenre,
      );
      _playlists.addAll(results);
      _page++;
      _hasMore = results.length == _pageSize;
    } catch (_) {}

    _isLoadingMore = false;
    notifyListeners();
  }
}
