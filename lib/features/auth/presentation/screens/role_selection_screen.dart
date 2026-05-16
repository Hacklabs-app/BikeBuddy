import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../app/app.dart';
import 'package:bike_buddy/features/discovery/presentation/widgets/glass_container.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../state/auth_state.dart';

class RoleSelectionScreen extends ConsumerWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else if (isLoggedIn) {
              // Fallback for forced redirects: logout to escape the loop
              ref.read(authNotifierProvider.notifier).signOut();
            } else {
              // True Guest just clicked "Create Account", go back home
              context.go('/home');
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
        actions: [
          if (isLoggedIn)
            TextButton(
              onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
              child: Text(
                'SIGN OUT',
                style: GoogleFonts.inter(
                  color: Colors.white24,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Join the ride',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select your path to continue.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white60,
                ),
              ),
              const SizedBox(height: 48),
              
              // RIDER CARD
              _RoleCard(
                title: 'RIDER',
                description: 'I want to find and rent bikes at local stations.',
                icon: Icons.pedal_bike_rounded,
                color: AppColors.green,
                onTap: () => context.push(AppRoutes.riderSignUp),
              ),
              
              const SizedBox(height: 24),
              
              // OWNER CARD
              _RoleCard(
                title: 'STATION OWNER',
                description: 'I want to manage my bikes, rentals, and revenue.',
                icon: Icons.storefront_rounded,
                color: const Color(0xFFB0B0B0), // Sophisticated Silver
                onTap: () => context.push(AppRoutes.ownerSignUp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: widget.color,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.description,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.color.withValues(alpha: 0.2)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
