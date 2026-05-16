import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/discovery_shop.dart';
import 'glass_container.dart';

class ShopCard extends StatelessWidget {
  const ShopCard({super.key, required this.shop, required this.onTap});

  final DiscoveryShop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'en_US');

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: GlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            opacity: 0.04,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Main Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                shop.name,
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RatingIndicator(rating: shop.rating),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shop.address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(
                              currencyFormat.format(shop.ratePerHour),
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '/hr',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            if (shop.distanceKm != null) ...[
                              const SizedBox(width: 12),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: Colors.white24,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${shop.distanceKm!.toStringAsFixed(1)}km',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.green,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Availability Visual
                  _AvailabilityIndicator(count: shop.availableBikes),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingIndicator extends StatelessWidget {
  const _RatingIndicator({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 14),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _AvailabilityIndicator extends StatelessWidget {
  const _AvailabilityIndicator({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final bool isLow = count < 5;
    final bool isEmpty = count == 0;
    final color = isEmpty
        ? Colors.white.withValues(alpha: 0.2)
        : (isLow ? const Color(0xFFFF5252) : AppColors.green);

    return Container(
      width: 64,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isEmpty ? Icons.block_flipped : Icons.pedal_bike_rounded,
            size: 16,
            color: color.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            'LEFT',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: color.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
