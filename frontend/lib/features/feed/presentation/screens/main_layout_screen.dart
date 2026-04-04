import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:swaptune/features/discover/presentation/screens/discover_screen.dart';
import 'package:swaptune/features/feed/presentation/screens/feed_screen.dart';
import 'package:swaptune/features/messaging/presentation/screens/chats_list_screen.dart';
import 'package:swaptune/features/profile/presentation/screens/own_profile_screen.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sliding_nav_bar.dart';
import '../../../../features/auth/presentation/viewmodels/auth_viewmodel.dart';
import '../../../../features/collab/presentation/screens/collab_screen.dart';

/// Enum to control bottom nav bar visibility behavior per screen
enum NavBarVisibility {
  /// Nav bar is visible and responds to scroll (default behavior)
  visible,

  /// Nav bar is hidden and ignores scroll events
  hidden,

  /// Nav bar is visible but ignores scroll events (always shown)
  locked,
}

class MainLayoutScreen extends StatefulWidget {
  static final GlobalKey<_MainLayoutScreenState> _key = GlobalKey();

  MainLayoutScreen() : super(key: _key);

  /// Pop every pushed screen in the current tab and switch to the Profile tab.
  static void switchToProfile() {
    final state = _key.currentState;
    if (state == null) return;
    final isCreator = state._isCreator;
    final profileIndex = isCreator ? 4 : 3;
    state._tabKeys[profileIndex].currentState?.popUntil((route) => route.isFirst);
    state._switchTab(profileIndex);
  }

  /// Set the nav bar visibility mode.
  /// - [NavBarVisibility.visible]: Normal behavior with scroll hide/show
  /// - [NavBarVisibility.hidden]: Force hide, ignores scroll
  /// - [NavBarVisibility.locked]: Force show, ignores scroll
  static void setNavVisibility(NavBarVisibility visibility) {
    _key.currentState?._setNavVisibility(visibility);
  }

  /// Convenience method to hide nav bar (shorthand for setNavVisibility(hidden))
  static void hideNavBar() => setNavVisibility(NavBarVisibility.hidden);

  /// Convenience method to show nav bar (shorthand for setNavVisibility(visible))
  static void showNavBar() => setNavVisibility(NavBarVisibility.visible);

  /// Convenience method to lock nav bar visible (shorthand for setNavVisibility(locked))
  static void lockNavBar() => setNavVisibility(NavBarVisibility.locked);

  @Deprecated('Use setNavVisibility, hideNavBar, or showNavBar instead')
  static void setNavVisible(bool visible) {
    _key.currentState?._setNavVisibility(
      visible ? NavBarVisibility.visible : NavBarVisibility.hidden,
    );
  }

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  NavBarVisibility _navVisibility = NavBarVisibility.visible;
  bool _isNavBarShown = true;
  bool _isCreator = false;

  // Always allocate 5 keys — collab tab uses index 2, others shift right
  final List<GlobalKey<NavigatorState>> _tabKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  // Tab roots: Home, Discover, Collab, Inbox, Profile
  final List<Widget> _tabRoots = [
    const FeedScreen(),
    const DiscoverScreen(),
    const CollabScreen(),
    ChatsListScreen(),
    const OwnProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncCreatorState();
      context.read<AuthViewmodel>().addListener(_syncCreatorState);
    });
  }

  @override
  void dispose() {
    try {
      context.read<AuthViewmodel>().removeListener(_syncCreatorState);
    } catch (_) {}
    super.dispose();
  }

  void _syncCreatorState() {
    if (!mounted) return;
    final isCreator =
        context.read<AuthViewmodel>().currentUser?.userType == 'creator';
    if (isCreator != _isCreator) {
      setState(() {
        _isCreator = isCreator;
        // If creator tab was selected and we switched to listener, reset to home
        if (!isCreator && _currentIndex == 2) _currentIndex = 0;
      });
    }
  }

  void _switchTab(int index) {
    // index 3 = Inbox (listener) or Inbox (creator, index 3 shifts to include collab)
    if (!_isCreator && index == 2) {
      // listener: index 2 = Inbox (no collab tab) → map to actual tab 3
    }
    if (_isCreator && index == 3) ChatsListScreen.refresh();
    if (!_isCreator && index == 2) ChatsListScreen.refresh();
    setState(() {
      _currentIndex = index;
      // Reset to default visibility when switching tabs
      _navVisibility = NavBarVisibility.visible;
      _isNavBarShown = true;
    });
  }

  void _setNavVisibility(NavBarVisibility visibility) {
    // Defer setState so callers (e.g. initState of a child route) never
    // trigger a rebuild while the current frame is still being built/laid out.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _navVisibility = visibility;
        switch (visibility) {
          case NavBarVisibility.visible:
            _isNavBarShown = true;
          case NavBarVisibility.hidden:
            _isNavBarShown = false;
          case NavBarVisibility.locked:
            _isNavBarShown = true;
        }
      });
    });
  }

  /// Handle scroll events - only responds to VERTICAL scroll and only when
  /// visibility mode is [NavBarVisibility.visible]
  bool _handleScrollNotification(UserScrollNotification notification) {
    // Only respond to scroll when in normal visible mode
    if (_navVisibility != NavBarVisibility.visible) return false;

    // FIX: Only respond to vertical scroll, ignore horizontal scroll
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return false;

    if (notification.direction == ScrollDirection.forward) {
      if (!_isNavBarShown) {
        setState(() => _isNavBarShown = true);
      }
    } else if (notification.direction == ScrollDirection.reverse) {
      if (_isNavBarShown) {
        setState(() => _isNavBarShown = false);
      }
    }
    return false;
  }

  /// Returns the actual Navigator tab index accounting for creator/listener mode.
  /// Listeners skip the Collab tab (index 2), so their Inbox=2, Profile=3.
  int get _navigatorIndex {
    if (_isCreator) return _currentIndex;
    // Listener: logical 0=Home,1=Discover,2=Inbox,3=Profile
    //           actual  0=Home,1=Discover,3=Inbox,4=Profile (skip 2=Collab)
    if (_currentIndex >= 2) return _currentIndex + 1;
    return _currentIndex;
  }

  List<SlidingNavItem> get _navItems {
    final homeItem = SlidingNavItem(
      icon: HugeIcon(
        icon: AppAssets.icon.home,
        color: AppColors.textSecondary,
        size: 26,
      ),
      title: 'Home',
    );
    final discoverItem = SlidingNavItem(
      icon: HugeIcon(
        icon: AppAssets.icon.discover,
        color: AppColors.textSecondary,
        size: 26,
      ),
      title: 'Discover',
    );
    final collabItem = SlidingNavItem(
      icon: HugeIcon(
        icon: AppAssets.icon.collab,
        color: AppColors.textSecondary,
        size: 26,
      ),
      title: 'Collab',
    );
    final inboxItem = SlidingNavItem(
      icon: HugeIcon(
        icon: AppAssets.icon.message,
        color: AppColors.textSecondary,
        size: 26,
      ),
      title: 'Inbox',
    );
    final profileItem = SlidingNavItem(
      icon: HugeIcon(
        icon: AppAssets.icon.profile,
        color: AppColors.textSecondary,
        size: 26,
      ),
      title: 'Profile',
    );

    if (_isCreator) {
      return [homeItem, discoverItem, collabItem, inboxItem, profileItem];
    }
    return [homeItem, discoverItem, inboxItem, profileItem];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final tabNav = _tabKeys[_navigatorIndex].currentState;
        if (tabNav != null && tabNav.canPop()) {
          tabNav.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.background,
        body: NotificationListener<UserScrollNotification>(
          onNotification: _handleScrollNotification,
          child: IndexedStack(
            index: _navigatorIndex,
            children: List.generate(5, (i) {
              return Navigator(
                key: _tabKeys[i],
                onGenerateRoute: (_) =>
                    MaterialPageRoute(builder: (_) => _tabRoots[i]),
              );
            }),
          ),
        ),
        bottomNavigationBar: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: _isNavBarShown ? Offset.zero : const Offset(0, 1.5),
          child: SlidingNavBar(
            backgroundColor: AppColors.cardFront,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.textSecondary,
            selectedIndex: _currentIndex,
            onTap: _switchTab,
            items: _navItems,
          ),
        ),
      ),
    );
  }
}
