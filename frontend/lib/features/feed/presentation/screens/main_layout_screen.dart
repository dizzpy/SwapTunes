import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:swaptune/features/feed/presentation/screens/feed_screen.dart';
import 'package:swaptune/features/profile/presentation/screens/own_profile_screen.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/theme/app_colors.dart';

class MainLayoutScreen extends StatefulWidget {
  static final GlobalKey<_MainLayoutScreenState> _key = GlobalKey();

  MainLayoutScreen() : super(key: _key);

  /// Pop every pushed screen and switch to the Profile tab (index 3).
  /// This is the only way to "navigate to own profile" — never push a
  /// standalone OwnProfileScreen.
  static void switchToProfile() {
    final nav = NavigationService.navigatorKey.currentState;
    nav?.popUntil((route) => route.isFirst);
    _key.currentState?._switchTab(3);
  }

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;
  bool _isBottomNavVisible = true;

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _isBottomNavVisible = true;
    });
  }

  final List<Widget> _screens = [
    const FeedScreen(),
    const Center(
      child: Text('Discover', style: TextStyle(color: AppColors.textWhite)),
    ),
    const Center(
      child: Text('Inbox', style: TextStyle(color: AppColors.textWhite)),
    ),
    const OwnProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        // IndexedStack keeps all screens alive — prevents reload on tab switch
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isBottomNavVisible ? Offset.zero : const Offset(0, 1.5),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.cardFront,
            border: Border(top: BorderSide(color: AppColors.outline, width: 1)),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                backgroundColor: AppColors.cardFront,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textSecondary,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                elevation: 0,
                items: [
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: AppAssets.icon.home,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    activeIcon: HugeIcon(
                      icon: AppAssets.icon.home,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: AppAssets.icon.discover,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    activeIcon: HugeIcon(
                      icon: AppAssets.icon.discover,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    label: 'Discover',
                  ),
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: AppAssets.icon.message,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    activeIcon: HugeIcon(
                      icon: AppAssets.icon.message,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    label: 'Inbox',
                  ),
                  BottomNavigationBarItem(
                    icon: HugeIcon(
                      icon: AppAssets.icon.profile,
                      color: AppColors.textSecondary,
                      size: 26,
                    ),
                    activeIcon: HugeIcon(
                      icon: AppAssets.icon.profile,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
