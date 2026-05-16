import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../state/onboarding_state.dart';
import '../../domain/entities/onboarding_page.dart';

/// The entry point for the application's onboarding experience.
/// Implements a high-fidelity "Liquid Clock" transition between slides.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (mounted) {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleFinish(String destination) async {
    try {
      await ref.read(onboardingProvider.notifier).completeOnboarding();
      if (mounted) context.go(destination);
    } catch (e) {
      debugPrint('ERROR in OnboardingScreen._handleFinish: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final size = MediaQuery.of(context).size;

    return onboardingState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (pages) {
        final bool isLastPage = _currentPage >= pages.length - 1.5;

        return Scaffold(
          body: Stack(
            children: [
              // Content Layer: Uses Matrix4 for curved "Clock" transitions
              PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final double relativePosition = index - _currentPage;
                  
                  // Motion Physics: Rotation + Opacity + Scale
                  final double angle = relativePosition * 0.25 * math.pi; 
                  final double opacity = (1.0 - relativePosition.abs()).clamp(0.0, 1.0);
                  final double scale = 0.9 + (opacity * 0.1);

                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001) 
                      ..setTranslationRaw(relativePosition * size.width, 0.0, 0.0)
                      ..rotateZ(angle)
                      ..scaleByDouble(scale, scale, 1.0, 1.0),
                    alignment: Alignment.center,
                    child: Opacity(
                      opacity: opacity,
                      child: _OnboardingBody(page: pages[index]),
                    ),
                  );
                },
              ),

              // Navigation Overlay: Skip Button (Top Right)
              if (!isLastPage)
                Positioned(
                  top: 60,
                  right: 20,
                  child: Opacity(
                    opacity: (1.0 - _currentPage).clamp(0.0, 1.0),
                    child: IgnorePointer(
                      ignoring: isLastPage,
                      child: TextButton(
                        onPressed: () => _handleFinish('/home'),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Navigation Overlay: Bottom Bar (Indicators + Actions)
              Positioned(
                bottom: math.max(40, size.height * 0.08),
                left: 32,
                right: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Reactive Progress Indicators
                    Row(
                      children: List.generate(pages.length, (index) {
                        final double active = (1.0 - (index - _currentPage).abs()).clamp(0.0, 1.0);
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 8),
                          height: 2,
                          width: 16 + (active * 12),
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: active.clamp(0.1, 1.0)),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        );
                      }),
                    ),

                    // Unified Action Control
                    _ActionControl(
                      isLast: isLastPage,
                      onNext: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                      onSkipToRide: () => _handleFinish('/home'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A specialized widget for the central content of an onboarding page.
/// Handles responsive scaling and typography.
class _OnboardingBody extends StatelessWidget {
  const _OnboardingBody({required this.page});
  final OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: isSmallScreen ? 80 : 120,
            width: isSmallScreen ? 80 : 120,
            color: AppColors.green,
          ),
          SizedBox(height: isSmallScreen ? 48 : 64),
          
          Text(
            page.subtitle,
            style: GoogleFonts.inter(
              color: AppColors.green.withValues(alpha: 0.5),
              fontSize: isSmallScreen ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
            ),
          ),
          const SizedBox(height: 16),
          
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isSmallScreen ? 28 : 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white54,
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

/// Manages the primary navigation action in the onboarding flow.
class _ActionControl extends StatefulWidget {
  const _ActionControl({
    required this.isLast,
    required this.onNext,
    required this.onSkipToRide,
  });

  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkipToRide;

  @override
  State<_ActionControl> createState() => _ActionControlState();
}

class _ActionControlState extends State<_ActionControl> with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _hoverAnimation = Tween<double>(begin: 0, end: 6).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: widget.isLast ? _buildLastAction() : _buildNextAction(),
    );
  }

  Widget _buildNextAction() {
    return Material(
      key: const ValueKey('next_button'),
      color: AppColors.green.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: widget.onNext,
        borderRadius: BorderRadius.circular(25),
        child: const SizedBox(
          height: 50,
          width: 50,
          child: Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.green,
            size: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLastAction() {
    return TextButton(
      key: const ValueKey('finish_button'),
      onPressed: widget.onSkipToRide,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ride Along now',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_hoverAnimation.value, 0),
                child: child,
              );
            },
            child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}
