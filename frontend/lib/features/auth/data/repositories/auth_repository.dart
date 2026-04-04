import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Repository layer for authentication and profile setup operations.
///
/// Orchestrates between [SupabaseAuthService], [AuthRemoteDatasource],
/// [StorageService], and the domain models. All business/validation logic
/// lives here.
class AuthRepository {
  final AuthRemoteDatasource _datasource;
  final StorageService _storage;
  final SupabaseAuthService _supabaseAuth;

  AuthRepository({
    required AuthRemoteDatasource datasource,
    required StorageService storage,
    required SupabaseAuthService supabaseAuth,
  }) : _datasource = datasource,
       _storage = storage,
       _supabaseAuth = supabaseAuth;

  // ── Supabase Auth Accessors ────────────────────────────

  /// Stream of Supabase auth state changes.
  Stream<AuthState> get onAuthStateChange => _supabaseAuth.onAuthStateChange;

  /// Whether the user has an active Supabase session.
  bool get hasSupabaseSession => _supabaseAuth.isSignedIn;

  /// The current Supabase user, or null.
  User? get supabaseUser => _supabaseAuth.currentUser;

  // ── OAuth Sign-In ──────────────────────────────────────

  /// Initiates Google OAuth sign-in via Supabase.
  Future<void> signInWithGoogle() async {
    await _supabaseAuth.signInWithGoogle();
  }

  /// Initiates Spotify OAuth sign-in via Supabase.
  Future<void> signInWithSpotify() async {
    await _supabaseAuth.signInWithSpotify();
  }

  // ── OTP Sign-In ────────────────────────────────────────

  /// Sends a 6-digit OTP code to the given [email].
  Future<void> sendOtp(String email) async {
    await _supabaseAuth.sendOtp(email);
  }

  /// Verifies the OTP [token] for the given [email].
  /// Syncs the resulting JWT to storage on success.
  Future<void> verifyOtp({
    required String email,
    required String token,
  }) async {
    await _supabaseAuth.verifyOtp(email: email, token: token);
    await syncTokenToStorage();
  }

  // ── Session Handling ───────────────────────────────────

  /// Syncs the current Supabase JWT to local storage so the
  /// API client includes it in requests to the Express backend.
  Future<void> syncTokenToStorage() async {
    final token = _supabaseAuth.accessToken;
    if (token != null) {
      await _storage.saveToken(token);
    }
  }

  /// Handles a deep-link callback URI from OAuth / magic link.
  ///
  /// Recovers the session from the URI, stores the JWT, and
  /// returns `true` if sign-in was successful.
  Future<bool> handleAuthCallback(Uri uri) async {
    try {
      await _supabaseAuth.handleDeepLink(uri);
      await syncTokenToStorage();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Profile Setup ──────────────────────────────────────

  /// Creates the user profile on the backend after sign-up.
  Future<UserModel> setupProfile({
    required String fullName,
    required String username,
    String? bio,
    String? avatarUrl,
    required List<String> genres,
  }) async {
    final json = await _datasource.setupProfile(
      fullName: fullName,
      username: username,
      bio: bio,
      avatarUrl: avatarUrl,
      genres: genres,
    );
    final user = UserModel.fromJson(json);
    await _storage.saveUserId(user.id);
    return user;
  }

  /// Exchanges Spotify OAuth code via the backend.
  Future<void> connectSpotify(String code, String redirectUri) async {
    await _datasource.connectSpotify(code: code, redirectUri: redirectUri);
  }

  /// Fetches the authenticated user's profile from `/auth/me`.
  Future<UserModel> getCurrentUser() async {
    final json = await _datasource.getCurrentUser();
    return UserModel.fromJson(json);
  }

  /// Clears all locally stored auth data and signs out of Supabase.
  Future<void> logout() async {
    await _supabaseAuth.signOut();
    await _storage.clearAll();
  }

  /// Checks if a JWT token is persisted locally.
  bool get isLoggedIn => _storage.hasToken || _supabaseAuth.isSignedIn;
}
