import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/providers/auth_provider.dart';
import '../core/models/user_model.dart';
import '../core/services/storage_service.dart';
import '../core/widgets/floating_bottom_nav.dart';
import '../features/auth/presentation/state/auth_state.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/discovery/presentation/screens/discovery_home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/update_password_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/rider_signup_screen.dart';
import '../features/auth/presentation/screens/owner_signup_screen.dart';

// Route constant names for easier management
class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const roleSelection = '/role-selection';
  static const riderSignUp = '/rider-signup';
  static const ownerSignUp = '/owner-signup';
  static const forgotPassword = '/forgot-password';
  static const updatePassword = '/update-password';
  static const loading = '/loading';
  static const home = '/home';
  static const admin = '/admin';
  static const shopSetup = '/shop-setup';
  static const ride = '/ride';
  static const scan = '/scan';
  static const profile = '/profile';
}

const _ownerRoutes = [AppRoutes.admin, AppRoutes.shopSetup];
const _customerAuthRoutes = [AppRoutes.ride, AppRoutes.scan, AppRoutes.profile];
const _registrationRoutes = [AppRoutes.roleSelection, AppRoutes.riderSignUp, AppRoutes.ownerSignUp];

bool _isOwnerRoute(String loc) => _ownerRoutes.contains(loc);
bool _isCustomerAuthRoute(String loc) => _customerAuthRoutes.contains(loc);
bool _isRegistrationRoute(String loc) => _registrationRoutes.contains(loc);

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<bool>(false);
  
  ref.listen(authStateProvider, (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(currentUserProvider, (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(hasSeenOnboardingProvider, (_, __) => refreshListenable.value = !refreshListenable.value);

  return GoRouter(
    initialLocation: ref.read(hasSeenOnboardingProvider) ? AppRoutes.home : AppRoutes.onboarding,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final location = state.matchedLocation;
      
      final authState = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserProvider);
      final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);
      
      final isLoggedIn = authState.valueOrNull != null;
      final user = userAsync.valueOrNull;
      final isOwner = user?.role == UserRole.owner;

      // ── DEBUG LOGGING ──────────────────────────────────────────────────────
      debugPrint('┌── [ROUTER] ───────────────────────────────────────');
      debugPrint('│ Location: $location');
      debugPrint('│ Logged In: $isLoggedIn');
      debugPrint('│ Profile Loaded: ${!userAsync.isLoading}');
      debugPrint('│ User Role: ${user?.role.name ?? "null"}');
      debugPrint('│ Shop ID: ${user?.shopId ?? "null"}');
      debugPrint('└───────────────────────────────────────────────────');

      // ── Onboarding Guard ───────────────────────────────────────────────────
      if (!hasSeenOnboarding && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (hasSeenOnboarding && location == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      // ── Guest Guard ───────────────────────────────────────────────────────
      if (!isLoggedIn) {
        // Guests ARE allowed on Registration routes and Login routes.
        // They are BLOCKED from Activity/Scan/Profile/Admin.
        if (_isCustomerAuthRoute(location) || _isOwnerRoute(location)) {
          debugPrint('[ROUTER] Guest blocked from private route. Redirecting to Home');
          return AppRoutes.home;
        }
        return null;
      }

      // ── Profile Gap Interceptor (Only for Authenticated Users) ─────────────
      if (userAsync.isLoading) {
        return null;
      }

      // 1. User has no role (First-time social or trigger lag) -> Force Role Selection
      if (user?.role == UserRole.pending || user == null) {
        if (!_isRegistrationRoute(location)) {
          debugPrint('[ROUTER] Redirecting: Authenticated user needs to pick a role');
          return AppRoutes.roleSelection;
        }
        return null;
      }

      // 2. Owner missing a Station -> Force Owner Signup/Setup
      if (isOwner && user.shopId == null) {
        if (location != AppRoutes.ownerSignUp && location != AppRoutes.shopSetup) {
          debugPrint('[ROUTER] Redirecting: Owner needs to setup station');
          return AppRoutes.ownerSignUp;
        }
        return null;
      }

      // 3. Rider missing ID Number -> Force Rider Signup
      if (user.role == UserRole.customer &&
          (user.idNumber == null || user.idNumber!.isEmpty)) {
        if (location != AppRoutes.riderSignUp) {
          debugPrint('[ROUTER] Redirecting: Rider needs to provide ID');
          return AppRoutes.riderSignUp;
        }
        return null;
      }

      // 4. OWNER ACCESS CONTROL
      if (isOwner) {
        if (location == AppRoutes.home || location == '/') {
          return AppRoutes.admin;
        }
        if (_isCustomerAuthRoute(location)) return AppRoutes.admin;
      } else {
        if (_isOwnerRoute(location)) return AppRoutes.home;
      }

      // 5. LOGIN ESCAPE
      if (location == AppRoutes.login) {
        return isOwner ? AppRoutes.admin : AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.roleSelection, builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(path: AppRoutes.riderSignUp, builder: (_, __) => const RiderSignUpScreen()),
      GoRoute(path: AppRoutes.ownerSignUp, builder: (_, __) => const OwnerSignUpScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.updatePassword, builder: (_, __) => const UpdatePasswordScreen()),
      GoRoute(path: AppRoutes.loading, builder: (_, __) => const _LoadingScreen()),
      GoRoute(
        path: AppRoutes.admin, 
        builder: (_, __) => const _PlaceholderScreen(
          title: 'Business Dashboard',
          isOwnerView: true,
        ),
      ),
      GoRoute(path: AppRoutes.shopSetup, builder: (_, __) => const _PlaceholderScreen(title: 'Shop Setup')),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const DiscoveryHomeScreen()),
      GoRoute(
        path: AppRoutes.ride, 
        builder: (_, __) => const _PlaceholderScreen(
          title: 'Activity', 
          tab: FloatingNavTab.activity,
        ),
      ),
      GoRoute(
        path: AppRoutes.scan, 
        builder: (_, __) => const _PlaceholderScreen(
          title: 'Scan QR', 
          tab: FloatingNavTab.scan,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile, 
        builder: (_, __) => const _PlaceholderScreen(
          title: 'Profile Settings',
        ),
      ),
    ],
  );
});

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _PlaceholderScreen extends ConsumerWidget {
  const _PlaceholderScreen({required this.title, this.tab, this.isOwnerView = false});
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
                  isOwnerView ? 'Manage your station assets here.' : 'Coming soon to your city.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white38,
                  ),
                ),
                if (tab == null) ...[ // Only show logout on the Profile page or Admin dash
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 200,
                    child: OutlinedButton(
                      onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 0.5),
                        foregroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

class BikeBuddyApp extends ConsumerStatefulWidget {
  const BikeBuddyApp({super.key});
  @override
  ConsumerState<BikeBuddyApp> createState() => _BikeBuddyAppState();
}

class _BikeBuddyAppState extends ConsumerState<BikeBuddyApp> {
  @override
  void initState() {
    super.initState();
    try {
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        debugPrint('[AUTH] Auth State Changed: ${data.event.name}');
        if (data.event == AuthChangeEvent.passwordRecovery) {
          debugPrint('[AUTH] Password recovery event detected! Redirecting...');
          ref.read(routerProvider).push(AppRoutes.updatePassword);
        }
      });
    } catch (e) {
      debugPrint('[AUTH] Error initializing listener: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00B248),
        brightness: Brightness.dark,
        surface: const Color(0xFF0D0D0D),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    );

    return MaterialApp.router(
      title: 'Bike Buddy',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
