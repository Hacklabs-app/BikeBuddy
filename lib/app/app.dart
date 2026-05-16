import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../shared/providers/auth_provider.dart';
import '../core/models/user_model.dart';
import '../core/services/storage_service.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/discovery/presentation/screens/discovery_home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';

// Extend these two lists as new routes are added — guards update automatically.
const _ownerRoutes = ['/admin', '/shop-setup'];
const _customerAuthRoutes = ['/ride', '/scan', '/history'];

bool _isOwnerRoute(String loc) => _ownerRoutes.any(loc.startsWith);
bool _isCustomerAuthRoute(String loc) => _customerAuthRoutes.any(loc.startsWith);

final routerProvider = Provider<GoRouter>((ref) {
  // We use a ValueNotifier as a refresh listenable to trigger redirects
  // without recreating the entire GoRouter instance.
  final refreshListenable = ValueNotifier<bool>(false);
  
  // Listen to the providers and notify the router when they change
  ref.listen(authStateProvider, (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(currentUserProvider, (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(hasSeenOnboardingProvider, (_, __) => refreshListenable.value = !refreshListenable.value);

  return GoRouter(
    initialLocation: ref.read(hasSeenOnboardingProvider) ? '/home' : '/onboarding',
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final location = state.matchedLocation;
      
      // Read values inside redirect to get latest state
      final authState = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserProvider);
      final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);
      
      final isLoggedIn = authState.valueOrNull != null;
      final user = userAsync.valueOrNull;
      final isOwner = user?.role == UserRole.owner;

      debugPrint('DEBUG: Router Redirecting. Location: $location, isLoggedIn: $isLoggedIn, hasSeenOnboarding: $hasSeenOnboarding');

      // ── Onboarding ──────────────────────────────────────────────────────────
      if (!hasSeenOnboarding && location != '/onboarding') {
        debugPrint('DEBUG: Forcing /onboarding');
        return '/onboarding';
      }

      // If they just finished onboarding, let the intended navigation proceed.
      // But if they are manually trying to go back to /onboarding, send them home.
      if (hasSeenOnboarding && location == '/onboarding') {
        debugPrint('DEBUG: Onboarding seen, redirecting to /home');
        return '/home';
      }

      // ── /loading ────────────────────────────────────────────────────────────
      // Used as a brief holding screen while the profile is being fetched.
      // Exit immediately if not logged in, or once the profile resolves.
      if (location == '/loading') {
        if (!isLoggedIn) return '/home';
        if (!userAsync.isLoading) {
          if (isOwner) {
            return user?.shopId == null ? '/shop-setup' : '/admin';
          }
          return '/home';
        }
        return null; // still fetching — stay on the spinner
      }

      // ── /login ──────────────────────────────────────────────────────────────
      // Authenticated users have no business on the login screen.
      // Hold at /loading while the profile is still resolving.
      if (isLoggedIn && location == '/login') {
        if (userAsync.isLoading) return '/loading';
        if (isOwner) {
          return user?.shopId == null ? '/shop-setup' : '/admin';
        }
        return '/home';
      }

      // ── Owner Checks ────────────────────────────────────────────────────────
      if (isOwner) {
        // If owner hasn't set up shop, force them to setup screen
        if (user?.shopId == null && location != '/shop-setup') {
          return '/shop-setup';
        }
        // If owner has shop, don't let them stay on setup screen
        if (user?.shopId != null && location == '/shop-setup') {
          return '/admin';
        }
        // An owner has no customer bookings or ride screens; send them home.
        if (_isCustomerAuthRoute(location)) return '/admin';
      }

      // ── Non-owner → owner routes ────────────────────────────────────────────
      // Always redirect to /home — covers both customers and the post-logout
      // case where an owner lands on /admin after signOut() clears the session.
      if (!isOwner && _isOwnerRoute(location)) return '/home';

      // ── Unauthenticated → customer-auth routes ──────────────────────────────
      // No hard login wall — drop them at /home in browse-only mode instead.
      if (!isLoggedIn && _isCustomerAuthRoute(location)) return '/home';

      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/loading', builder: (_, __) => const _LoadingScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const _PlaceholderScreen(title: 'Admin Dashboard')),
      GoRoute(path: '/shop-setup', builder: (_, __) => const _PlaceholderScreen(title: 'Shop Setup')),
      GoRoute(path: '/home', builder: (_, __) => const DiscoveryHomeScreen()),
      GoRoute(
        path: '/shop-detail',
        builder: (_, state) {
          return const _PlaceholderScreen(title: 'Shop Detail');
        },
      ),
      GoRoute(path: '/ride', builder: (_, __) => const _PlaceholderScreen(title: 'Active Ride')),
      GoRoute(path: '/scan', builder: (_, __) => const _PlaceholderScreen(title: 'Scan QR')),
      GoRoute(path: '/history', builder: (_, __) => const _PlaceholderScreen(title: 'Ride History')),
    ],
  );
});

// Shown while the profile row is being fetched after sign-in.
// The router exits this screen automatically once currentUserProvider resolves.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Placeholder for $title', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/onboarding'),
              child: const Text('Back to Onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}

class BikeBuddyApp extends ConsumerWidget {
  const BikeBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Global Dark Theme Configuration
    final darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00C853),
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
      // Provide the same dark theme for all slots to force dark mode physically
      theme: darkTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
