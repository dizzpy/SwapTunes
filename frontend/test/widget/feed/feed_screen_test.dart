import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import 'package:swaptune/core/network/api_client.dart';
import 'package:swaptune/core/network/api_interceptor.dart';
import 'package:swaptune/core/services/storage_service.dart';
import 'package:swaptune/features/auth/data/models/user_model.dart';
import 'package:swaptune/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:swaptune/features/feed/data/models/comment_model.dart';
import 'package:swaptune/features/feed/data/models/liker_model.dart';
import 'package:swaptune/features/feed/data/models/post_model.dart';
import 'package:swaptune/features/feed/presentation/screens/feed_screen.dart';
import 'package:swaptune/features/feed/presentation/viewmodels/feed_viewmodel.dart';
import 'package:swaptune/features/feed/presentation/widgets/post_card.dart';
import 'package:swaptune/features/feed/presentation/widgets/post_input_box.dart';

import '../../helpers/fixtures.dart';

class _FakeStorageService extends StorageService {
  @override
  String? getUserId() => 'user-1';

  @override
  String? getToken() => null;
}

class _FakeAuthViewmodel extends ChangeNotifier implements AuthViewmodel {
  @override
  UserModel? get currentUser => tUser;
  @override
  User? get supabaseUser => null;
  @override
  bool get isLoading => false;
  @override
  String? get errorMessage => null;
  @override
  AuthStatus get status => AuthStatus.profileLoaded;
  @override
  bool get isAuthenticated => true;
  @override
  bool get isLoggedIn => true;

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
  }) async => false;
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
  void clearError() {}
}

class _FakeFeedViewmodel extends ChangeNotifier implements FeedViewmodel {
  final List<String> calls = [];

  List<PostModel> _posts;
  final bool _isLoading;
  final bool _isLoadingMore;
  final String? _feedError;

  _FakeFeedViewmodel({
    List<PostModel>? posts,
    bool isLoading = false,
    bool isLoadingMore = false,
    String? feedError,
  }) : _posts = posts ?? [],
       _isLoading = isLoading,
       _isLoadingMore = isLoadingMore,
       _feedError = feedError;

  @override
  List<PostModel> get posts => _posts;
  @override
  bool get isLoading => _isLoading;
  @override
  bool get isLoadingMore => _isLoadingMore;
  @override
  String? get feedError => _feedError;
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
  Future<void> loadFeed({bool forceRefresh = false}) async {
    calls.add('loadFeed');
  }

  @override
  Future<void> loadMore() async {
    calls.add('loadMore');
  }

  @override
  void toggleLike(String postId) {
    calls.add('toggleLike:$postId');
  }

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
  Future<bool> updatePost(
    String postId,
    String content, {
    dynamic newImage,
    bool removeImage = false,
  }) async => false;

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> hidePost(String postId) async {}

  @override
  Future<void> reportPost(String postId, String reason) async {}

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
  }) async => false;

  @override
  Future<void> deleteComment(String postId, String commentId) async {}

  @override
  Future<bool> updateComment(
    String postId,
    String commentId,
    String content,
  ) async => false;

  @override
  void clearCommentError() {}

  @override
  Future<void> loadLikers(String postId) async {}
}

Widget _buildSubject(_FakeFeedViewmodel feedVm) {
  final storage = _FakeStorageService();
  final api = ApiClient(
    interceptor: ApiInterceptor(storage),
    client: MockClient((_) async => http.Response('[]', 200)),
  );

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthViewmodel>.value(value: _FakeAuthViewmodel()),
      ChangeNotifierProvider<FeedViewmodel>.value(value: feedVm),
      Provider<ApiClient>.value(value: api),
      Provider<StorageService>.value(value: storage),
    ],
    child: const MaterialApp(home: FeedScreen(enableNotifications: false)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders loading skeleton when feed is loading', (tester) async {
    final vm = _FakeFeedViewmodel(isLoading: true);

    await tester.pumpWidget(_buildSubject(vm));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(PostCard), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('renders post cards when posts are loaded', (tester) async {
    final vm = _FakeFeedViewmodel(
      posts: [
        makePost(id: 'p1'),
        makePost(id: 'p2'),
      ],
    );

    await tester.pumpWidget(_buildSubject(vm));
    await tester.pump();

    expect(find.byType(PostCard), findsNWidgets(2));
  });

  testWidgets('renders error with retry when feed has failed and no posts', (
    tester,
  ) async {
    final vm = _FakeFeedViewmodel(feedError: 'load failed', posts: []);

    await tester.pumpWidget(_buildSubject(vm));
    await tester.pump();

    expect(find.text('load failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('renders input box and no post cards when feed list is empty', (
    tester,
  ) async {
    final vm = _FakeFeedViewmodel(posts: []);

    await tester.pumpWidget(_buildSubject(vm));
    await tester.pump();

    expect(find.byType(PostInputBox), findsOneWidget);
    expect(find.byType(PostCard), findsNothing);
  });

  testWidgets('tapping like on a post calls toggleLike with postId', (
    tester,
  ) async {
    final vm = _FakeFeedViewmodel(posts: [makePost(id: 'post-1')]);

    await tester.pumpWidget(_buildSubject(vm));
    await tester.pump();

    final likeButton = find
        .ancestor(
          of: find.text('5 Likes'),
          matching: find.byType(GestureDetector),
        )
        .at(1);
    final rect = tester.getRect(likeButton);
    await tester.tapAt(Offset(rect.left + 8, rect.center.dy));
    await tester.pump();

    expect(vm.calls, contains('toggleLike:post-1'));
  });
}
