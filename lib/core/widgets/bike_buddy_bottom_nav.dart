import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';

enum BikeBuddyNavItem {
  discover,
  activeRide,
  profile,
  ownerDashboard,
  ownerSettings,
}

class BikeBuddyBottomNav extends StatelessWidget {
  const BikeBuddyBottomNav.customer({
    required this.currentItem,
    required this.isLoggedIn,
    super.key,
  }) : isOwner = false;

  const BikeBuddyBottomNav.owner({
    required this.currentItem,
    super.key,
  })  : isOwner = true,
        isLoggedIn = true;

  final BikeBuddyNavItem currentItem;
  final bool isOwner;
  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = isOwner ? _ownerItems : _customerItems(isLoggedIn);
    final selectedIndex = items.indexWhere((item) => item.item == currentItem);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
            height: 68,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            indicatorColor: AppColors.green.withValues(alpha: 0.16),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              final item = items[index];
              if (item.item == currentItem) return;
              context.go(item.route);
            },
            destinations: [
              for (final item in items)
                NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: item.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.item,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final BikeBuddyNavItem item;
  final String route;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _ownerItems = [
  _NavDestination(
    item: BikeBuddyNavItem.ownerDashboard,
    route: '/admin',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Home',
  ),
  _NavDestination(
    item: BikeBuddyNavItem.ownerSettings,
    route: '/shop-setup',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    label: 'Shop',
  ),
];

List<_NavDestination> _customerItems(bool isLoggedIn) {
  return [
    const _NavDestination(
      item: BikeBuddyNavItem.discover,
      route: '/home',
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Discover',
    ),
    const _NavDestination(
      item: BikeBuddyNavItem.activeRide,
      route: '/ride',
      icon: Icons.timer_outlined,
      selectedIcon: Icons.timer,
      label: AppStrings.activeRide,
    ),
    _NavDestination(
      item: BikeBuddyNavItem.profile,
      route: isLoggedIn ? '/scan' : '/login',
      icon: isLoggedIn ? Icons.qr_code_2_outlined : Icons.login_outlined,
      selectedIcon: isLoggedIn ? Icons.qr_code_2 : Icons.login,
      label: isLoggedIn ? AppStrings.profile : AppStrings.signIn,
    ),
  ];
}
