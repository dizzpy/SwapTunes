import 'package:flutter/material.dart';
import '../../data/repositories/discover_repository.dart';

class BrowseGenresViewModel extends ChangeNotifier {
  static const int _pageSize = 12;

  final DiscoverRepository _repository;

  bool _isLoading = true;
  String? _error;
  List<String> _allGenres = [];
  int _visibleCount = _pageSize;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get visibleGenres => _allGenres.take(_visibleCount).toList();
  bool get hasMore => _visibleCount < _allGenres.length;

  BrowseGenresViewModel(this._repository) {
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allGenres = await _repository.getGenres();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> retry() => _loadGenres();

  /// Silent refresh — re-fetches without showing loading spinner.
  Future<void> refresh() async {
    try {
      _allGenres = await _repository.getGenres();
      _error = null;
      notifyListeners();
    } catch (_) {}
  }

  void loadMore() {
    _visibleCount = (_visibleCount + _pageSize).clamp(0, _allGenres.length);
    notifyListeners();
  }
}
