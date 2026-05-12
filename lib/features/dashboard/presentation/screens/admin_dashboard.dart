import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/bike_buddy_bottom_nav.dart';

final adminShopProvider = FutureProvider<OwnerShopSummary?>((ref) async {
  final client = Supabase.instance.client;
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  final data = await client
      .from('shops')
      .select('''
        id, name, address, lat, lng, total_bikes,
        shop_rates(rate_per_hour),
        rentals(quantity, started_at, ended_at, amount_due)
      ''')
      .eq('owner_id', userId)
      .maybeSingle();

  if (data == null) return null;
  return OwnerShopSummary.fromMap(data);
});

class OwnerShopSummary {
  const OwnerShopSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.totalBikes,
    required this.ratePerHour,
    required this.activeRentalQuantity,
    required this.activeRentalCount,
    required this.todayRevenue,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String address;
  final int totalBikes;
  final int ratePerHour;
  final int activeRentalQuantity;
  final int activeRentalCount;
  final int todayRevenue;
  final double? latitude;
  final double? longitude;

  int get availableBikes =>
      (totalBikes - activeRentalQuantity).clamp(0, totalBikes);
  bool get hasLocation => latitude != null && longitude != null;

  factory OwnerShopSummary.fromMap(Map<String, dynamic> map) {
    final rentals = (map['rentals'] as List?) ?? [];
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    var activeQuantity = 0;
    var activeCount = 0;
    var revenue = 0;

    for (final rental in rentals.cast<Map<String, dynamic>>()) {
      if (rental['ended_at'] == null) {
        activeQuantity += rental['quantity'] as int? ?? 0;
        activeCount += 1;
        continue;
      }

      final endedAtRaw = rental['ended_at'] as String?;
      final amountDue = rental['amount_due'] as int? ?? 0;
      if (endedAtRaw == null) continue;

      final endedAt = DateTime.parse(endedAtRaw);
      if (!endedAt.isBefore(todayStart)) revenue += amountDue;
    }

    final rate = _readRatePerHour(map['shop_rates']);

    return OwnerShopSummary(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'My shop',
      address: map['address'] as String? ?? '',
      totalBikes: map['total_bikes'] as int? ?? 0,
      ratePerHour: rate,
      activeRentalQuantity: activeQuantity,
      activeRentalCount: activeCount,
      todayRevenue: revenue,
      latitude: (map['lat'] as num?)?.toDouble(),
      longitude: (map['lng'] as num?)?.toDouble(),
    );
  }
}

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(adminShopProvider);
    final shop = shopAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textLight,
        title: Text(
          shop?.name ?? 'Owner dashboard',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Shop settings',
            onPressed: () => context.go('/shop-setup'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: shopAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.green),
        ),
        error: (error, _) => _OwnerError(
          message: error.toString(),
          onRetry: () => ref.invalidate(adminShopProvider),
        ),
        data: (shop) {
          if (shop == null) {
            return _SetupPrompt(onSetup: () => context.go('/shop-setup'));
          }

          return RefreshIndicator(
            color: AppColors.green,
            onRefresh: () async => ref.invalidate(adminShopProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _ShopHeader(shop: shop),
                const SizedBox(height: 18),
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 720 ? 4 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _MetricCard(
                      icon: Icons.pedal_bike_outlined,
                      label: 'Available',
                      value: '${shop.availableBikes}/${shop.totalBikes}',
                    ),
                    _MetricCard(
                      icon: Icons.assignment_return_outlined,
                      label: 'Active rentals',
                      value: '${shop.activeRentalCount}',
                    ),
                    _MetricCard(
                      icon: Icons.payments_outlined,
                      label: 'Rate',
                      value: 'KES ${shop.ratePerHour}',
                    ),
                    _MetricCard(
                      icon: Icons.trending_up,
                      label: 'Today',
                      value: 'KES ${shop.todayRevenue}',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _ActionTile(
                  icon: Icons.point_of_sale_outlined,
                  title: 'Checkout bikes',
                  subtitle: 'Capture customer name, ID, quantity, and rate.',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.assignment_return,
                  title: 'Check in active rentals',
                  subtitle: 'End a rental and calculate the bill.',
                  onTap: () {},
                ),
                _ActionTile(
                  icon: Icons.receipt_long,
                  title: 'Rental history',
                  subtitle: 'Review completed rentals and revenue.',
                  onTap: () => context.go('/history'),
                ),
                _ActionTile(
                  icon: Icons.storefront,
                  title: 'Shop settings',
                  subtitle: 'Update bikes, rate, address, and location.',
                  onTap: () => context.go('/shop-setup'),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const BikeBuddyBottomNav.owner(
        currentItem: BikeBuddyNavItem.ownerDashboard,
      ),
    );
  }
}

int _readRatePerHour(Object? rawRates) {
  if (rawRates is Map<String, dynamic>) {
    return rawRates['rate_per_hour'] as int? ?? 0;
  }
  if (rawRates is List && rawRates.isNotEmpty) {
    final first = rawRates.first;
    if (first is Map<String, dynamic>) {
      return first['rate_per_hour'] as int? ?? 0;
    }
  }
  return 0;
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});

  final OwnerShopSummary shop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                shop.hasLocation
                    ? Icons.location_on_outlined
                    : Icons.location_off_outlined,
                color: shop.hasLocation ? AppColors.green : AppColors.warning,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shop.hasLocation
                      ? shop.address
                      : 'Add a shop location in settings',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: AppColors.green),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surfaceDark,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: AppColors.green),
        title: Text(title, style: const TextStyle(color: AppColors.textLight)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white70),
        onTap: onTap,
      ),
    );
  }
}

class _SetupPrompt extends StatelessWidget {
  const _SetupPrompt({required this.onSetup});

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, color: AppColors.green, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Set up your shop',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your address, bike count, hourly rate, and location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onSetup,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Set up shop'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerError extends StatelessWidget {
  const _OwnerError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 44),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
