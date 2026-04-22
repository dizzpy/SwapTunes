import 'package:swaptune/features/auth/data/models/user_model.dart';
import 'package:swaptune/features/collab/data/models/collab_model.dart';
import 'package:swaptune/features/discover/data/models/playlist_model.dart';
import 'package:swaptune/features/discover/data/models/source_platform.dart';
import 'package:swaptune/features/discover/data/models/suggested_user_model.dart';
import 'package:swaptune/features/feed/data/models/comment_model.dart';
import 'package:swaptune/features/feed/data/models/liker_model.dart';
import 'package:swaptune/features/feed/data/models/post_model.dart';
import 'package:swaptune/features/messaging/data/models/chat_conversation_model.dart';
import 'package:swaptune/features/messaging/data/models/message_model.dart';
import 'package:swaptune/features/notifications/data/models/notification_model.dart';
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
}) => PostModel(
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
}) => CommentModel(
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
}) => ChatConversationModel(
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
}) => MessageModel(
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

// ── Collabs ───────────────────────────────────────────────────────────────

CollabModel makeCollab({
  String id = 'collab-1',
  String title = 'Looking for a vocalist',
  String creatorId = 'user-creator',
  String paymentType = 'paid',
}) => CollabModel(
  id: id,
  creatorId: creatorId,
  title: title,
  description: 'Rock track collaboration',
  lookingFor: const ['vocalist'],
  genreStyle: const ['rock'],
  paymentType: paymentType,
  status: 'open',
  createdAt: DateTime(2024, 1, 1),
  creatorUsername: 'creator_user',
  creatorFullName: 'Creator User',
  creatorAvatarUrl: null,
  creatorIsVerified: true,
);

// ── Discover ──────────────────────────────────────────────────────────────

PlaylistModel makePlaylist({
  String id = 'playlist-1',
  String name = 'Test Playlist',
  bool isLiked = false,
}) => PlaylistModel(
  id: id,
  userId: 'user-1',
  spotifyPlaylistId: null,
  name: name,
  description: 'Test description',
  coverImageUrl: null,
  trackCount: 12,
  isPublic: true,
  sourcePlatform: SourcePlatform.other,
  primaryUrl: null,
  genreTags: const ['rock'],
  artists: const ['Artist 1'],
  moodTags: const ['energetic'],
  era: null,
  energyLevel: null,
  occasionTags: const [],
  vocalStyle: null,
  language: null,
  likesCount: 0,
  isLiked: isLiked,
  createdAt: DateTime(2024, 1, 1),
  updatedAt: null,
  ownerUsername: 'owner',
  ownerFullName: 'Owner Name',
  ownerAvatarUrl: null,
);

SuggestedUserModel makeSuggestedUser({
  String id = 'suggested-1',
  String username = 'suggested_user',
}) => SuggestedUserModel(
  id: id,
  fullName: 'Suggested User',
  username: username,
  avatarUrl: null,
  userType: 'listener',
);

// ── Notifications ─────────────────────────────────────────────────────────

NotificationModel makeNotification({
  String id = 'notif-1',
  bool isRead = false,
  String type = 'like',
}) => NotificationModel(
  id: id,
  type: type,
  isRead: isRead,
  createdAt: DateTime(2024, 1, 1),
  referenceId: 'ref-1',
  actorId: 'actor-1',
  actorName: 'Actor Name',
  actorUsername: 'actor_user',
  actorAvatarUrl: null,
);
