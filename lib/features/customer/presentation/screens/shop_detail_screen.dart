import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/billing_calculator.dart';
import '../../../../core/widgets/bike_buddy_bottom_nav.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../domain/entities/discovery_shop.dart';

class ShopDetailScreen extends ConsumerStatefulWidget {
  const ShopDetailScreen({
    required this.shop,
    super.key,
  });

  final DiscoveryShop shop;

  @override
  ConsumerState<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends ConsumerState<ShopDetailScreen> {
  int _quantity = 1;
  int _hours = 1;

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final isLoggedIn = ref.watch(authStateProvider).valueOrNull != null;
    final cappedQuantity = _quantity.clamp(1, shop.availableBikes);
    final estimate = shop.availableBikes == 0
        ? 0
        : BillingCalculator.calculateAmountDue(
            startedAt: DateTime(2026, 1, 1),
            endedAt: DateTime(2026, 1, 1, _hours),
            ratePerHour: shop.ratePerHour,
            quantity: cappedQuantity,
          );

    return Scaffold(
      appBar: AppBar(title: Text(shop.name)),
      bottomNavigationBar: BikeBuddyBottomNav.customer(
        currentItem: BikeBuddyNavItem.discover,
        isLoggedIn: isLoggedIn,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            shop.name,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(shop.address),
          const SizedBox(height: 24),
          _InfoRow(
            icon: Icons.pedal_bike_outlined,
            label: 'Availability',
            value: '${shop.availableBikes} of ${shop.totalBikes} bikes',
          ),
          _InfoRow(
            icon: Icons.payments_outlined,
            label: 'Rate',
            value: 'KES ${shop.ratePerHour} per hour',
          ),
          const _InfoRow(
            icon: Icons.schedule,
            label: 'Operating hours',
            value: 'Ask station owner',
          ),
          const SizedBox(height: 28),
          const Text(
            'Cost estimate',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _StepperRow(
            label: 'Bikes',
            value: cappedQuantity,
            minValue: 1,
            maxValue: shop.availableBikes.clamp(1, 999),
            onChanged: (value) => setState(() => _quantity = value),
          ),
          _StepperRow(
            label: 'Hours',
            value: _hours,
            minValue: 1,
            maxValue: 24,
            onChanged: (value) => setState(() => _hours = value),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimated total',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'KES $estimate',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          if (shop.availableBikes == 0) ...[
            const SizedBox(height: 16),
            const Text(
              'No bikes are currently available at this station.',
              style: TextStyle(color: AppColors.warning),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.green),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton.outlined(
            onPressed: value <= minValue ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          IconButton.outlined(
            onPressed: value >= maxValue ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
