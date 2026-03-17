import 'package:flutter/material.dart';
import 'package:swaptune/features/feed/presentation/screens/feed_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_assets.dart';
import 'package:hugeicons/hugeicons.dart';

class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FeedScreen(),
    const Center(
      child: Text('Discover', style: TextStyle(color: AppColors.textWhite)),
    ),
    const Center(
      child: Text('Inbox', style: TextStyle(color: AppColors.textWhite)),
    ),
    const Center(
      child: Text('Profile', style: TextStyle(color: AppColors.textWhite)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
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
    );
  }
}
