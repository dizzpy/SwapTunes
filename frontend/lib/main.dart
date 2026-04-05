import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/network/api_client.dart';
import 'core/services/onesignal_service.dart';
import 'core/network/api_interceptor.dart';
import 'core/services/isar_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/supabase_auth_service.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'features/feed/data/datasources/feed_remote_datasource.dart';
import 'features/feed/data/repositories/feed_repository.dart';
import 'features/feed/presentation/viewmodels/feed_viewmodel.dart';
import 'features/onboarding/data/repositories/onboarding_repository.dart';
import 'features/onboarding/presentation/viewmodels/onboarding_viewmodel.dart';
import 'features/discover/data/datasources/discover_remote_datasource.dart';
import 'features/discover/data/repositories/discover_repository.dart';
import 'features/messaging/data/datasources/messaging_remote_datasource.dart';
import 'features/messaging/data/repositories/messaging_repository.dart';
import 'features/creator/data/datasources/creator_remote_datasource.dart';
import 'features/creator/data/repositories/creator_repository.dart';
import 'features/creator/presentation/viewmodels/creator_viewmodel.dart';
import 'features/profile/data/datasources/profile_remote_datasource.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'features/collab/data/datasources/collab_remote_datasource.dart';
import 'features/collab/data/repositories/collab_repository.dart';
import 'features/collab/presentation/viewmodels/collab_viewmodel.dart';

/// Entry point for the SwapTunes application.
///
/// Initializes core services (Supabase, storage, network)
/// and wires up all providers before launching the app.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  // Initialize OneSignal push notifications
  await OnesignalService.initialize();

  // Initialize Supabase
  final supabaseAuthService = SupabaseAuthService();
  await supabaseAuthService.init();

  // Initialize core services
  final storageService = StorageService();
  await storageService.init();

  // Sync Supabase token to StorageService so the API client uses it
  final currentToken = supabaseAuthService.accessToken;
  if (currentToken != null) {
    await storageService.saveToken(currentToken);
  }

  // Build network layer
  final interceptor = ApiInterceptor(storageService);
  final apiClient = ApiClient(interceptor: interceptor);

  // Open Isar database
  final isar = await IsarService.open();

  // Build data layer
  final authDatasource = AuthRemoteDatasource(apiClient);
  final authRepository = AuthRepository(
    datasource: authDatasource,
    storage: storageService,
    supabaseAuth: supabaseAuthService,
  );
  final onboardingRepository = OnboardingRepository(storageService);
  final feedRepository = FeedRepository(
    FeedRemoteDatasource(apiClient, interceptor),
    isar,
  );
  final profileRepository = ProfileRepository(
    apiClient,
    ProfileRemoteDatasource(apiClient, interceptor),
    isar,
  );
  final discoverRepository = DiscoverRepository(
    DiscoverRemoteDatasource(apiClient, interceptor),
  );
  final messagingRepository = MessagingRepository(
    MessagingRemoteDatasource(apiClient),
    storageService,
    isar,
  );
  final creatorRepository = CreatorRepository(
    CreatorRemoteDatasource(apiClient),
  );
  final collabRepository = CollabRepository(
    CollabRemoteDatasource(apiClient),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewmodel(authRepository)),
        ChangeNotifierProvider(
          create: (_) => OnboardingViewmodel(onboardingRepository),
        ),
        ChangeNotifierProvider(create: (_) => ProfileViewmodel(authRepository)),
        ChangeNotifierProvider(create: (_) => FeedViewmodel(feedRepository)),
        ChangeNotifierProvider(
          create: (_) => CreatorViewmodel(creatorRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CollabViewmodel(collabRepository),
        ),
        Provider<ApiClient>.value(value: apiClient),
        Provider<ProfileRepository>.value(value: profileRepository),
        Provider<DiscoverRepository>.value(value: discoverRepository),
        Provider<StorageService>.value(value: storageService),
        Provider<MessagingRepository>.value(value: messagingRepository),
      ],
      child: const SwapTuneApp(),
    ),
  );
}
