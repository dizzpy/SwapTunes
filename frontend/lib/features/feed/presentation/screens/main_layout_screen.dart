import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  /// Show or hide the bottom navigation bar (e.g. when entering a full-screen chat).
  static void setNavVisible(bool visible) {
    _key.currentState?._setNavVisible(visible);
  }

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;
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
      _isBottomNavVisible = true;
    });
  }

  void _setNavVisible(bool visible) {
    setState(() => _isBottomNavVisible = visible);
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
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.forward) {
              if (!_isBottomNavVisible) {
                setState(() => _isBottomNavVisible = true);
              }
            } else if (notification.direction == ScrollDirection.reverse) {
              if (_isBottomNavVisible) {
                setState(() => _isBottomNavVisible = false);
              }
            }
            return false;
          },
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
          offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.5),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
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
      ),
    );
  }
}
