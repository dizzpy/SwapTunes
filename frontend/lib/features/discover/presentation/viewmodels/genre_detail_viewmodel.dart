import 'package:flutter/material.dart';

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
}

class GenreDetailViewModel extends ChangeNotifier {
  final String genre;

  final bool _isLoading = false;
  final String? _error = null;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 8;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;

  final List<PlaylistItem> playlists = [];

  GenreDetailViewModel({required this.genre}) {
    _seedMockData();
  }

  void _seedMockData() {
    // First page — will be replaced with API call in data layer phase
    for (var i = 1; i <= _pageSize; i++) {
      playlists.add(
        PlaylistItem(
          id: 'mock-$i',
          title: '$genre Mix $i',
          subtitle: '$genre • ${20 + i} tracks',
          imageUrl: 'https://picsum.photos/seed/${genre}_$i/200/200',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    // Simulates paged API call — will be wired to real API in data layer phase
    await Future.delayed(const Duration(milliseconds: 600));

    _page++;
    final start = (_page - 1) * _pageSize + 1;
    final end = start + _pageSize;

    for (var i = start; i < end; i++) {
      playlists.add(
        PlaylistItem(
          id: 'mock-$i',
          title: '$genre Mix $i',
          subtitle: '$genre • ${20 + i} tracks',
          imageUrl: 'https://picsum.photos/seed/${genre}_$i/200/200',
        ),
      );
    }

    // Stop after 3 pages in mock
    if (_page >= 3) _hasMore = false;

    _isLoadingMore = false;
    notifyListeners();
  }
}
