import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../shared/providers/auth_provider.dart';
import '../core/models/user_model.dart';
import '../core/services/storage_service.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/discovery/presentation/screens/discovery_home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/update_password_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/rider_signup_screen.dart';

// Route constant names for easier management
class AppRoutes {
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const roleSelection = '/role-selection';
  static const riderSignUp = '/rider-signup';
  static const forgotPassword = '/forgot-password';
  static const updatePassword = '/update-password';
  static const loading = '/loading';
  static const home = '/home';
  static const admin = '/admin';
  static const shopSetup = '/shop-setup';
  static const ride = '/ride';
  static const scan = '/scan';
  static const history = '/history';
}

const _ownerRoutes = [AppRoutes.admin, AppRoutes.shopSetup];
const _customerAuthRoutes = [AppRoutes.ride, AppRoutes.scan, AppRoutes.history];

bool _isOwnerRoute(String loc) => _ownerRoutes.any(loc.startsWith);
bool _isCustomerAuthRoute(String loc) => _customerAuthRoutes.any(loc.startsWith);

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

      // ── Onboarding Guard ───────────────────────────────────────────────────
      if (!hasSeenOnboarding && location != AppRoutes.onboarding) {
        return AppRoutes.onboarding;
      }
      if (hasSeenOnboarding && location == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      // ── Profile Gap Interceptor ───────────────────────────────────────────
      // If logged in but profile hasn't resolved, stay at /loading
      if (isLoggedIn && userAsync.isLoading) {
        return AppRoutes.loading;
      }

      // If logged in but has no role or missing Rider data, intercept!
      if (isLoggedIn && user != null) {
        // Missing Role: Force Role Selection
        if (user.role == UserRole.guest && location != AppRoutes.roleSelection) {
          return AppRoutes.roleSelection;
        }
        
        // Rider missing ID Number: Force detail completion
        if (user.role == UserRole.customer && 
            (user.idNumber == null || user.idNumber!.isEmpty) && 
            location != AppRoutes.riderSignUp) {
          return AppRoutes.riderSignUp;
        }
      }

      // ── /loading ────────────────────────────────────────────────────────────
      if (location == AppRoutes.loading) {
        if (!isLoggedIn) return AppRoutes.home;
        if (!userAsync.isLoading) {
          if (isOwner) {
            return user?.shopId == null ? AppRoutes.shopSetup : AppRoutes.admin;
          }
          return AppRoutes.home;
        }
        return null;
      }

      // ── /login ──────────────────────────────────────────────────────────────
      if (isLoggedIn && location == AppRoutes.login) {
        if (isOwner) {
          return user?.shopId == null ? AppRoutes.shopSetup : AppRoutes.admin;
        }
        return AppRoutes.home;
      }

      // ── Role & Auth Access Control ─────────────────────────────────────────
      if (isOwner) {
        if (user?.shopId == null && location != AppRoutes.shopSetup) {
          return AppRoutes.shopSetup;
        }
        if (user?.shopId != null && location == AppRoutes.shopSetup) {
          return AppRoutes.admin;
        }
        if (_isCustomerAuthRoute(location)) return AppRoutes.admin;
      }

      if (!isOwner && _isOwnerRoute(location)) return AppRoutes.home;
      if (!isLoggedIn && _isCustomerAuthRoute(location)) return AppRoutes.home;

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.onboarding, builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.roleSelection, builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(path: AppRoutes.riderSignUp, builder: (_, __) => const RiderSignUpScreen()),
      GoRoute(path: AppRoutes.forgotPassword, builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: AppRoutes.updatePassword, builder: (_, __) => const UpdatePasswordScreen()),
      GoRoute(path: AppRoutes.loading, builder: (_, __) => const _LoadingScreen()),
      GoRoute(path: AppRoutes.admin, builder: (_, __) => const _PlaceholderScreen(title: 'Admin Dashboard')),
      GoRoute(path: AppRoutes.shopSetup, builder: (_, __) => const _PlaceholderScreen(title: 'Shop Setup')),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const DiscoveryHomeScreen()),
      GoRoute(path: AppRoutes.ride, builder: (_, __) => const _PlaceholderScreen(title: 'Active Ride')),
      GoRoute(path: AppRoutes.scan, builder: (_, __) => const _PlaceholderScreen(title: 'Scan QR')),
      GoRoute(path: AppRoutes.history, builder: (_, __) => const _PlaceholderScreen(title: 'Ride History')),
    ],
  );
});

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text('Placeholder for $title')),
  );
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
    sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == sb.AuthChangeEvent.passwordRecovery) {
        ref.read(routerProvider).push(AppRoutes.updatePassword);
      }
    });
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
