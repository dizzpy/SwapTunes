import 'package:flutter/material.dart';
import '../../data/models/playlist_model.dart';
import '../../data/repositories/discover_repository.dart';

/// Lightweight display model for a single playlist card in the genre detail grid.
class PlaylistItem {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;

  const PlaylistItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
  });

  factory PlaylistItem.fromModel(PlaylistModel model) {
    return PlaylistItem(
      id: model.id,
      title: model.name,
      subtitle: model.genreTags.isNotEmpty
          ? model.genreTags.join(', ')
          : model.ownerUsername,
      imageUrl: model.coverImageUrl,
    );
  }
}

class GenreDetailViewModel extends ChangeNotifier {
  static const int _pageSize = 20;

  final DiscoverRepository _repository;
  final String genre;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  final List<PlaylistItem> _playlists = [];
  int _page = 1;
  bool _hasMore = true;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  List<PlaylistItem> get playlists => List.unmodifiable(_playlists);

  GenreDetailViewModel({
    required this.genre,
    required DiscoverRepository repository,
  }) : _repository = repository {
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await _repository.getDiscoverPlaylists(
        genre: genre,
        page: 1,
        limit: _pageSize,
      );
      _playlists
        ..clear()
        ..addAll(results.map(PlaylistItem.fromModel));
      _page = 1;
      _hasMore = results.length == _pageSize;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => _loadPlaylists();

  /// Silent refresh — re-fetches page 1 without showing loading spinner.
  Future<void> refresh() async {
    try {
      final results = await _repository.getDiscoverPlaylists(
        genre: genre,
        page: 1,
        limit: _pageSize,
      );
      _playlists
        ..clear()
        ..addAll(results.map(PlaylistItem.fromModel));
      _page = 1;
      _hasMore = results.length == _pageSize;
      _error = null;
      notifyListeners();
    } catch (_) {
      // Silently ignore — stale data is better than a blank screen
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final results = await _repository.getDiscoverPlaylists(
        genre: genre,
        page: _page + 1,
        limit: _pageSize,
      );
      _playlists.addAll(results.map(PlaylistItem.fromModel));
      _page++;
      _hasMore = results.length == _pageSize;
    } catch (_) {
      // silently ignore load-more errors — existing data stays visible
    }

    _isLoadingMore = false;
    notifyListeners();
  }
}
