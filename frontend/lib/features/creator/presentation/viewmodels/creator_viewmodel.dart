import 'package:flutter/foundation.dart';

import '../../data/repositories/creator_repository.dart';

/// State for the creator setup and deactivation flows.
class CreatorViewmodel extends ChangeNotifier {
  final CreatorRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  CreatorViewmodel(this._repository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Upgrade to creator or re-activate a previously deactivated account.
  Future<bool> setupCreator({
    required String roleTitle,
    required List<String> specializations,
    String? location,
    String? soundcloudUrl,
    String? youtubeUrl,
    String? spotifyArtistUrl,
    String? appleMusicUrl,
    String? portfolioUrl,
  }) async {
    _setLoading(true);
    try {
      await _repository.setupCreator(
        roleTitle: roleTitle,
        specializations: specializations,
        location: location,
        soundcloudUrl: soundcloudUrl,
        youtubeUrl: youtubeUrl,
        spotifyArtistUrl: spotifyArtistUrl,
        appleMusicUrl: appleMusicUrl,
        portfolioUrl: portfolioUrl,
      );
      return true;
    } catch (e) {
      _setError(_extractMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Switch back to listener mode.
  Future<bool> deactivateCreator() async {
    _setLoading(true);
    try {
      await _repository.deactivateCreator();
      return true;
    } catch (e) {
      _setError(_extractMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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

  String _extractMessage(Object e) {
    if (e is Exception) return e.toString().replaceFirst('Exception: ', '');
    return e.toString();
  }
}
