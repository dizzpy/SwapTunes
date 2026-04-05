import 'package:flutter/material.dart';
import '../../data/models/playlist_model.dart';
import '../../data/models/suggested_user_model.dart';
import '../../data/repositories/discover_repository.dart';
import '../../../profile/data/repositories/profile_repository.dart';

class DiscoverViewModel extends ChangeNotifier {
  final DiscoverRepository _repository;
  final ProfileRepository _profileRepository;

  bool _isLoading = true;
  String? _error;
  List<String> _genres = [];
  List<PlaylistModel> _playlists = [];
  List<SuggestedUserModel> _suggestedUsers = [];

  final Set<String> _followingIds = {};
  final Set<String> _followLoadingIds = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get genres => _genres;
  List<PlaylistModel> get playlists => _playlists;
  List<SuggestedUserModel> get suggestedUsers => _suggestedUsers;

  bool isFollowing(String userId) => _followingIds.contains(userId);
  bool isFollowLoading(String userId) => _followLoadingIds.contains(userId);

  DiscoverViewModel(this._repository, this._profileRepository) {
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
        _repository.getSuggestedUsers(limit: 20),
      ]);
      _genres = results[0] as List<String>;
      _playlists = results[1] as List<PlaylistModel>;
      _suggestedUsers = results[2] as List<SuggestedUserModel>;
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
        _repository.getSuggestedUsers(limit: 20),
      ]);
      _genres = results[0] as List<String>;
      _playlists = results[1] as List<PlaylistModel>;
      _suggestedUsers = results[2] as List<SuggestedUserModel>;
      _error = null;
      notifyListeners();
    } catch (_) {
      // Silently ignore — stale data is better than a blank screen
    }
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
      // Revert optimistic update on error
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

  Future<void> retry() => _load();
}
