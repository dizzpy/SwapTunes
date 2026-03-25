import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:swaptune/features/discover/presentation/screens/discover_screen.dart';
import 'package:swaptune/features/feed/presentation/screens/feed_screen.dart';
import 'package:swaptune/features/messaging/presentation/screens/chats_list_screen.dart';
import 'package:swaptune/features/profile/presentation/screens/own_profile_screen.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sliding_nav_bar.dart';

class MainLayoutScreen extends StatefulWidget {
  static final GlobalKey<_MainLayoutScreenState> _key = GlobalKey();

  MainLayoutScreen() : super(key: _key);

  /// Pop every pushed screen in the current tab and switch to the Profile tab.
  static void switchToProfile() {
    final state = _key.currentState;
    if (state == null) return;
    state._tabKeys[3].currentState?.popUntil((route) => route.isFirst);
    state._switchTab(3);
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

  final List<GlobalKey<NavigatorState>> _tabKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  final List<Widget> _tabRoots = [
    const FeedScreen(),
    const DiscoverScreen(),
    const ChatsListScreen(),
    const OwnProfileScreen(),
  ];

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _isBottomNavVisible = true;
    });
  }

  void _setNavVisible(bool visible) {
    setState(() => _isBottomNavVisible = visible);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final tabNav = _tabKeys[_currentIndex].currentState;
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
            index: _currentIndex,
            children: List.generate(4, (i) {
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
              items: [
                SlidingNavItem(
                  icon: HugeIcon(
                    icon: AppAssets.icon.home,
                    color: AppColors.textSecondary,
                    size: 26,
                  ),
                  title: 'Home',
                ),
                SlidingNavItem(
                  icon: HugeIcon(
                    icon: AppAssets.icon.discover,
                    color: AppColors.textSecondary,
                    size: 26,
                  ),
                  title: 'Discover',
                ),
                SlidingNavItem(
                  icon: HugeIcon(
                    icon: AppAssets.icon.message,
                    color: AppColors.textSecondary,
                    size: 26,
                  ),
                  title: 'Inbox',
                ),
                SlidingNavItem(
                  icon: HugeIcon(
                    icon: AppAssets.icon.profile,
                    color: AppColors.textSecondary,
                    size: 26,
                  ),
                  title: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
