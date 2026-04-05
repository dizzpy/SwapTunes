import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/suggested_user_model.dart';
import '../../data/repositories/discover_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';

class SearchViewModel extends ChangeNotifier {
  final DiscoverRepository _repository;
  final ProfileRepository _profileRepository;
  final StorageService _storage;

  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  final List<String> tabs = ['All', 'Users', 'Playlists', 'Creators'];
  String _activeTab = 'All';
  String get activeTab => _activeTab;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;

  List<SuggestedUserModel> _userResults = [];
  List<SuggestedUserModel> get userResults => _userResults;

  List<PlaylistModel> _playlistResults = [];
  List<PlaylistModel> get playlistResults => _playlistResults;

  List<SuggestedUserModel> _creatorResults = [];
  List<SuggestedUserModel> get creatorResults => _creatorResults;

  // Follow state
  final Set<String> _followingIds = {};
  final Set<String> _followLoadingIds = {};
  bool isFollowing(String userId) => _followingIds.contains(userId);
  bool isFollowLoading(String userId) => _followLoadingIds.contains(userId);

  // Recent searches — persisted via StorageService
  final List<String> _recentSearches = [];
  List<String> get recentSearches => List.unmodifiable(_recentSearches);

  List<String> _trendingTags = [];
  List<String> get trendingTags => _trendingTags;

  bool get hasQuery => searchController.text.trim().isNotEmpty;

  bool get hasResults =>
      _userResults.isNotEmpty ||
      _playlistResults.isNotEmpty ||
      _creatorResults.isNotEmpty;

  SearchViewModel(this._repository, this._profileRepository, this._storage) {
    _recentSearches.addAll(_storage.getRecentSearches());
    searchController.addListener(_onSearchChanged);
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    try {
      final genres = await _repository.getTrendingGenres(limit: 12);
      _trendingTags = genres.map((g) => '#$g').toList();
      notifyListeners();
    } catch (_) {
      // Non-critical — keep empty
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final query = searchController.text.trim();
      if (query.isEmpty) {
        _clearResults();
      } else {
        _performSearch(query);
      }
    });
    notifyListeners();
  }

  void _clearResults() {
    _userResults = [];
    _playlistResults = [];
    _creatorResults = [];
    _error = null;
    notifyListeners();
  }

  Future<void> _performSearch(String query) async {
    _isSearching = true;
    _error = null;
    _saveToRecent(query);
    notifyListeners();

    try {
      final type = _tabToType(_activeTab);
      final data = await _repository.search(query, type: type);

      if (data['users'] != null) {
        _userResults = (data['users'] as List)
            .map((e) => SuggestedUserModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _userResults = [];
      }

      if (data['playlists'] != null) {
        _playlistResults = (data['playlists'] as List)
            .map((e) => PlaylistModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        _playlistResults = [];
      }

      if (data['creators'] != null) {
        _creatorResults = (data['creators'] as List).map((e) {
          final map = e as Map<String, dynamic>;
          final user = map['user'] as Map<String, dynamic>? ?? {};
          return SuggestedUserModel(
            id: user['id'] as String? ?? '',
            fullName: user['full_name'] as String? ?? '',
            username: user['username'] as String? ?? '',
            avatarUrl: user['avatar_url'] as String?,
            userType: map['role_title'] as String?,
          );
        }).toList();
      } else {
        _creatorResults = [];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isSearching = false;
    notifyListeners();
  }

  String _tabToType(String tab) {
    switch (tab) {
      case 'Users':
        return 'users';
      case 'Playlists':
        return 'playlists';
      case 'Creators':
        return 'creators';
      default:
        return 'all';
    }
  }

  void _saveToRecent(String query) {
    _recentSearches.remove(query);
    _recentSearches.insert(0, query);
    if (_recentSearches.length > 10) _recentSearches.removeLast();
    _storage.saveRecentSearches(_recentSearches);
  }

  void setTab(String tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      _performSearch(query);
    }
    notifyListeners();
  }

  void removeRecentSearch(int index) {
    _recentSearches.removeAt(index);
    _storage.saveRecentSearches(_recentSearches);
    notifyListeners();
  }

  void clearRecentSearches() {
    _recentSearches.clear();
    _storage.saveRecentSearches([]);
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    _clearResults();
  }

  Future<void> toggleFollow(String userId) async {
    if (_followLoadingIds.contains(userId)) return;
    _followLoadingIds.add(userId);
    notifyListeners();

    final wasFollowing = _followingIds.contains(userId);
    try {
      if (wasFollowing) {
        await _profileRepository.unfollowUser(userId);
        _followingIds.remove(userId);
      } else {
        await _profileRepository.followUser(userId);
        _followingIds.add(userId);
      }
    } catch (_) {
      if (wasFollowing) {
        _followingIds.add(userId);
      } else {
        _followingIds.remove(userId);
      }
    } finally {
      _followLoadingIds.remove(userId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}
