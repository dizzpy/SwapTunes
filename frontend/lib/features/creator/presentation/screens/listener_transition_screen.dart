import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/feed/presentation/screens/main_layout_screen.dart';
import '../../../../features/profile/data/repositories/profile_repository.dart';
import '../../../../shared/widgets/wavy_prograss_indicator.dart';
import '../viewmodels/creator_viewmodel.dart';

/// Loading screen shown when switching from creator to listener mode.
class ListenerTransitionScreen extends StatefulWidget {
  const ListenerTransitionScreen({super.key});

  @override
  State<ListenerTransitionScreen> createState() => _ListenerTransitionScreenState();
}

class _ListenerTransitionScreenState extends State<ListenerTransitionScreen>
    with SingleTickerProviderStateMixin {
  static const _steps = [
    (text: 'Switching to listener mode...', duration: 1500),
    (text: 'Closing open collaborations...', duration: 1200),
    (text: 'Saving your creator profile...', duration: 1000),
    (text: 'Almost there...', duration: 1000),
    (text: 'All set!', duration: 800),
  ];

  int _stepIndex = 0;
  bool _visible = true;
  bool _navigated = false;
  bool _sequenceDone = false;
  bool? _apiSuccess;
  String? _apiError;
  final List<Timer> _timers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MainLayoutScreen.hideNavBar();
      _callApi();
    });
    _startSequence();
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MainLayoutScreen.showNavBar();
    });
    super.dispose();
  }

  Future<void> _callApi() async {
    final creatorVm = context.read<CreatorViewmodel>();
    final authVm = context.read<AuthViewmodel>();
    final profileRepo = context.read<ProfileRepository>();

    final success = await creatorVm.deactivateCreator();
    if (!mounted) return;

    if (success) {
      final username = authVm.currentUser?.username ?? '';
      if (username.isNotEmpty) {
        profileRepo.invalidateCache(username);
      }
      await authVm.refreshCurrentUser();
      _apiSuccess = true;
    } else {
      _apiSuccess = false;
      _apiError = creatorVm.errorMessage ?? 'Switch failed. Please try again.';
    }

    _maybeNavigate();
  }

  void _startSequence() {
    _showStep(0);
  }

  void _showStep(int index) {
    if (!mounted) return;
    setState(() {
      _stepIndex = index;
      _visible = true;
    });
    HapticFeedback.lightImpact();

    final duration = _steps[index].duration;
    final isLast = index == _steps.length - 1;

    // Fade out before switching (200ms before end)
    _timers.add(
      Timer(Duration(milliseconds: duration - 200), () {
        if (!mounted) return;
        if (!isLast) {
          setState(() => _visible = false);
          _timers.add(
            Timer(const Duration(milliseconds: 200), () {
              _showStep(index + 1);
            }),
          );
        } else {
          // Last step: mark sequence done, then try to navigate
          _timers.add(
            Timer(const Duration(milliseconds: 200), () {
              _sequenceDone = true;
              _maybeNavigate();
            }),
          );
        }
      }),
    );
  }

  void _maybeNavigate() {
    if (_navigated || !mounted) return;
    if (!_sequenceDone) return; // always wait for full animation
    if (_apiSuccess == null) return; // still waiting for API

    _navigated = true;

    if (_apiSuccess == true) {
      AppSnackbar.success('Switched to listener mode');
      // Pop back to profile screen which will auto-refresh
      Navigator.of(context).pop();
    } else {
      AppSnackbar.error(_apiError ?? 'Switch failed. Please try again.');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const WavyCircularIndicator(
                size: 60,
                strokeWidth: 5,
                waveCount: 8,
                amplitudeFactor: 0.6,
                arcFraction: 1.0,
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: AnimatedOpacity(
                  opacity: _visible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _steps[_stepIndex].text,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
