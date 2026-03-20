import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../data/datasources/feed_remote_datasource.dart' show kFeedPageSize;
import '../../data/models/comment_model.dart';
import '../../data/models/liker_model.dart';
import '../../data/models/post_model.dart';
import '../../data/repositories/feed_repository.dart';

/// Feed state management for the presentation layer.
///
/// Exposes feed posts, comment state, and loading/error state to UI
/// via the Provider ChangeNotifier pattern.
///
/// Both user roles (listener & creator) share this viewmodel —
/// `isOwnPost` is determined in the UI by comparing `post.userId`
/// against `AuthViewmodel.currentUser?.id`.
class FeedViewmodel extends ChangeNotifier {
  final FeedRepository _repository;
  int _tempIdCounter = 0;

  // ── Feed State ─────────────────────────────────────────

  List<PostModel> _posts = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _feedError;
  int _page = 1;
  bool _hasMore = true;

  // ── Comment State ──────────────────────────────────────

  List<CommentModel> _comments = [];
  bool _isCommentsLoading = false;
  String? _commentError;
  final Map<String, List<CommentModel>> _commentsCache = {};

  // ── Likers State ───────────────────────────────────────

  List<LikerModel> _likers = [];
  bool _isLikersLoading = false;

  // ── Create Post State ──────────────────────────────────

  bool _isCreating = false;
  String? _createError;

  FeedViewmodel(this._repository);

  // ── Getters ────────────────────────────────────────────

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get feedError => _feedError;
  bool get hasMore => _hasMore;

  List<CommentModel> get comments => List.unmodifiable(_comments);
  bool get isCommentsLoading => _isCommentsLoading;
  String? get commentError => _commentError;

  List<LikerModel> get likers => List.unmodifiable(_likers);
  bool get isLikersLoading => _isLikersLoading;

  bool get isCreating => _isCreating;
  String? get createError => _createError;

  // ── Feed ───────────────────────────────────────────────

  /// Loads the first page of feed posts, replacing any existing data.
  Future<void> loadFeed() async {
    if (_isLoading) return;
    _isLoading = true;
    _feedError = null;
    _page = 1;
    _hasMore = true;
    notifyListeners();

    try {
      final posts = await _repository.getFeed(page: _page);
      _posts = posts;
      _hasMore = posts.length >= kFeedPageSize;
      _page = 2;
    } catch (e) {
      _feedError = _parseError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Appends the next page of posts. No-op if already loading or no more data.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final posts = await _repository.getFeed(page: _page);
      _posts = [..._posts, ...posts];
      _hasMore = posts.length >= kFeedPageSize;
      if (_hasMore) _page++;
    } catch (_) {
      // Silent failure — pagination errors don't disrupt the existing feed.
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // ── Create Post ────────────────────────────────────────

  /// Optimistically creates a post: inserts a placeholder immediately, then
  /// uploads the image (if any) and calls the API in the background.
  ///
  /// [userId], [authorUsername], [authorFullName], [authorAvatarUrl] are used
  /// to build the placeholder card visible before the server responds.
  void createPost({
    required String content,
    required String userId,
    required String authorUsername,
    required String authorFullName,
    String? authorAvatarUrl,
    List<XFile>? images,
  }) {
    _isCreating = true;
    _createError = null;
    final tempId =
        '_temp_${DateTime.now().millisecondsSinceEpoch}_${_tempIdCounter++}';
    final placeholder = PostModel(
      id: tempId,
      userId: userId,
      content: content,
      imageUrl: null,
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      createdAt: DateTime.now(),
      authorUsername: authorUsername,
      authorFullName: authorFullName,
      authorAvatarUrl: authorAvatarUrl,
      authorIsVerified: false,
      isUploading: true,
    );
    _posts = [placeholder, ..._posts];
    notifyListeners();

    _doCreatePost(tempId: tempId, content: content, images: images);
  }

  Future<void> _doCreatePost({
    required String tempId,
    required String content,
    List<XFile>? images,
  }) async {
    try {
      String? imageUrl;
      if (images != null && images.isNotEmpty) {
        imageUrl = await _repository.uploadImage(images.first);
      }
      final post = await _repository.createPost(content, imageUrl: imageUrl);
      final idx = _posts.indexWhere((p) => p.id == tempId);
      if (idx != -1) {
        _posts = List.from(_posts)..[idx] = post;
      } else {
        _posts = [post, ..._posts];
      }
      AppSnackbar.success('Post published');
    } catch (e) {
      _createError = _parseError(e);
      _posts = _posts.where((p) => p.id != tempId).toList();
      AppSnackbar.error('Failed to publish post');
    } finally {
      _isCreating = false;
      notifyListeners();
    }
  }

  void clearCreateError() {
    _createError = null;
    notifyListeners();
  }

  // ── Like / Unlike ──────────────────────────────────────

  /// Per-post debounce timers — cancel and restart on each tap so the API
  /// call only fires 500ms after the *last* tap.
  final Map<String, Timer> _likeTimers = {};

  /// Captures the like state as it was *before the first tap* in a debounce
  /// window, so we can skip the API call if the user toggled back, or
  /// revert correctly on failure.
  final Map<String, bool> _likeOriginalState = {};

  /// Debounce duration for like/unlike API calls.
  static const _likeDebounceDuration = Duration(milliseconds: 500);

  /// Toggles the like state for [postId] with optimistic UI + 500ms debounce.
  ///
  /// Each tap instantly updates the UI. The API call is deferred until
  /// 500ms of inactivity. If the final state equals the original state,
  /// no network request is made.
  void toggleLike(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final post = _posts[idx];
    final wasLiked = post.isLiked;

    // Remember the original state at the start of the debounce window.
    _likeOriginalState.putIfAbsent(postId, () => wasLiked);

    // ── Optimistic UI update (instant) ──────────────────
    _updatePost(
      postId,
      (p) => p.copyWith(
        isLiked: !wasLiked,
        likesCount: wasLiked
            ? (p.likesCount > 0 ? p.likesCount - 1 : 0)
            : p.likesCount + 1,
      ),
    );

    // ── Cancel any pending timer and start a fresh one ──
    _likeTimers[postId]?.cancel();
    _likeTimers[postId] = Timer(_likeDebounceDuration, () {
      _fireLikeApi(postId);
    });
  }

  /// Fires the actual API call once the debounce timer expires.
  Future<void> _fireLikeApi(String postId) async {
    _likeTimers.remove(postId);
    final originalState = _likeOriginalState.remove(postId);
    if (originalState == null) return;

    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    final currentIsLiked = _posts[idx].isLiked;

    // If the user toggled back to the original state, skip the API call.
    if (currentIsLiked == originalState) return;

    try {
      if (currentIsLiked) {
        await _repository.likePost(postId);
      } else {
        await _repository.unlikePost(postId);
      }
    } catch (_) {
      // Revert to the original state on failure.
      _updatePost(
        postId,
        (p) => p.copyWith(
          isLiked: originalState,
          likesCount: originalState
              ? p.likesCount + 1
              : (p.likesCount > 0 ? p.likesCount - 1 : 0),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Cancel all pending like timers to prevent leaks.
    for (final timer in _likeTimers.values) {
      timer.cancel();
    }
    _likeTimers.clear();
    _likeOriginalState.clear();
    super.dispose();
  }

  // ── Edit ───────────────────────────────────────────────

  /// Optimistically updates post content and/or image, reverting on failure.
  ///
  /// If [newImage] is provided, it is uploaded first via the repository.
  /// If [removeImage] is true, the image_url is cleared on the server.
  /// Returns true on success, false on failure.
  Future<bool> updatePost(
    String postId,
    String content, {
    XFile? newImage,
    bool removeImage = false,
  }) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return false;
    final oldPost = _posts[idx];

    // Optimistic text update
    _updatePost(postId, (p) => p.copyWith(content: content));

    try {
      String? imageUrl;
      if (newImage != null) {
        imageUrl = await _repository.uploadImage(newImage);
      }

      final updated = await _repository.updatePost(
        postId,
        content: content,
        imageUrl: removeImage ? '' : imageUrl,
      );
      _posts = List.from(_posts)
        ..[idx] = updated.copyWith(
          isLiked: _posts[idx].isLiked,
          likesCount: _posts[idx].likesCount,
          commentsCount: _posts[idx].commentsCount,
        );
      notifyListeners();
      return true;
    } catch (_) {
      _updatePost(
        postId,
        (p) => p.copyWith(content: oldPost.content, imageUrl: oldPost.imageUrl),
      );
      return false;
    }
  }

  // ── Moderation ─────────────────────────────────────────

  /// Removes the post from the local feed, reverting on API failure.
  Future<void> deletePost(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    PostModel? removed;
    if (idx != -1) {
      removed = _posts[idx];
      _posts = List.from(_posts)..removeAt(idx);
      notifyListeners();
    }
    try {
      await _repository.deletePost(postId);
    } catch (_) {
      if (removed != null && idx != -1) {
        _posts = List.from(_posts)..insert(idx, removed);
        notifyListeners();
      }
    }
  }

  /// Removes the post from the local feed, reverting on API failure.
  Future<void> hidePost(String postId) async {
    final idx = _posts.indexWhere((p) => p.id == postId);
    PostModel? removed;
    if (idx != -1) {
      removed = _posts[idx];
      _posts = List.from(_posts)..removeAt(idx);
      notifyListeners();
    }
    try {
      await _repository.hidePost(postId);
    } catch (_) {
      if (removed != null && idx != -1) {
        _posts = List.from(_posts)..insert(idx, removed);
        notifyListeners();
      }
    }
  }

  /// Reports a post. Silent on failure (fire-and-forget).
  Future<void> reportPost(String postId, String reason) async {
    try {
      await _repository.reportPost(postId, reason);
    } catch (_) {
      // Silent — the UI already dismissed the sheet.
    }
  }

  // ── Comments ───────────────────────────────────────────

  /// Loads comments for [postId] with stale-while-revalidate caching.
  ///
  /// If cached data exists, it is shown immediately while a fresh fetch runs
  /// in the background. If no cache exists, a loading spinner is shown instead.
  Future<void> loadComments(String postId) async {
    final cached = _commentsCache[postId];
    if (cached != null) {
      _comments = cached;
      _commentError = null;
      notifyListeners();
    } else {
      _isCommentsLoading = true;
      _commentError = null;
      notifyListeners();
    }

    try {
      final fresh = await _repository.getComments(postId);
      _commentsCache[postId] = fresh;
      _comments = fresh;
    } catch (e) {
      if (cached == null) {
        _commentError = _parseError(e);
      }
    } finally {
      _isCommentsLoading = false;
      notifyListeners();
    }
  }

  /// Optimistically adds a comment: appends it immediately, then confirms via API.
  ///
  /// On failure the optimistic comment is removed and the count rolled back.
  /// [userId], [authorUsername], [authorFullName], [authorAvatarUrl] are used
  /// to build the placeholder that is shown before the server responds.
  Future<bool> addComment(
    String postId,
    String content, {
    required String userId,
    required String authorUsername,
    required String authorFullName,
    String? authorAvatarUrl,
  }) async {
    final tempId =
        '_temp_${DateTime.now().millisecondsSinceEpoch}_${_tempIdCounter++}';
    final optimistic = CommentModel(
      id: tempId,
      postId: postId,
      userId: userId,
      content: content,
      createdAt: DateTime.now(),
      authorUsername: authorUsername,
      authorFullName: authorFullName,
      authorAvatarUrl: authorAvatarUrl,
    );

    _comments = [..._comments, optimistic];
    _updatePost(postId, (p) => p.copyWith(commentsCount: p.commentsCount + 1));

    try {
      final comment = await _repository.addComment(postId, content);
      final idx = _comments.indexWhere((c) => c.id == tempId);
      if (idx != -1) {
        _comments = List.from(_comments)..[idx] = comment;
        _commentsCache[postId] = List.from(_comments);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _comments = _comments.where((c) => c.id != tempId).toList();
      _updatePost(
        postId,
        (p) => p.copyWith(
          commentsCount: p.commentsCount > 0 ? p.commentsCount - 1 : 0,
        ),
      );
      _commentError = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  /// Deletes a comment optimistically, reverting on API failure.
  Future<void> deleteComment(String postId, String commentId) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    CommentModel? removed;
    if (idx != -1) {
      removed = _comments[idx];
      _comments = List.from(_comments)..removeAt(idx);
      _updatePost(
        postId,
        (p) => p.copyWith(
          commentsCount: p.commentsCount > 0 ? p.commentsCount - 1 : 0,
        ),
      );
      notifyListeners();
    }
    try {
      await _repository.deleteComment(postId, commentId);
      _commentsCache[postId] = List.from(_comments);
    } catch (_) {
      if (removed != null && idx != -1) {
        _comments = List.from(_comments)..insert(idx, removed);
        _updatePost(
          postId,
          (p) => p.copyWith(commentsCount: p.commentsCount + 1),
        );
        notifyListeners();
      }
    }
  }

  /// Optimistically updates comment content, reverting on API failure.
  /// Returns true on success, false on failure.
  Future<bool> updateComment(
    String postId,
    String commentId,
    String content,
  ) async {
    final idx = _comments.indexWhere((c) => c.id == commentId);
    if (idx == -1) return false;
    final oldContent = _comments[idx].content;

    _comments = List.from(_comments)
      ..[idx] = _comments[idx].copyWith(content: content);
    notifyListeners();

    try {
      final updated = await _repository.updateComment(
        postId,
        commentId,
        content,
      );
      _comments = List.from(_comments)..[idx] = updated;
      _commentsCache[postId] = List.from(_comments);
      notifyListeners();
      return true;
    } catch (_) {
      _comments = List.from(_comments)
        ..[idx] = _comments[idx].copyWith(content: oldContent);
      notifyListeners();
      return false;
    }
  }

  void clearCommentError() {
    _commentError = null;
    notifyListeners();
  }

  // ── Likers ─────────────────────────────────────────────

  /// Loads the list of users who liked [postId].
  Future<void> loadLikers(String postId) async {
    _isLikersLoading = true;
    _likers = [];
    notifyListeners();
    try {
      _likers = await _repository.getLikers(postId);
    } catch (_) {
      // Silent — sheet just shows empty state
    } finally {
      _isLikersLoading = false;
      notifyListeners();
    }
  }

  // ── Helpers ────────────────────────────────────────────

  void _updatePost(String postId, PostModel Function(PostModel) update) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx == -1) return;
    _posts = List.from(_posts)..[idx] = update(_posts[idx]);
    notifyListeners();
  }

  String _parseError(Object e) {
    if (e is ApiException) return e.message;
    if (e is UnauthorizedException) {
      return 'Session expired. Please log in again.';
    }
    return e.toString();
  }
}
