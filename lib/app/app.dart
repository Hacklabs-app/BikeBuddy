import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shared/providers/auth_provider.dart';
import '../core/models/user_model.dart';
import '../core/services/storage_service.dart';
import '../core/widgets/floating_bottom_nav.dart';
import '../core/widgets/loading_screen.dart';
import '../core/widgets/common_placeholder_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/discovery/presentation/screens/discovery_home_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/update_password_screen.dart';
import '../features/auth/presentation/screens/role_selection_screen.dart';
import '../features/auth/presentation/screens/rider_signup_screen.dart';
import '../features/auth/presentation/screens/owner_signup_screen.dart';
import '../features/auth/presentation/screens/email_verification_screen.dart';

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
  static const emailVerification = '/email-verification';
}

const _ownerRoutes = [AppRoutes.admin, AppRoutes.shopSetup];
const _customerAuthRoutes = [AppRoutes.ride, AppRoutes.scan, AppRoutes.profile];
const _registrationRoutes = [
  AppRoutes.roleSelection,
  AppRoutes.riderSignUp,
  AppRoutes.ownerSignUp
];

bool _isOwnerRoute(String loc) => _ownerRoutes.contains(loc);
bool _isCustomerAuthRoute(String loc) => _customerAuthRoutes.contains(loc);
bool _isRegistrationRoute(String loc) => _registrationRoutes.contains(loc);

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void _showRouterSnackBar(String message, {bool isError = false}) {
  scaffoldMessengerKey.currentState?.clearSnackBars();
  scaffoldMessengerKey.currentState?.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? Colors.redAccent : const Color(0xFF00B248),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1E1E24),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      duration: const Duration(seconds: 4),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ValueNotifier<bool>(false);

  ref.listen(authStateProvider,
      (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(currentUserProvider,
      (_, __) => refreshListenable.value = !refreshListenable.value);
  ref.listen(hasSeenOnboardingProvider,
      (_, __) => refreshListenable.value = !refreshListenable.value);

  return GoRouter(
    initialLocation: ref.read(hasSeenOnboardingProvider)
        ? AppRoutes.home
        : AppRoutes.onboarding,
    refreshListenable: refreshListenable,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Intercept and handle /login-callback deep link errors gracefully without showing "Page Not Found"
      if (location.startsWith('/login-callback')) {
        final uri = state.uri;
        final params = {...uri.queryParameters};

        // Support fragment parsing since some auth servers return parameters in fragment after '#'
        if (uri.fragment.isNotEmpty) {
          try {
            final fragmentUri = Uri.parse('?${uri.fragment}');
            params.addAll(fragmentUri.queryParameters);
          } catch (_) {}
        }

        final error = params['error'];
        final errorCode = params['error_code'];
        final errorDescription = params['error_description'];

        if (error != null || errorCode != null) {
          debugPrint('[ROUTER] Deep-link error callback: $error ($errorCode): $errorDescription');

          String displayMessage = errorDescription?.replaceAll('+', ' ') ?? 'Verification link error.';
          if (errorCode == 'otp_expired' || error == 'access_denied' || displayMessage.toLowerCase().contains('expired') || displayMessage.toLowerCase().contains('invalid')) {
            displayMessage = 'The verification link has expired or already been used. Please request a new link.';
          }

          final msg = displayMessage;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showRouterSnackBar(msg, isError: true);
          });
        }

        return AppRoutes.home;
      }

      // Handle the initial root path '/' (e.g. from deep links) gracefully by redirecting
      // to home or onboarding based on application state, avoiding 404s.
      if (location == '/') {
        final hasSeenOnboarding = ref.read(hasSeenOnboardingProvider);
        if (!hasSeenOnboarding) return AppRoutes.onboarding;
        final authState = ref.read(authStateProvider);
        final isLoggedIn = authState.valueOrNull != null;
        if (isLoggedIn) {
          final user = ref.read(currentUserProvider).valueOrNull;
          final isOwner = user?.role == UserRole.owner;
          return isOwner ? AppRoutes.admin : AppRoutes.home;
        }
        return AppRoutes.home;
      }

      // Allow password update and forgot-password screens to pass through without redirection
      if (location == AppRoutes.updatePassword || location == AppRoutes.forgotPassword) {
        return null;
      }

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

      // ── Email Verification Guard ───────────────────────────────────────────
      if (isLoggedIn) {
        final isEmailVerified = authState.valueOrNull?.emailConfirmedAt != null;
        if (!isEmailVerified) {
          if (location != AppRoutes.emailVerification) {
            debugPrint('[ROUTER] Redirecting: Logged in user needs email verification');
            return AppRoutes.emailVerification;
          }
          return null;
        }
      }

      // ── Guest Guard ───────────────────────────────────────────────────────
      if (!isLoggedIn) {
        // Guests ARE allowed on Registration routes and Login routes.
        if (_isCustomerAuthRoute(location) || _isOwnerRoute(location)) {
          debugPrint(
              '[ROUTER] Guest blocked from private route. Redirecting to Home');
          return AppRoutes.home;
        }
        return null;
      }

      // ── Profile Gap Interceptor (Only for Authenticated Users) ─────────────
      if (userAsync.isLoading) {
        return null;
      }

      // If user has a valid completed role, clear the local pending role preference if it exists
      if (user != null && user.role != UserRole.pending) {
        final pendingRole = ref.read(pendingRegistrationRoleProvider);
        if (pendingRole != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(storageServiceProvider).clearPendingRegistrationRole();
            ref.invalidate(pendingRegistrationRoleProvider);
          });
        }
      }

      // 1. User has no role (First-time social or trigger lag) -> Force Role Selection or direct to pending form
      if (user?.role == UserRole.pending || user == null) {
        if (!_isRegistrationRoute(location)) {
          final pendingRole = ref.read(pendingRegistrationRoleProvider);
          if (pendingRole == 'customer') {
            debugPrint('[ROUTER] Redirecting directly to Rider Signup based on local preference');
            return AppRoutes.riderSignUp;
          } else if (pendingRole == 'owner') {
            debugPrint('[ROUTER] Redirecting directly to Owner Signup based on local preference');
            return AppRoutes.ownerSignUp;
          }

          debugPrint(
              '[ROUTER] Redirecting: Authenticated user needs to pick a role');
          return AppRoutes.roleSelection;
        }
        return null;
      }

      // 2. Owner missing a Station -> Force Owner Signup/Setup
      if (isOwner && user.shopId == null) {
        if (location != AppRoutes.ownerSignUp &&
            location != AppRoutes.shopSetup) {
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
      GoRoute(
          path: AppRoutes.onboarding,
          builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.roleSelection,
          builder: (_, __) => const RoleSelectionScreen()),
      GoRoute(
          path: AppRoutes.riderSignUp,
          builder: (_, __) => const RiderSignUpScreen()),
      GoRoute(
          path: AppRoutes.ownerSignUp,
          builder: (_, __) => const OwnerSignUpScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(
          path: AppRoutes.updatePassword,
          builder: (_, __) => const UpdatePasswordScreen()),
      GoRoute(
          path: AppRoutes.loading, builder: (_, __) => const LoadingScreen()),
      GoRoute(
          path: AppRoutes.emailVerification, builder: (_, __) => const EmailVerificationScreen()),
      GoRoute(
          path: '/', builder: (_, __) => const LoadingScreen()),
      GoRoute(
          path: '/login-callback', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(
        path: AppRoutes.admin,
        builder: (_, __) => const CommonPlaceholderScreen(
          title: 'Business Dashboard',
          isOwnerView: true,
        ),
      ),
      GoRoute(
        path: AppRoutes.shopSetup,
        builder: (_, __) => const CommonPlaceholderScreen(title: 'Shop Setup'),
      ),
      GoRoute(
          path: AppRoutes.home,
          builder: (_, __) => const DiscoveryHomeScreen()),
      GoRoute(
        path: AppRoutes.ride,
        builder: (_, __) => const CommonPlaceholderScreen(
          title: 'Activity',
          tab: FloatingNavTab.activity,
        ),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (_, __) => const CommonPlaceholderScreen(
          title: 'Scan QR',
          tab: FloatingNavTab.scan,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const CommonPlaceholderScreen(
          title: 'Profile Settings',
        ),
      ),
    ],
  );
});

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
          ref.read(routerProvider).go(AppRoutes.updatePassword);
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
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Bike Buddy',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
