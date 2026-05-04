import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../shared/providers/auth_provider.dart';
import '../core/models/user_model.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/admin_dashboard.dart';
import '../features/dashboard/presentation/screens/shop_setup_screen.dart';
import '../features/dashboard/presentation/screens/customer_home.dart';
import '../features/rentals/presentation/screens/booking_confirm_screen.dart';
import '../features/rentals/presentation/screens/active_ride_screen.dart';
import '../features/rentals/presentation/screens/scan_qr_screen.dart';
import '../features/rentals/presentation/screens/ride_history_screen.dart';

// Extend these two lists as new routes are added — guards update automatically.
const _ownerRoutes = ['/admin', '/shop-setup'];
const _customerAuthRoutes = ['/booking', '/ride', '/scan', '/history'];

bool _isOwnerRoute(String loc) => _ownerRoutes.any(loc.startsWith);
bool _isCustomerAuthRoute(String loc) => _customerAuthRoutes.any(loc.startsWith);

final routerProvider = Provider<GoRouter>((ref) {
  // Watching both providers means the router rebuilds (and redirect re-fires)
  // whenever auth state or the fetched profile changes.
  final authState = ref.watch(authStateProvider);
  final userAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggedIn = authState.valueOrNull != null;
      final user = userAsync.valueOrNull;
      final isOwner = user?.role == UserRole.owner;

      // ── /loading ────────────────────────────────────────────────────────────
      // Used as a brief holding screen while the profile is being fetched.
      // Exit immediately if not logged in, or once the profile resolves.
      if (location == '/loading') {
        if (!isLoggedIn) return '/home';
        if (!userAsync.isLoading) return isOwner ? '/admin' : '/home';
        return null; // still fetching — stay on the spinner
      }

      // ── /login ──────────────────────────────────────────────────────────────
      // Authenticated users have no business on the login screen.
      // Hold at /loading while the profile is still resolving.
      if (isLoggedIn && location == '/login') {
        return userAsync.isLoading ? '/loading' : (isOwner ? '/admin' : '/home');
      }

      // ── Owner → customer-auth routes ────────────────────────────────────────
      // An owner has no customer bookings or ride screens; send them home.
      if (isOwner && _isCustomerAuthRoute(location)) return '/admin';

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
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/loading', builder: (_, __) => const _LoadingScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboard()),
      GoRoute(path: '/shop-setup', builder: (_, __) => const ShopSetupScreen()),
      GoRoute(path: '/home', builder: (_, __) => const CustomerHome()),
      GoRoute(path: '/ride', builder: (_, __) => const ActiveRideScreen()),
      GoRoute(path: '/scan', builder: (_, __) => const ScanQrScreen()),
      GoRoute(path: '/history', builder: (_, __) => const RideHistoryScreen()),
      GoRoute(
        path: '/booking',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BookingConfirmScreen(
            bike: extra?['bike'] as Map<String, dynamic>? ?? {},
            selectedHours: extra?['hours'] as int? ?? 1,
          );
        },
      ),
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

class BikeBuddyApp extends ConsumerWidget {
  const BikeBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Bike Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C853),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
