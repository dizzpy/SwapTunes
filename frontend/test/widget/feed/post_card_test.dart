import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:swaptune/features/auth/data/models/user_model.dart';
import 'package:swaptune/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:swaptune/features/feed/data/models/comment_model.dart';
import 'package:swaptune/features/feed/data/models/liker_model.dart';
import 'package:swaptune/features/feed/data/models/post_model.dart';
import 'package:swaptune/features/feed/presentation/viewmodels/feed_viewmodel.dart';
import 'package:swaptune/features/feed/presentation/widgets/post_card.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────

class _FakeAuthViewmodel extends ChangeNotifier implements AuthViewmodel {
  @override
  UserModel? get currentUser => null;
  @override
  User? get supabaseUser => null;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  AuthStatus get status => AuthStatus.initial;
  @override
  bool get isAuthenticated => false;
  @override
  bool get isLoggedIn => false;
  
  // OTP getters
  @override
  String? get pendingEmail => null;
  @override
  String? get otpError => null;
  @override
  int get resendSecondsRemaining => 0;
  @override
  bool get canResendOtp => true;
  
  @override
  Future<void> signInWithGoogle() async {}
  @override
  Future<void> signInWithSpotify() async {}
  @override
  Future<bool> sendOtp(String email) async => false;
  @override
  Future<bool> verifyOtp(String token) async => false;
  @override
  Future<bool> resendOtp() async => false;
  @override
  void reset() {}
  @override
  Future<bool> handleDeepLink(Uri uri) async => false;
  @override
  Future<void> tryAutoLogin() async {}
  @override
  Future<bool> setupProfile({
    required String fullName,
    required String username,
    String? bio,
    String? avatarUrl,
    required List<String> genres,
  }) async =>
      false;
  @override
  Future<String?> launchSpotifyConnect() async => null;
  @override
  void handleSpotifyConnectCallback(Uri uri) {}
  @override
  void cancelSpotifyConnect() {}
  @override
  Future<bool> connectSpotify(String code, String redirectUri) async => false;
  @override
  Future<void> refreshCurrentUser() async {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> deleteAccount() async {}
  @override
  void clearError() {}
}

class _FakeFeedViewmodel extends ChangeNotifier implements FeedViewmodel {
  final List<String> calls = [];

  @override
  List<PostModel> get posts => [];
  @override
  bool get isLoading => false;
  @override
  bool get isLoadingMore => false;
  @override
  String? get feedError => null;
  @override
  bool get hasMore => false;
  @override
  List<CommentModel> get comments => [];
  @override
  bool get isCommentsLoading => false;
  @override
  String? get commentError => null;
  @override
  List<LikerModel> get likers => [];
  @override
  bool get isLikersLoading => false;
  @override
  bool get isCreating => false;
  @override
  String? get createError => null;

  @override
  void toggleLike(String postId) => calls.add('toggleLike:$postId');

  @override
  Future<void> loadFeed({bool forceRefresh = false}) async {}
  @override
  Future<void> loadMore() async {}
  @override
  void createPost({
    required String content,
    required String userId,
    required String authorUsername,
    required String authorFullName,
    String? authorAvatarUrl,
    dynamic images,
  }) {}
  @override
  void clearCreateError() {}
  @override
  Future<bool> updatePost(String postId, String content,
          {dynamic newImage, bool removeImage = false}) async =>
      false;
  @override
  Future<void> deletePost(String postId) async =>
      calls.add('deletePost:$postId');
  @override
  Future<void> hidePost(String postId) async => calls.add('hidePost:$postId');
  @override
  Future<void> reportPost(String postId, String reason) async =>
      calls.add('reportPost:$postId');
  @override
  Future<void> loadComments(String postId) async {}
  @override
  Future<bool> addComment(
    String postId,
    String content, {
    required String userId,
    required String authorUsername,
    required String authorFullName,
    String? authorAvatarUrl,
  }) async =>
      false;
  @override
  Future<void> deleteComment(String postId, String commentId) async {}
  @override
  Future<bool> updateComment(
          String postId, String commentId, String content) async =>
      false;
  @override
  void clearCommentError() {}
  @override
  Future<void> loadLikers(String postId) async {}
}

// ── Helpers ────────────────────────────────────────────────────────────────

Widget _buildSubject({
  required _FakeAuthViewmodel authVm,
  required _FakeFeedViewmodel feedVm,
  bool isLiked = false,
  bool isOwnPost = false,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewmodel>.value(value: authVm),
      ChangeNotifierProvider<FeedViewmodel>.value(value: feedVm),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: PostCard(
          postId: 'post-1',
          userName: 'testuser',
          authorName: 'Test User',
          isVerified: false,
          avatarUrl: '',
          imageUrl: null,
          caption: 'Test post content',
          likes: '5 Likes',
          comments: '2 Comment',
          isLiked: isLiked,
          isOwnPost: isOwnPost,
          timeAgo: '1h ago',
        ),
      ),
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late _FakeAuthViewmodel fakeAuth;
  late _FakeFeedViewmodel fakeFeed;

  setUp(() {
    fakeAuth = _FakeAuthViewmodel();
    fakeFeed = _FakeFeedViewmodel();
  });

  testWidgets('renders without throwing', (tester) async {
    await tester.pumpWidget(
        _buildSubject(authVm: fakeAuth, feedVm: fakeFeed));
    await tester.pump();
    expect(find.byType(PostCard), findsOneWidget);
  });

  testWidgets('shows caption text', (tester) async {
    await tester.pumpWidget(
        _buildSubject(authVm: fakeAuth, feedVm: fakeFeed));
    await tester.pump();
    expect(find.text('Test post content'), findsOneWidget);
  });

  testWidgets('shows username', (tester) async {
    await tester.pumpWidget(
        _buildSubject(authVm: fakeAuth, feedVm: fakeFeed));
    await tester.pump();
    expect(find.text('testuser'), findsOneWidget);
  });

  testWidgets('shows likes and comments counts', (tester) async {
    await tester.pumpWidget(
        _buildSubject(authVm: fakeAuth, feedVm: fakeFeed));
    await tester.pump();
    expect(find.text('5 Likes'), findsOneWidget);
    expect(find.text('2 Comment'), findsOneWidget);
  });

  testWidgets('tapping like button calls toggleLike with correct postId',
      (tester) async {
    await tester.pumpWidget(
        _buildSubject(authVm: fakeAuth, feedVm: fakeFeed));
    await tester.pump();

    // Tapping '5 Likes' text opens the likes sheet (inner GestureDetector).
    // Tap the icon area (left side of the outer button GestureDetector) to
    // trigger _toggleLike instead.
    final outerLikeButton = find
        .ancestor(
          of: find.text('5 Likes'),
          matching: find.byType(GestureDetector),
        )
        .at(1); // at(0) = inner label GD (opens sheet), at(1) = outer button GD
    final rect = tester.getRect(outerLikeButton);
    await tester.tapAt(Offset(rect.left + 8, rect.center.dy));
    await tester.pump();

    expect(fakeFeed.calls, contains('toggleLike:post-1'));
  });
}
