import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/discovery_shop.dart';

class DiscoveryShopCard extends StatelessWidget {
  const DiscoveryShopCard({
    required this.shop,
    required this.onTap,
    super.key,
  });

  final DiscoveryShop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = isDark ? AppColors.borderDark : AppColors.borderLight;
    final primaryText = isDark ? AppColors.textLight : AppColors.textDark;
    final mutedText = isDark ? Colors.white70 : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: AppColors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _distanceLabel(shop),
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.green),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              shop.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: mutedText, height: 1.4),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _MetricPill(
                  icon: Icons.pedal_bike_outlined,
                  label: '${shop.availableBikes}/${shop.totalBikes} bikes',
                  color: shop.hasAvailableBikes
                      ? AppColors.green
                      : AppColors.warning,
                ),
                const SizedBox(width: 10),
                _MetricPill(
                  icon: Icons.payments_outlined,
                  label: 'KES ${shop.ratePerHour}/hr',
                  color: AppColors.greenDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _distanceLabel(DiscoveryShop shop) {
  final distance = shop.distanceKm;
  if (distance == null) return 'Distance available after location access';
  if (distance < 1) return '${(distance * 1000).round()} m away';
  return '${distance.toStringAsFixed(1)} km away';
}
