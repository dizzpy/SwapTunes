import '../../../../core/services/storage_service.dart';

/// Onboarding repository stub.
///
/// TODO: Add endpoints if onboarding state is tracked on the backend.
class OnboardingRepository {
  final StorageService _storage;

  OnboardingRepository(this._storage);

  /// Whether the user has completed onboarding.
  bool get isOnboardingComplete => _storage.isOnboardingComplete;

  /// Marks onboarding as complete in local storage.
  Future<void> completeOnboarding() async {
    await _storage.setOnboardingComplete(true);
  }
}
