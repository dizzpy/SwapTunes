import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/spotify_constants.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Possible states for the auth flow.
enum AuthStatus {
  /// Initial / unknown state.
  initial,

  /// OAuth browser opened — waiting for callback.
  awaitingOAuth,

  /// Magic link sent — waiting for user to tap the email link.
  awaitingMagicLink,

  /// User authenticated but profile not yet set up.
  authenticated,

  /// Fully signed in with profile loaded.
  profileLoaded,

  /// Not signed in.
  unauthenticated,
}

/// Auth state management for the presentation layer.
///
/// Exposes loading, error, user state, and auth status to UI widgets
/// via the Provider ChangeNotifier pattern.
class AuthViewmodel extends ChangeNotifier {
  final AuthRepository _repository;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  AuthStatus _status = AuthStatus.initial;

  StreamSubscription<AuthState>? _authSubscription;

  AuthViewmodel(this._repository) {
    _listenToAuthChanges();
  }

  // ── Getters ────────────────────────────────────────────

  UserModel? get currentUser => _currentUser;
  User? get supabaseUser => _repository.supabaseUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AuthStatus get status => _status;

  /// Whether the user object is loaded in memory.
  bool get isAuthenticated => _currentUser != null;

  /// Whether a saved JWT token exists locally or a Supabase session is active.
  bool get isLoggedIn => _repository.isLoggedIn;

  // ── Auth State Listener ────────────────────────────────

  /// Listens to Supabase auth state changes and reacts accordingly.
  void _listenToAuthChanges() {
    _authSubscription = _repository.onAuthStateChange.listen(
      (AuthState authState) async {
        final event = authState.event;
        debugPrint('[AuthViewmodel] Auth event: $event');

        switch (event) {
          case AuthChangeEvent.signedIn:
            // User just signed in — sync token and load profile.
            // Do NOT notify until _tryLoadProfile resolves so the
            // navigation gate sees the final status in one step.
            await _repository.syncTokenToStorage();
            _status = AuthStatus.authenticated;
            await _tryLoadProfile();
            break;

          case AuthChangeEvent.tokenRefreshed:
            // Token was refreshed — re-sync to storage
            await _repository.syncTokenToStorage();
            break;

          case AuthChangeEvent.signedOut:
            _currentUser = null;
            _status = AuthStatus.unauthenticated;
            notifyListeners();
            break;

          case AuthChangeEvent.initialSession:
            // App launch — check if there's an existing session.
            // Do NOT notify until _tryLoadProfile resolves so the
            // navigation gate sees the final status in one step.
            if (_repository.hasSupabaseSession) {
              await _repository.syncTokenToStorage();
              _status = AuthStatus.authenticated;
              await _tryLoadProfile();
            } else {
              _status = AuthStatus.unauthenticated;
              notifyListeners();
            }
            break;

          default:
            break;
        }
      },
      onError: (error) {
        debugPrint('[AuthViewmodel] Auth stream error: $error');
      },
    );
  }

  /// Attempts to load the user profile from the backend.
  /// If the profile doesn't exist yet (new user), stays in `authenticated`.
  Future<void> _tryLoadProfile() async {
    try {
      _currentUser = await _repository.getCurrentUser();
      _status = AuthStatus.profileLoaded;
    } catch (_) {
      // Profile not set up yet — user needs onboarding
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  // ── Google OAuth ───────────────────────────────────────

  /// Initiates Google sign-in via Supabase OAuth.
  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      await _repository.signInWithGoogle();
      _status = AuthStatus.awaitingOAuth;
      notifyListeners();
    } catch (e) {
      _setError('Google sign-in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ── Spotify OAuth ──────────────────────────────────────

  /// Initiates Spotify sign-in via Supabase OAuth.
  Future<void> signInWithSpotify() async {
    _setLoading(true);
    try {
      await _repository.signInWithSpotify();
      _status = AuthStatus.awaitingOAuth;
      notifyListeners();
    } catch (e) {
      _setError('Spotify sign-in failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // ── Magic Link ─────────────────────────────────────────

  /// Sends a magic link to the given email.
  Future<bool> sendMagicLink(String email) async {
    _setLoading(true);
    try {
      await _repository.signInWithMagicLink(email);
      _status = AuthStatus.awaitingMagicLink;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Magic link failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Deep Link Handling ─────────────────────────────────

  /// Handles an incoming deep-link URI (OAuth/magic-link callback).
  Future<bool> handleDeepLink(Uri uri) async {
    _setLoading(true);
    try {
      final success = await _repository.handleAuthCallback(uri);
      if (success) {
        _status = AuthStatus.authenticated;
        notifyListeners();
        await _tryLoadProfile();
      }
      return success;
    } catch (e) {
      _setError('Auth callback failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Auto Login ─────────────────────────────────────────

  /// Attempts to restore the session from stored token on app startup.
  /// Call this once from `main.dart` or the root widget.
  Future<void> tryAutoLogin() async {
    if (!_repository.isLoggedIn) return;

    _setLoading(true);
    try {
      _currentUser = await _repository.getCurrentUser();
      _status = AuthStatus.profileLoaded;
    } catch (_) {
      // Token expired or invalid — clear it
      await _repository.logout();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } finally {
      _setLoading(false);
    }
  }

  // ── Profile Setup ──────────────────────────────────────

  /// Submits the user's profile to `POST /auth/profile/setup`.
  Future<bool> setupProfile({
    required String fullName,
    required String username,
    String? bio,
    String? avatarUrl,
    required List<String> genres,
  }) async {
    _setLoading(true);
    try {
      _currentUser = await _repository.setupProfile(
        fullName: fullName,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
        genres: genres,
      );
      _status = AuthStatus.profileLoaded;
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Spotify Connect ────────────────────────────────────

  Completer<String?>? _spotifyConnectCompleter;

  /// Opens Spotify authorization page in the browser.
  /// Returns the auth code when the callback deep link arrives, or null
  /// if the user cancelled or an error occurred.
  Future<String?> launchSpotifyConnect() async {
    _spotifyConnectCompleter = Completer<String?>();

    final url = SpotifyConstants.buildAuthorizationUrl();
    await launchUrl(url, mode: LaunchMode.externalApplication);

    return _spotifyConnectCompleter!.future;
  }

  /// Called by the deep link handler when a `spotify-connect` callback arrives.
  void handleSpotifyConnectCallback(Uri uri) {
    final code = uri.queryParameters['code'];
    final error = uri.queryParameters['error'];

    if (_spotifyConnectCompleter != null &&
        !_spotifyConnectCompleter!.isCompleted) {
      if (error != null || code == null) {
        _spotifyConnectCompleter!.complete(null);
      } else {
        _spotifyConnectCompleter!.complete(code);
      }
    }
    _spotifyConnectCompleter = null;
  }

  /// Cancels a pending Spotify connect flow (e.g. user navigated away).
  void cancelSpotifyConnect() {
    if (_spotifyConnectCompleter != null &&
        !_spotifyConnectCompleter!.isCompleted) {
      _spotifyConnectCompleter!.complete(null);
    }
    _spotifyConnectCompleter = null;
  }

  /// Exchanges Spotify OAuth code via `POST /auth/spotify/connect`.
  Future<bool> connectSpotify(String code, String redirectUri) async {
    _setLoading(true);
    try {
      await _repository.connectSpotify(code, redirectUri);
      await refreshCurrentUser();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ── Current User ───────────────────────────────────────

  /// Fetches fresh user data from `GET /auth/me`.
  Future<void> refreshCurrentUser() async {
    _setLoading(true);
    try {
      _currentUser = await _repository.getCurrentUser();
      _status = AuthStatus.profileLoaded;
    } catch (e) {
      _currentUser = null;
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ─────────────────────────────────────────────

  /// Clears local state, persisted tokens, and Supabase session.
  Future<void> logout() async {
    await _repository.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Internal Helpers ───────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    if (value) _errorMessage = null;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
