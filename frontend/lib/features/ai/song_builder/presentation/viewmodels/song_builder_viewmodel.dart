import 'package:flutter/foundation.dart';

import '../../../../../core/network/network_exceptions.dart';
import '../../data/models/song_builder_model.dart';
import '../../data/repositories/song_builder_repository.dart';

enum SongBuilderState { idle, loading, loaded, error }

/// State management for the AI Song Builder feature.
///
/// Stores last inputs so [regenerate] can re-submit without the user
/// having to re-fill the form.
class SongBuilderViewModel extends ChangeNotifier {
  final SongBuilderRepository _repository;
  bool _disposed = false;

  SongBuilderState _state = SongBuilderState.idle;
  SongBuilderResult? _result;
  String? _errorMessage;

  bool _isSaving = false;
  bool _isSaved = false;
  String? _saveError;

  String? _lastIdea;
  String? _lastGenre;
  String? _lastLyrics;
  String? _lastType;

  SongBuilderViewModel(this._repository);

  SongBuilderState get state => _state;
  SongBuilderResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  bool get isSaved => _isSaved;
  String? get saveError => _saveError;

  Future<void> build({
    required String idea,
    required String genre,
    String? lyrics,
    required String type,
  }) async {
    _lastIdea = idea;
    _lastGenre = genre;
    _lastLyrics = lyrics;
    _lastType = type;

    _state = SongBuilderState.loading;
    _errorMessage = null;
    _notify();

    try {
      _result = await _repository.buildSong(
        idea: idea,
        genre: genre,
        lyrics: lyrics,
        type: type,
      );
      _state = SongBuilderState.loaded;
    } catch (e) {
      _errorMessage = _parseError(e);
      _state = SongBuilderState.error;
    }

    _notify();
  }

  Future<void> regenerate() async {
    if (_lastIdea == null) return;
    _isSaved = false;
    await build(
      idea: _lastIdea!,
      genre: _lastGenre!,
      lyrics: _lastLyrics,
      type: _lastType!,
    );
  }

  Future<void> savePlan() async {
    if (_result == null || _isSaving || _isSaved) return;
    _isSaving = true;
    _saveError = null;
    _notify();

    try {
      await _repository.savePlan(_result!);
      _isSaved = true;
    } catch (e) {
      _saveError = _parseError(e);
    }

    _isSaving = false;
    _notify();
  }

  void reset() {
    _state = SongBuilderState.idle;
    _result = null;
    _errorMessage = null;
    _isSaving = false;
    _isSaved = false;
    _saveError = null;
    _lastIdea = null;
    _lastGenre = null;
    _lastLyrics = null;
    _lastType = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  String _parseError(Object e) {
    if (e is ApiException) return e.message;
    if (e is UnauthorizedException) return 'Session expired. Please log in again.';
    return e.toString();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
