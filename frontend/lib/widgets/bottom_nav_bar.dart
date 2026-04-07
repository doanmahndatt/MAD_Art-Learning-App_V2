import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  const BottomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final isDark = app.isDarkMode;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: isDark ? AppColors.darkTextLight : AppColors.textLight,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: app.t('nav_home')),
        BottomNavigationBarItem(icon: const Icon(Icons.school_outlined), activeIcon: const Icon(Icons.school), label: app.t('nav_tutorials')),
        BottomNavigationBarItem(icon: const Icon(Icons.brush_outlined), activeIcon: const Icon(Icons.brush), label: app.t('nav_draw')),
        BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined), activeIcon: const Icon(Icons.explore), label: app.t('nav_explore')),
        BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: app.t('nav_profile')),
      ],
    );
  }
}