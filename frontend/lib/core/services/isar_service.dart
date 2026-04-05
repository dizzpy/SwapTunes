import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/feed/data/models/cached_post.dart';
import '../../features/messaging/data/models/cached_conversation.dart';
import '../../features/messaging/data/models/cached_messages.dart';
import '../../features/profile/data/models/cached_profile.dart';
import '../../features/profile/data/models/cached_user_post.dart';

/// Singleton that opens and holds the Isar database instance.
///
/// Call [IsarService.open] once in main.dart before runApp.
/// Repositories receive the [Isar] instance via constructor injection —
/// they never call [IsarService.open] themselves.
class IsarService {
  IsarService._();

  static Isar? _instance;

  static Future<Isar> open() async {
    if (_instance != null && _instance!.isOpen) return _instance!;
    final dir = await getApplicationDocumentsDirectory();
    _instance = await Isar.open(
      [CachedPostSchema, CachedProfileSchema, CachedUserPostSchema, CachedConversationSchema, CachedMessagesSchema],
      name: 'swaptunes',
      directory: dir.path,
    );
    return _instance!;
  }

  /// Exposed for tests that need to pass an already-open instance.
  static Isar? get instance => _instance;
}
