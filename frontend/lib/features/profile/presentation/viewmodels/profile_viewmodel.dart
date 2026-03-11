import 'package:flutter/foundation.dart';

import '../../../auth/data/repositories/auth_repository.dart';

/// Profile viewmodel for the profile setup and edit screens.
///
/// Manages form state, validation, and API submission.
class ProfileViewmodel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  ProfileViewmodel(this._authRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Submits the profile setup form to the backend.
  Future<bool> submitProfileSetup({
    required String fullName,
    required String username,
    String? bio,
    String? avatarUrl,
    required List<String> genres,
  }) async {
    _setLoading(true);
    try {
      await _authRepository.setupProfile(
        fullName: fullName,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
        genres: genres,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
