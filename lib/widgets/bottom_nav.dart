import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NavigationProvider>(
      builder: (context, navProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.home_rounded,
                    label: 'Dashboard',
                    index: 0,
                    currentIndex: navProvider.currentIndex,
                    onTap: () => navProvider.setCurrentIndex(0),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.edit_note_rounded,
                    label: 'Input',
                    index: 2,
                    currentIndex: navProvider.currentIndex,
                    onTap: () => navProvider.setCurrentIndex(2),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.bar_chart_rounded,
                    label: 'Riwayat',
                    index: 1,
                    currentIndex: navProvider.currentIndex,
                    onTap: () => navProvider.setCurrentIndex(1),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_rounded,
                    label: 'Profil',
                    index: 3,
                    currentIndex: navProvider.currentIndex,
                    onTap: () => navProvider.setCurrentIndex(3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
    required VoidCallback onTap,
  }) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryBlue.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primaryBlue : AppColors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primaryBlue : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
