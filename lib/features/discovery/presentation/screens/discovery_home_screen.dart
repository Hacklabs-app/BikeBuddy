import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/models/discovery_shop.dart';
import '../state/discovery_state.dart';
import '../widgets/shop_card.dart';
import '../widgets/filter_chips.dart';
import '../widgets/discovery_skeleton.dart';
import '../widgets/location_rationale_sheet.dart';
import '../widgets/shop_detail_sheet.dart';

class DiscoveryHomeScreen extends ConsumerStatefulWidget {
  const DiscoveryHomeScreen({super.key});

  @override
  ConsumerState<DiscoveryHomeScreen> createState() => _DiscoveryHomeScreenState();
}

class _DiscoveryHomeScreenState extends ConsumerState<DiscoveryHomeScreen> with WidgetsBindingObserver {
  bool _isWaitingForLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // If we were waiting for the user to enable location and they just came back to the app
    if (state == AppLifecycleState.resumed && _isWaitingForLocation) {
      _checkLocationAndSort();
    }
  }

  Future<void> _checkLocationAndSort() async {
    // 1. Force the UI to show the 'Nearest' filter is selected immediately
    ref.read(discoveryProvider.notifier).setFilter(ShopFilter.nearest);

    // 2. Poll for the permission change (OS sometimes takes 100-300ms to update)
    for (int i = 0; i < 3; i++) {
      final hasPermission = await locationService.canUseLocationWithoutPrompt();
      if (hasPermission) {
        setState(() => _isWaitingForLocation = false);
        ref.read(discoveryProvider.notifier).requestLocationAndSort();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 3. If still no permission after polling, reset the flag
    setState(() => _isWaitingForLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    final discoveryState = ref.watch(discoveryProvider);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      // FIX: Ensure keyboard doesn't push the nav bar up
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Main Scrollable Content
          RefreshIndicator(
            color: AppColors.green,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: () => ref.read(discoveryProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Header
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(24, size.height * 0.08, 24, 24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ready to\nPedal?',
                              style: GoogleFonts.inter(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: -2,
                              ),
                            ),
                            _ProfileIcon(onTap: () => context.push('/login')),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const _SearchInput(),
                        const SizedBox(height: 24),
                        discoveryState.maybeWhen(
                          data: (state) => FilterChips(
                            selectedFilter: state.filter,
                            onFilterSelected: (filter) {
                              if (filter == ShopFilter.nearest) {
                                _handleLocationFilter(state);
                              } else {
                                ref.read(discoveryProvider.notifier).updateFilter(filter);
                              }
                            },
                            onNearestSelected: () {
                              discoveryState.whenData((state) {
                                _handleLocationFilter(state);
                              });
                            },
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Shop List
                discoveryState.when(
                  loading: () => const SliverFillRemaining(
                    child: DiscoverySkeleton(),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white60))),
                  ),
                  data: (state) => SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                    sliver: state.filteredShops.isEmpty 
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 40),
                              child: Text('No stations match your search.', 
                                   style: TextStyle(color: Colors.white38)),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final shop = state.filteredShops[index];
                              return ShopCard(
                                shop: shop,
                                onTap: () => _showShopDetails(shop),
                              );
                            },
                            childCount: state.filteredShops.length,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Bottom Navigation
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: _FloatingBottomNav(
              onNavTap: () => context.push('/login'),
            ),
          ),
        ],
      ),
    );
  }

  void _showShopDetails(DiscoveryShop shop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ShopDetailSheet(shop: shop),
    );
  }

  void _handleLocationFilter(DiscoveryState state) async {
    final hasPermission = await locationService.canUseLocationWithoutPrompt();
    if (hasPermission && state.userLocation != null) {
      ref.read(discoveryProvider.notifier).updateFilter(ShopFilter.nearest);
      return;
    }

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: LocationRationaleSheet(
          onAccept: () {
            setState(() => _isWaitingForLocation = true);
            ref.read(discoveryProvider.notifier).requestLocationAndSort();
          },
        ),
      ),
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

class _SearchInput extends ConsumerStatefulWidget {
  const _SearchInput();
  @override
  ConsumerState<_SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends ConsumerState<_SearchInput> {
  final TextEditingController _controller = TextEditingController();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: (val) => ref.read(discoveryProvider.notifier).updateSearch(val),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Search stations...',
                hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.2), fontSize: 15),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                ref.read(discoveryProvider.notifier).updateSearch('');
                setState(() {});
              },
              child: Icon(Icons.close_rounded, color: Colors.white.withValues(alpha: 0.3), size: 18),
            ),
        ],
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({required this.onNavTap});
  final VoidCallback onNavTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 40, offset: const Offset(0, 20)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const _NavIcon(icon: Icons.explore_rounded, label: 'Stations', isActive: true),
          GestureDetector(onTap: onNavTap, child: const _NavIcon(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', isActive: false)),
          _ScanHeroButton(onTap: onNavTap),
          GestureDetector(onTap: onNavTap, child: const _NavIcon(icon: Icons.bar_chart_rounded, label: 'Activity', isActive: false)),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.label, required this.isActive});
  final IconData icon;
  final String label;
  final bool isActive;
  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.green : Colors.white.withValues(alpha: 0.2);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: isActive ? FontWeight.w800 : FontWeight.w500, color: color)),
      ],
    );
  }
}

class _ScanHeroButton extends StatelessWidget {
  const _ScanHeroButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A), // Dark surface
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.green.withValues(alpha: 0.3), width: 2), // Subtle green ring
          boxShadow: [
            BoxShadow(color: AppColors.green.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 4)),
          ],
        ),
        child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.green, size: 28), // Green only on the icon
      ),
    );
  }
}
