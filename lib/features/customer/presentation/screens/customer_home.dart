import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/widgets/bike_buddy_bottom_nav.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../state/shop_discovery_state.dart';
import '../widgets/discovery_shop_card.dart';

class CustomerHome extends ConsumerStatefulWidget {
  const CustomerHome({super.key});

  @override
  ConsumerState<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends ConsumerState<CustomerHome>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreLocationIfAlreadyAllowed();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    final notice = ref.read(locationNoticeProvider);
    final shouldRetryLocation =
        notice?.toLowerCase().contains('turn on device location') ?? false;
    if (shouldRetryLocation) _requestLocation();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shopsAsync = ref.watch(shopDiscoveryProvider);
    final locationNotice = ref.watch(locationNoticeProvider);
    final hasLocation = ref.watch(currentLocationProvider) != null;
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: RefreshIndicator(
            color: AppColors.green,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _DiscoveryHeader(
                  isLoggedIn: isLoggedIn,
                  hasLocation: hasLocation,
                  locationNotice: locationNotice,
                  onProfileTap: () =>
                      isLoggedIn ? _showProfileSheet() : context.go('/login'),
                  onUseLocation: _requestLocation,
                  onOpenSettings: _openLocationSettings,
                  onRefresh: _refresh,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
                  sliver: shopsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.green,
                          ),
                        ),
                      ),
                    ),
                    error: (error, _) => SliverToBoxAdapter(
                      child: _ErrorState(
                        message: error.toString(),
                        onRetry: () => ref.invalidate(shopDiscoveryProvider),
                      ),
                    ),
                    data: (shops) {
                      if (shops.isEmpty) {
                        return const SliverToBoxAdapter(child: _EmptyState());
                      }

                      return SliverList.separated(
                        itemCount: shops.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final shop = shops[index];
                          return DiscoveryShopCard(
                            shop: shop,
                            onTap: () =>
                                context.push('/shop-detail', extra: shop),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BikeBuddyBottomNav.customer(
          currentItem: BikeBuddyNavItem.discover,
          isLoggedIn: isLoggedIn,
        ),
      ),
    );
  }

  Future<void> _restoreLocationIfAlreadyAllowed() async {
    if (!mounted) return;
    if (ref.read(currentLocationProvider) != null) return;

    final canUseLocation = await locationService.canUseLocationWithoutPrompt();
    if (!mounted || !canUseLocation) return;

    await _requestLocation();
  }

  Future<void> _requestLocation() async {
    if (!mounted) return;
    await ref.read(shopDiscoveryProvider.notifier).requestLocation();
  }

  Future<void> _openLocationSettings() async {
    if (!mounted) return;
    await locationService.openLocationSettings();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final hasLocation = ref.read(currentLocationProvider) != null;
    if (!hasLocation && await locationService.isLocationServiceEnabled()) {
      await _requestLocation();
    }
    ref.invalidate(shopDiscoveryProvider);
  }

  void _showProfileSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  title: const Text(AppStrings.profile),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/scan');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer_outlined),
                  title: const Text(AppStrings.activeRide),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/ride');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text(AppStrings.rideHistory),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/history');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DiscoveryHeader extends StatelessWidget {
  const _DiscoveryHeader({
    required this.isLoggedIn,
    required this.hasLocation,
    required this.locationNotice,
    required this.onProfileTap,
    required this.onUseLocation,
    required this.onOpenSettings,
    required this.onRefresh,
  });

  final bool isLoggedIn;
  final bool hasLocation;
  final String? locationNotice;
  final VoidCallback onProfileTap;
  final VoidCallback onUseLocation;
  final VoidCallback onOpenSettings;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final needsDeviceLocation =
        locationNotice?.toLowerCase().contains('turn on device location') ??
            false;

    return SliverAppBar(
      expandedHeight: 226,
      pinned: true,
      elevation: 0,
      backgroundColor: AppColors.green,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.green, AppColors.greenDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.84),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Refresh',
                            onPressed: onRefresh,
                            icon: const Icon(Icons.refresh),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: isLoggedIn ? 'Profile' : 'Sign in',
                            onPressed: onProfileTap,
                            icon: Icon(
                              isLoggedIn
                                  ? Icons.person_outline
                                  : Icons.login_outlined,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    AppStrings.discoveryTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.discoverySubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderChip(
                        icon: hasLocation
                            ? Icons.location_on_outlined
                            : Icons.near_me_outlined,
                        label: hasLocation
                            ? 'Nearest first'
                            : needsDeviceLocation
                                ? 'Turn on location'
                                : 'Use location',
                        onTap: hasLocation
                            ? null
                            : needsDeviceLocation
                                ? onOpenSettings
                                : onUseLocation,
                      ),
                      const _HeaderChip(
                        icon: Icons.public,
                        label: 'All shops',
                        onTap: null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: const Text(
        AppStrings.appName,
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = isDark ? AppColors.textLight : AppColors.textDark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.green),
          const SizedBox(height: 12),
          Text(
            'Could not load shops',
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onRetry,
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: Text('No bike stations are listed yet.')),
    );
  }
}

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
