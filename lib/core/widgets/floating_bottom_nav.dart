import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../../shared/providers/auth_provider.dart';

enum FloatingNavTab { stations, scan, activity }

class FloatingBottomNav extends ConsumerWidget {
  const FloatingBottomNav({super.key, required this.activeTab});

  final FloatingNavTab activeTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;

    void handleTap(String route) {
      if (isLoggedIn) {
        context.go(route);
      } else {
        context.push('/login');
      }
    }

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(
            icon: Icons.explore_rounded,
            label: 'Stations',
            isActive: activeTab == FloatingNavTab.stations,
            onTap: () => context.go('/home'),
          ),
          const SizedBox(width: 8),
          _ScanHeroButton(
            onTap: () => handleTap('/scan'),
            isActive: activeTab == FloatingNavTab.scan,
          ),
          const SizedBox(width: 8),
          _NavIcon(
            icon: Icons.bar_chart_rounded,
            label: 'Activity',
            isActive: activeTab == FloatingNavTab.activity,
            onTap: () => handleTap('/ride'),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? AppColors.green : Colors.white.withValues(alpha: 0.2);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanHeroButton extends StatelessWidget {
  const _ScanHeroButton({required this.onTap, required this.isActive});
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? AppColors.green
                : AppColors.green.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: isActive ? 0.2 : 0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: AppColors.green,
          size: 28,
        ),
      ),
    );
  }
}
