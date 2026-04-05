import 'package:swaptune/features/auth/data/models/user_model.dart';
import 'package:swaptune/features/feed/data/models/comment_model.dart';
import 'package:swaptune/features/feed/data/models/liker_model.dart';
import 'package:swaptune/features/feed/data/models/post_model.dart';
import 'package:swaptune/features/messaging/data/models/chat_conversation_model.dart';
import 'package:swaptune/features/messaging/data/models/message_model.dart';
import 'package:swaptune/features/profile/data/models/full_profile_model.dart';

// ── Auth ──────────────────────────────────────────────────────────────────

final tUser = UserModel(
  id: 'user-1',
  fullName: 'Test User',
  username: 'testuser',
  userType: 'listener',
  spotifyConnected: false,
  isVerified: false,
  createdAt: DateTime(2024, 1, 1),
);

// ── Feed ──────────────────────────────────────────────────────────────────

PostModel makePost({
  String id = 'post-1',
  String userId = 'user-1',
  String content = 'Test post content',
  bool isLiked = false,
  int likesCount = 5,
  int commentsCount = 2,
}) =>
    PostModel(
      id: id,
      userId: userId,
      content: content,
      imageUrl: null,
      likesCount: likesCount,
      commentsCount: commentsCount,
      isLiked: isLiked,
      createdAt: DateTime(2024, 1, 1),
      authorUsername: 'testuser',
      authorFullName: 'Test User',
      authorAvatarUrl: null,
      authorIsVerified: false,
    );

final tPost = makePost();

CommentModel makeComment({
  String id = 'comment-1',
  String postId = 'post-1',
  String content = 'Test comment',
}) =>
    CommentModel(
      id: id,
      postId: postId,
      userId: 'user-1',
      content: content,
      createdAt: DateTime(2024, 1, 1),
      authorUsername: 'testuser',
      authorFullName: 'Test User',
    );

final tComment = makeComment();

final tLiker = LikerModel(
  id: 'user-2',
  username: 'otheruser',
  fullName: 'Other User',
);

// ── Messaging ─────────────────────────────────────────────────────────────

ChatConversationModel makeConversation({
  String id = 'convo-1',
  String participantId = 'user-2',
  String participantName = 'Other User',
  String participantUsername = 'other_user',
  String? participantAvatarUrl,
  String lastMessage = 'Hello!',
  int unreadCount = 0,
}) =>
    ChatConversationModel(
      id: id,
      participantId: participantId,
      participantName: participantName,
      participantUsername: participantUsername,
      participantAvatarUrl: participantAvatarUrl,
      isOnline: false,
      lastMessage: lastMessage,
      lastMessageAt: DateTime(2024, 1, 1, 12),
      unreadCount: unreadCount,
    );

final tConversation = makeConversation();

MessageModel makeMessage({
  String id = 'msg-1',
  String conversationId = 'convo-1',
  String senderId = 'user-1',
  String text = 'Hello!',
  bool isRead = false,
  bool isDeleted = false,
}) =>
    MessageModel(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      isRead: isRead,
      isDeleted: isDeleted,
      createdAt: DateTime(2024, 1, 1, 12),
    );

final tMessage = makeMessage();

// ── Profile ───────────────────────────────────────────────────────────────

final tStats = ProfileStats(
  followers: 100,
  following: 50,
  posts: 10,
  playlists: 3,
  collabs: 1,
);

final tProfile = FullProfileModel(
  id: 'user-1',
  fullName: 'Test User',
  username: 'testuser',
  bio: 'Test bio',
  avatarUrl: null,
  coverUrl: null,
  userType: 'listener',
  isVerified: false,
  spotifyConnected: false,
  createdAt: DateTime(2024, 1, 1),
  genres: ['pop', 'rock'],
  stats: tStats,
  isFollowing: false,
);

final tProfileFollowing = FullProfileModel(
  id: 'user-1',
  fullName: 'Test User',
  username: 'testuser',
  bio: 'Test bio',
  avatarUrl: null,
  coverUrl: null,
  userType: 'listener',
  isVerified: false,
  spotifyConnected: false,
  createdAt: DateTime(2024, 1, 1),
  genres: ['pop', 'rock'],
  stats: tStats,
  isFollowing: true,
);
