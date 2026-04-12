import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../collab/data/models/collab_model.dart';
import '../../../feed/data/models/post_model.dart';
import '../../data/models/full_profile_model.dart';
import '../../data/models/saved_song_plan_model.dart';
import '../../data/repositories/profile_repository.dart';

/// Viewmodel for both own-profile and public-profile screens.
///
/// Created per-screen (not globally) so each profile view has
/// independent state. Disposed by the screen's [State.dispose].
class UserProfileViewmodel extends ChangeNotifier {
  final ProfileRepository _repository;

  FullProfileModel? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFollowLoading = false;
  Timer? _followDebounce;

  List<PostModel> _posts = [];
  bool _isPostsLoading = false;
  bool _postsLoaded = false; // guard against duplicate loads

  List<CollabModel> _collabs = [];
  bool _isCollabsLoading = false;
  bool _collabsLoaded = false;

  List<SavedSongPlanModel> _songs = [];
  bool _isSongsLoading = false;
  bool _songsLoaded = false;

  FullProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isFollowLoading => _isFollowLoading;
  bool get hasProfile => _profile != null;
  bool get isCreator => _profile?.isCreator ?? false;
  List<PostModel> get posts => _posts;
  bool get isPostsLoading => _isPostsLoading;
  List<CollabModel> get collabs => _collabs;
  bool get isCollabsLoading => _isCollabsLoading;
  List<SavedSongPlanModel> get songs => _songs;
  bool get isSongsLoading => _isSongsLoading;

  bool _disposed = false;

  UserProfileViewmodel(this._repository);

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Load any user profile by username (own or other).
  Future<void> loadProfile(String username) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      _profile = await _repository.getUserProfile(username);
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Silent refresh — bypasses cache, keeps existing data visible.
  Future<void> refresh(String username) async {
    try {
      _profile = await _repository.getUserProfile(username, forceRefresh: true);
      _postsLoaded = false;
    } catch (_) {
      // Silent — stale data stays on screen
    }
    _safeNotify();
  }

  /// Optimistically apply local profile edits before the API call returns.
  ///
  /// Call this immediately on save so the UI reflects changes instantly.
  /// Pass [username] to also invalidate the cache entry.
  void applyLocalProfileEdit({
    String? fullName,
    String? bio,
    String? avatarUrl,
    Object? coverUrl = _sentinel,
    String? username,
    List<String>? genres,
  }) {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      fullName: fullName,
      bio: bio,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
      username: username,
      genres: genres,
    );
    _safeNotify();
  }

  /// Optimistic follow/unfollow toggle with 1-second debounce.
  ///
  /// Flips UI immediately → debounces API call → reverts on failure.
  Future<void> toggleFollow() async {
    if (_profile == null || _isFollowLoading) return;

    // Cancel any pending debounced call
    _followDebounce?.cancel();

    _isFollowLoading = true;
    final wasFollowing = _profile!.isFollowing ?? false;
    final oldStats = _profile!.stats;

    // Optimistic update
    _profile = _profile!.copyWith(
      isFollowing: !wasFollowing,
      stats: oldStats.copyWith(
        followers: wasFollowing
            ? (oldStats.followers > 0 ? oldStats.followers - 1 : 0)
            : oldStats.followers + 1,
      ),
    );
    _safeNotify();

    _followDebounce = Timer(const Duration(milliseconds: 800), () async {
      try {
        if (wasFollowing) {
          await _repository.unfollowUser(_profile!.id);
        } else {
          await _repository.followUser(_profile!.id);
        }
      } catch (_) {
        // Revert on failure
        _profile = _profile!.copyWith(
          isFollowing: wasFollowing,
          stats: oldStats,
        );
        _safeNotify();
      } finally {
        _isFollowLoading = false;
        _safeNotify();
      }
    });
  }

  /// Load the Posts tab content for the current profile.
  Future<void> loadUserPosts() async {
    if (_profile == null || _isPostsLoading || _postsLoaded) return;
    _isPostsLoading = true;
    _safeNotify();

    try {
      _posts = await _repository.getUserPosts(_profile!.id);
      _postsLoaded = true;
    } catch (_) {
      // Silently keep empty list on error
    } finally {
      _isPostsLoading = false;
      _safeNotify();
    }
  }

  /// Load the Collabs tab content for the current profile.
  Future<void> loadUserCollabs() async {
    if (_profile == null || _isCollabsLoading || _collabsLoaded) return;
    _isCollabsLoading = true;
    _safeNotify();

    try {
      _collabs = await _repository.getUserCollabs(_profile!.id);
      _collabsLoaded = true;
    } catch (_) {
      // Silently keep empty list on error
    } finally {
      _isCollabsLoading = false;
      _safeNotify();
    }
  }

  /// Load the Songs tab content for the current profile.
  Future<void> loadUserSongs() async {
    if (_profile == null || _isSongsLoading || _songsLoaded) return;
    _isSongsLoading = true;
    _safeNotify();

    try {
      _songs = await _repository.getUserSongs(_profile!.id);
      _songsLoaded = true;
    } catch (_) {
      // Silently keep empty list on error
    } finally {
      _isSongsLoading = false;
      _safeNotify();
    }
  }

  /// Remove a post from the local list (called after delete in profile tab).
  void removePost(String postId) {
    _posts = _posts.where((p) => p.id != postId).toList();
    if (_profile != null) {
      final current = _profile!.stats.posts;
      _profile = _profile!.copyWith(
        stats: _profile!.stats.copyWith(posts: current > 0 ? current - 1 : 0),
      );
    }
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _followDebounce?.cancel();
    super.dispose();
  }

  String _parseError(Object e) {
    if (e is ApiException) return e.message;
    if (e is UnauthorizedException) {
      return 'Session expired. Please log in again.';
    }
    if (e is NetworkException) return e.message;
    return 'Something went wrong. Please try again.';
  }
}

const Object _sentinel = Object();
