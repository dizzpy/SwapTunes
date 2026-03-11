import 'package:flutter/foundation.dart';

import '../../data/repositories/onboarding_repository.dart';

/// Onboarding state management.
///
/// Tracks onboarding completion and page navigation.
class OnboardingViewmodel extends ChangeNotifier {
  final OnboardingRepository _repository;

  int _currentPage = 0;

  OnboardingViewmodel(this._repository);

  int get currentPage => _currentPage;
  bool get isOnboardingComplete => _repository.isOnboardingComplete;

  /// Updates the current page index.
  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  /// Marks onboarding as completed.
  Future<void> completeOnboarding() async {
    await _repository.completeOnboarding();
    notifyListeners();
  }
}
