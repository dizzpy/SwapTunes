import 'package:flutter/material.dart';

class BrowseGenresViewModel extends ChangeNotifier {
  static const int _pageSize = 12;

  final bool _isLoading = false;
  final String? _error = null;
  int _visibleCount = _pageSize;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Full genre list — will be replaced with API call in data layer phase
  static const List<String> _allGenres = [
    'Hip-Hop',
    'Jazz',
    'Rock',
    'Classical',
    'Reggae',
    'Electronic',
    'Pop',
    'R&B',
    'Lo-fi',
    'Dubstep',
    'K-Pop',
    'Ambient',
    'Metal',
    'Country',
    'Funk',
    'Soul',
    'Indie',
    'Blues',
    'Trap',
    'Drill',
    'Afrobeats',
    'Latin',
    'Gospel',
    'Punk',
  ];

  List<String> get visibleGenres => _allGenres.take(_visibleCount).toList();

  bool get hasMore => _visibleCount < _allGenres.length;

  void loadMore() {
    _visibleCount = (_visibleCount + _pageSize).clamp(0, _allGenres.length);
    notifyListeners();
  }
}
