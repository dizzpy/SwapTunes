import 'package:mocktail/mocktail.dart';
import 'package:swaptune/features/auth/data/repositories/auth_repository.dart';
import 'package:swaptune/features/feed/data/datasources/feed_remote_datasource.dart';
import 'package:swaptune/features/feed/data/repositories/feed_repository.dart';
import 'package:swaptune/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:swaptune/features/profile/data/repositories/profile_repository.dart';

// ── Repository mocks (used in unit tests) ─────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

class MockFeedRepository extends Mock implements FeedRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

// ── Datasource mocks (used in integration tests) ──────────────────────────

class MockFeedRemoteDatasource extends Mock implements FeedRemoteDatasource {}

class MockProfileRemoteDatasource extends Mock
    implements ProfileRemoteDatasource {}
