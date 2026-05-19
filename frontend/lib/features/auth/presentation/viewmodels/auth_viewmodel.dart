import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/spotify_constants.dart';
import '../../../../core/network/network_exceptions.dart';
import '../../../../core/services/onesignal_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

/// Possible states for the auth flow.
enum AuthStatus {
  /// Initial / unknown state.
  initial,

  /// OAuth browser opened — waiting for callback.
  awaitingOAuth,

  /// OTP sent — waiting for user to enter the code.
  awaitingOtp,

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

  // OTP state
  String? _pendingEmail;
  String? _otpError;
  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;

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

  // OTP getters
  String? get pendingEmail => _pendingEmail;
  String? get otpError => _otpError;
  int get resendSecondsRemaining => _resendSecondsRemaining;
  bool get canResendOtp => _resendSecondsRemaining == 0;

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
            // If we failed to load profile previously due to an expired token,
            // retry loading the profile now that we have a fresh one.
            if (_status != AuthStatus.profileLoaded && _status != AuthStatus.unauthenticated) {
              await _tryLoadProfile();
            }
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
              _status = AuthStatus.initial; // Keep splash screen while we load
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
  /// If the profile doesn't exist yet (new user), switches to `authenticated`.
  Future<void> _tryLoadProfile() async {
    try {
      _currentUser = await _repository.getCurrentUser();
      _status = AuthStatus.profileLoaded;
      OnesignalService.login(_currentUser!.id);
    } on UnauthorizedException catch (e) {
      if (e.message == 'User not found') {
        // Profile not set up yet — user needs onboarding
        _status = AuthStatus.authenticated;
      } else {
        // Token expired/invalid. Wait for tokenRefreshed or signedOut event.
        // Revert to initial to stay on splash screen, or unauthenticated if we must.
        debugPrint('[AuthViewmodel] Token invalid, waiting for refresh: ${e.message}');
        _status = AuthStatus.initial;
      }
    } catch (e) {
      // Network error or 500 error.
      // Do not drop the user into ProfileSetupScreen!
      debugPrint('[AuthViewmodel] Error loading profile: $e');
      _setError(e.toString());
      // Log them out to reset state, avoiding stuck on black screen / setup
      _status = AuthStatus.unauthenticated;
      await _repository.logout();
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

  // ── OTP Authentication ─────────────────────────────────

  /// Sends a 6-digit OTP code to the given email.
  Future<bool> sendOtp(String email) async {
    _setLoading(true);
    try {
      debugPrint('[AuthViewmodel] sendOtp → calling Supabase for: $email');
      await _repository.sendOtp(email);
      debugPrint('[AuthViewmodel] sendOtp → Supabase accepted, OTP sent');
      _pendingEmail = email;
      _otpError = null;
      _status = AuthStatus.awaitingOtp;
      _startResendTimer();
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('[AuthViewmodel] sendOtp FAILED: $e');
      debugPrint('$st');
      _setError('Failed to send code: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifies the OTP token using the pending email.
  Future<bool> verifyOtp(String token) async {
    if (_pendingEmail == null) {
      _otpError = 'No pending email found';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _otpError = null;
    notifyListeners();

    try {
      await _repository.verifyOtp(email: _pendingEmail!, token: token);
      // Success - auth state listener will handle navigation
      // Clear OTP state but don't reset() since auth is complete
      _pendingEmail = null;
      _resendTimer?.cancel();
      _resendSecondsRemaining = 0;
      return true;
    } on AuthException catch (e) {
      // Handle Supabase-specific OTP errors
      debugPrint('[AuthViewmodel] OTP verification failed: ${e.message}');
      debugPrint('[AuthViewmodel] Status code: ${e.statusCode}');
      
      if (e.message.toLowerCase().contains('expired') || 
          e.message.toLowerCase().contains('token')) {
        _otpError = 'Code expired. Please request a new one.';
        _resendSecondsRemaining = 0; // Allow immediate resend
      } else if (e.message.toLowerCase().contains('invalid') || 
                 e.message.toLowerCase().contains('otp')) {
        _otpError = 'Invalid code. Please try again.';
      } else {
        _otpError = e.message;
      }
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthViewmodel] OTP verification error: $e');
      _otpError = 'Verification failed. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Resends the OTP to the pending email.
  Future<bool> resendOtp() async {
    if (_pendingEmail == null) return false;
    if (!canResendOtp) return false;

    return await sendOtp(_pendingEmail!);
  }

  /// Starts the resend cooldown timer.
  void _startResendTimer() {
    _resendSecondsRemaining = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _resendSecondsRemaining--;
      notifyListeners();
      if (_resendSecondsRemaining <= 0) {
        timer.cancel();
      }
    });
  }

  /// Resets OTP state to idle.
  void reset() {
    _pendingEmail = null;
    _otpError = null;
    _resendTimer?.cancel();
    _resendSecondsRemaining = 0;
    _status = AuthStatus.initial; // idle state
    notifyListeners();
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
    } on UnauthorizedException catch (e) {
      if (e.message == 'User not found') {
        _status = AuthStatus.authenticated;
      } else {
        // Token expired or invalid — clear it
        await _repository.logout();
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      // transient error, remain in logged state but log out if needed manually
      _setError(e.toString());
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
    } on UnauthorizedException catch (e) {
      if (e.message == 'User not found') {
        _status = AuthStatus.authenticated;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
        await _repository.logout();
      }
    } catch (e) {
      // Do not clear _currentUser on a transient error
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ── Logout ─────────────────────────────────────────────

  /// Clears local state, persisted tokens, and Supabase session.
  Future<void> logout() async {
    await _repository.logout();
    OnesignalService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Permanently deletes the user's account, then clears local state.
  ///
  /// Throws on backend failure so the caller can surface an error; on
  /// success the auth listener navigates back to onboarding.
  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    OnesignalService.logout();
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
    _resendTimer?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
