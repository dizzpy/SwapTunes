import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/datasources/collab_remote_datasource.dart'
    show kCollabPageSize;
import '../../data/models/collab_model.dart';
import '../../data/repositories/collab_repository.dart';

/// State management for the collab feature.
///
/// Covers: feed browsing with filter + pagination, creator's own posts,
/// detail view, create, and delete flows.
class CollabViewmodel extends ChangeNotifier {
  final CollabRepository _repository;
  bool _disposed = false;

  // ── Feed State ─────────────────────────────────────────

  List<CollabModel> _collabs = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  bool _hasMore = true;
  String? _selectedFilter; // null = 'All'

  // ── My Collabs State ───────────────────────────────────

  List<CollabModel> _myCollabs = [];
  bool _isMyCollabsLoading = false;
  String? _myCollabsError;

  // ── Create State ───────────────────────────────────────

  bool _isCreating = false;
  String? _createError;

  // ── Delete State ───────────────────────────────────────

  Set<String> _deletingIds = {};

  // ── Detail State ───────────────────────────────────────

  CollabModel? _selectedCollab;
  bool _isDetailLoading = false;
  String? _detailError;

  CollabViewmodel(this._repository);

  // ── Getters ────────────────────────────────────────────

  List<CollabModel> get collabs => List.unmodifiable(_collabs);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get hasMore => _hasMore;
  String? get selectedFilter => _selectedFilter;

  List<CollabModel> get myCollabs => List.unmodifiable(_myCollabs);
  bool get isMyCollabsLoading => _isMyCollabsLoading;
  String? get myCollabsError => _myCollabsError;

  bool get isCreating => _isCreating;
  String? get createError => _createError;

  bool isDeleting(String id) => _deletingIds.contains(id);

  CollabModel? get selectedCollab => _selectedCollab;
  bool get isDetailLoading => _isDetailLoading;
  String? get detailError => _detailError;

  // ── Feed ───────────────────────────────────────────────

  /// Loads page 1, replacing existing data. Respects the current filter.
  Future<void> loadCollabs() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    _page = 1;
    _hasMore = true;
    _notify();

    try {
      final results = await _repository.getCollabs(
        page: _page,
        role: _selectedFilter,
      );
      _collabs = results;
      _hasMore = results.length >= kCollabPageSize;
      _page = 2;
    } catch (e) {
      _error = _parseError(e);
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  /// Appends the next page. No-op if already loading or at end.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    _notify();

    try {
      final results = await _repository.getCollabs(
        page: _page,
        role: _selectedFilter,
      );
      _collabs = [..._collabs, ...results];
      _hasMore = results.length >= kCollabPageSize;
      if (_hasMore) _page++;
    } catch (_) {
      // Silent — don't disrupt the existing list on pagination failure.
    } finally {
      _isLoadingMore = false;
      _notify();
    }
  }

  /// Updates the active filter and reloads from page 1.
  Future<void> setFilter(String? role) async {
    if (_selectedFilter == role) return;
    _selectedFilter = role;
    await loadCollabs();
  }

  void clearError() {
    _error = null;
    _notify();
  }

  // ── My Collabs ─────────────────────────────────────────

  /// Loads the authenticated creator's own collaboration posts.
  Future<void> loadMyCollabs() async {
    if (_isMyCollabsLoading) return;
    _isMyCollabsLoading = true;
    _myCollabsError = null;
    _notify();

    try {
      _myCollabs = await _repository.getMyCollabs();
    } catch (e) {
      _myCollabsError = _parseError(e);
    } finally {
      _isMyCollabsLoading = false;
      _notify();
    }
  }

  void clearMyCollabsError() {
    _myCollabsError = null;
    _notify();
  }

  // ── Detail ─────────────────────────────────────────────

  /// Fetches a single collab for the detail screen.
  Future<void> loadCollabById(String id) async {
    _isDetailLoading = true;
    _detailError = null;
    _selectedCollab = null;
    _notify();

    try {
      _selectedCollab = await _repository.getCollabById(id);
    } catch (e) {
      _detailError = _parseError(e);
    } finally {
      _isDetailLoading = false;
      _notify();
    }
  }

  void clearDetailError() {
    _detailError = null;
    _notify();
  }

  // ── Create ─────────────────────────────────────────────

  /// Creates a new collaboration post. Returns true on success.
  Future<bool> createCollab({
    required String title,
    required String description,
    required List<String> lookingFor,
    required List<String> genreStyle,
    required String paymentType,
  }) async {
    if (_isCreating) return false;
    _isCreating = true;
    _createError = null;
    _notify();

    try {
      final created = await _repository.createCollab(
        title: title,
        description: description,
        lookingFor: lookingFor,
        genreStyle: genreStyle,
        paymentType: paymentType,
      );
      // Prepend to my collabs list if it's been loaded.
      if (_myCollabs.isNotEmpty) {
        _myCollabs = [created, ..._myCollabs];
      }
      // Refresh the public feed so the new post appears immediately.
      unawaited(loadCollabs());
      return true;
    } catch (e) {
      _createError = _parseError(e);
      return false;
    } finally {
      _isCreating = false;
      _notify();
    }
  }

  /// Updates an existing collaboration post. Returns true on success.
  Future<bool> updateCollab({
    required String id,
    required String title,
    required String description,
    required List<String> lookingFor,
    required List<String> genreStyle,
    required String paymentType,
  }) async {
    if (_isCreating) return false;
    _isCreating = true;
    _createError = null;
    _notify();

    try {
      final updated = await _repository.updateCollab(id, {
        'title': title,
        'description': description,
        'looking_for': lookingFor,
        'genre_style': genreStyle,
        'payment_type': paymentType,
      });
      // Update in myCollabs list.
      _myCollabs = _myCollabs.map((c) => c.id == id ? updated : c).toList();
      // Update in feed list.
      _collabs = _collabs.map((c) => c.id == id ? updated : c).toList();
      // Update detail if it's the same collab.
      if (_selectedCollab?.id == id) _selectedCollab = updated;
      return true;
    } catch (e) {
      _createError = _parseError(e);
      return false;
    } finally {
      _isCreating = false;
      _notify();
    }
  }

  void clearCreateError() {
    _createError = null;
    _notify();
  }

  // ── Delete ─────────────────────────────────────────────

  /// Deletes a collaboration post. Waits for server (destructive action).
  /// Returns true on success.
  Future<bool> deleteCollab(String id) async {
    if (_deletingIds.contains(id)) return false;
    _deletingIds = {..._deletingIds, id};
    _notify();

    try {
      await _repository.deleteCollab(id);
      _myCollabs = _myCollabs.where((c) => c.id != id).toList();
      _collabs = _collabs.where((c) => c.id != id).toList();
      return true;
    } catch (e) {
      _myCollabsError = _parseError(e);
      return false;
    } finally {
      _deletingIds = {..._deletingIds}..remove(id);
      _notify();
    }
  }

  // ── Helpers ────────────────────────────────────────────

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _parseError(Object e) {
    if (e is ApiException) return e.message;
    if (e is UnauthorizedException) {
      return 'Session expired. Please log in again.';
    }
    return e.toString();
  }

  void reset() {
    _collabs = [];
    _isLoading = false;
    _isLoadingMore = false;
    _error = null;
    _page = 1;
    _hasMore = true;
    _selectedFilter = null;
    _myCollabs = [];
    _isMyCollabsLoading = false;
    _myCollabsError = null;
    _isCreating = false;
    _createError = null;
    _deletingIds = {};
    _selectedCollab = null;
    _isDetailLoading = false;
    _detailError = null;
  }

  @override
  void dispose() {
    _disposed = true;
    reset();
    super.dispose();
  }
}
