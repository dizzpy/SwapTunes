import 'package:flutter/foundation.dart';

import '../../../../core/network/network_exceptions.dart';
import '../../data/models/collab_match_result.dart';
import '../../data/repositories/collab_repository.dart';

enum CollabMatchState { idle, loading, loaded, error }

/// State management for AI Collab Match.
///
/// Keeps [_matches] cached in memory after load so [MessageRecipientSheet]
/// can read them for auto-suggestions without a second API call.
class CollabMatchViewModel extends ChangeNotifier {
  final CollabRepository _repository;
  bool _disposed = false;

  CollabMatchState _state = CollabMatchState.idle;
  List<CollabMatchResult> _matches = [];
  String? _errorMessage;

  CollabMatchViewModel(this._repository);

  CollabMatchState get state => _state;
  List<CollabMatchResult> get matches => List.unmodifiable(_matches);
  String? get errorMessage => _errorMessage;

  Future<void> fetchMatches(String collabId) async {
    if (_state == CollabMatchState.loading) return;
    _state = CollabMatchState.loading;
    _matches = [];
    _errorMessage = null;
    _notify();

    try {
      _matches = await _repository.getCollabMatches(collabId);
      _state = CollabMatchState.loaded;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = CollabMatchState.error;
    }

    _notify();
  }

  void reset() {
    _state = CollabMatchState.idle;
    _matches = [];
    _errorMessage = null;
    _notify();
  }

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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
