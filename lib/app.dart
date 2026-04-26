import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'shared/providers/auth_provider.dart';
import 'core/models/user_model.dart';
import 'features/auth/login_screen.dart';
import 'features/admin/dashboard/admin_dashboard.dart';
import 'features/customer/home/customer_home.dart';
import 'features/customer/booking/booking_confirm_screen.dart';
import 'features/customer/ride/active_ride_screen.dart';
import 'features/customer/ride/scan_qr_screen.dart';
import 'features/customer/history/ride_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final onHome = state.matchedLocation == '/home';
      final onLogin = state.matchedLocation == '/login';

      // Protected routes — require login
      final protectedRoutes = ['/booking', '/ride', '/scan', '/history'];
      final isProtected = protectedRoutes
          .any((r) => state.matchedLocation.startsWith(r));

      if (!isLoggedIn && isProtected) return '/login';
      if (!isLoggedIn && !onHome && !onLogin) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
      GoRoute(path: '/loading', builder: (context, _) => const _RoleRedirector()),
      GoRoute(path: '/admin', builder: (context, _) => const AdminDashboard()),
      GoRoute(path: '/home', builder: (context, _) => const CustomerHome()),
      GoRoute(path: '/ride', builder: (context, _) => const ActiveRideScreen()),
      GoRoute(path: '/scan', builder: (context, _) => const ScanQrScreen()),
      GoRoute(path: '/history', builder: (context, _) => const RideHistoryScreen()),
      GoRoute(
        path: '/booking',
        builder: (context, state) {
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

class _RoleRedirector extends ConsumerWidget {
  const _RoleRedirector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/login');
          });
          return const SizedBox();
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (user.role == UserRole.admin) {
            context.go('/admin');
          } else {
            context.go('/home');
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
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