import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/supabase_constants.dart';

/// Centralized service for all Supabase authentication operations.
///
/// Wraps the Supabase Flutter SDK to provide Google OAuth, Spotify OAuth,
/// and Magic Link sign-in flows. Exposes session state via streams and
/// getters so the rest of the app can react to auth changes.
class SupabaseAuthService {
  late final SupabaseClient _client;
  late final GoTrueClient _auth;

  /// Whether [init] has been called successfully.
  bool _initialized = false;

  // ── Initialization ─────────────────────────────────────

  /// Initializes the Supabase SDK. Must be called once in `main()`.
  Future<void> init() async {
    await Supabase.initialize(
      url: SupabaseConstants.url,
      anonKey: SupabaseConstants.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    _client = Supabase.instance.client;
    _auth = _client.auth;
    _initialized = true;

    debugPrint('[SupabaseAuthService] Initialized');
  }

  // ── Getters ────────────────────────────────────────────

  /// The underlying Supabase client (for advanced usage).
  SupabaseClient get client {
    assert(_initialized, 'SupabaseAuthService.init() must be called first');
    return _client;
  }

  /// The current Supabase auth session, or null if not signed in.
  Session? get currentSession => _auth.currentSession;

  /// The current Supabase user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// The current JWT access token, or null.
  String? get accessToken => currentSession?.accessToken;

  /// Whether the user is currently signed in with a valid session.
  bool get isSignedIn => currentSession != null;

  /// Stream of auth state changes (sign in, sign out, token refresh, etc.).
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  // ── Google OAuth ───────────────────────────────────────

  /// Initiates Google OAuth sign-in via Supabase.
  ///
  /// Opens the system browser for the Google consent screen.
  /// The result is delivered via deep link → [onAuthStateChange].
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConstants.redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  // ── Spotify OAuth ──────────────────────────────────────

  /// Initiates Spotify OAuth sign-in via Supabase.
  ///
  /// Opens the system browser for the Spotify authorization screen.
  /// Requires Spotify provider to be enabled in Supabase Dashboard →
  /// Authentication → Providers → Spotify.
  Future<void> signInWithSpotify() async {
    await _auth.signInWithOAuth(
      OAuthProvider.spotify,
      redirectTo: SupabaseConstants.redirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  // ── Magic Link ─────────────────────────────────────────

  /// Sends a magic link to the given [email] for passwordless login.
  ///
  /// The user receives an email with a link that, when tapped,
  /// opens the app via deep link and completes sign-in automatically.
  Future<void> signInWithMagicLink(String email) async {
    await _auth.signInWithOtp(
      email: email,
      emailRedirectTo: SupabaseConstants.redirectUrl,
    );
  }

  // ── Session Management ─────────────────────────────────

  /// Manually refreshes the current session to get a new JWT.
  Future<AuthResponse> refreshSession() async {
    return await _auth.refreshSession();
  }

  /// Signs the user out and clears the Supabase session.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Recovers a session from a deep-link URI (OAuth/magic-link callback).
  ///
  /// Call this when the app receives a deep link matching [SupabaseConstants.redirectScheme].
  /// Returns the recovered session, or null if the URI wasn't a valid callback.
  Future<AuthSessionUrlResponse> handleDeepLink(Uri uri) async {
    return await _auth.getSessionFromUrl(uri);
  }
}
