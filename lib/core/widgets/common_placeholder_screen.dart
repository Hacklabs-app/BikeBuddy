import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'floating_bottom_nav.dart';
import '../../features/auth/presentation/state/auth_state.dart';
import '../../app/app.dart';

class CommonPlaceholderScreen extends ConsumerWidget {
  const CommonPlaceholderScreen({
    super.key,
    required this.title,
    this.tab,
    this.isOwnerView = false,
  });

  final String title;
  final FloatingNavTab? tab;
  final bool isOwnerView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOwnerView
                      ? Icons.dashboard_customize_rounded
                      : (tab == FloatingNavTab.activity
                          ? Icons.bar_chart_rounded
                          : tab == FloatingNavTab.scan
                              ? Icons.qr_code_scanner_rounded
                              : Icons.person_outline_rounded),
                  color: Colors.white10,
                  size: 80,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isOwnerView
                      ? 'Manage your station assets here.'
                      : 'Coming soon to your city.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white38,
                  ),
                ),
                if (tab == null) ...[
                  // Only show logout on Profile or Admin dash
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      onPressed: () async {
                        // Simply sign out. GoRouter's redirect logic automatically triggers
                        // and bounces unauthenticated users off this screen smoothly.
                        await ref.read(authNotifierProvider.notifier).signOut();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.redAccent, width: 0.5),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (tab != null)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: FloatingBottomNav(activeTab: tab!),
            ),
          if (tab == null && !isOwnerView) // Profile page back button
            Positioned(
              top: 60,
              left: 24,
              child: IconButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
